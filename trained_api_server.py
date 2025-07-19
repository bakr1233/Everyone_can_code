#!/usr/bin/env python3
"""
Trained WiseAI API Server
Uses machine learning models to provide better quote recommendations
"""

import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import pickle
import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
import os

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

class TrainedQuoteEngine:
    def __init__(self, models_dir='models'):
        self.models_dir = models_dir
        self.vectorizer = None
        self.emotion_classifier = None
        self.problem_classifier = None
        self.quote_clusters = None
        self.quotes_df = None
        self.training_data = None
        self.is_loaded = False
        
    def load_models(self):
        """Load trained models"""
        try:
            logger.info("🔄 Loading simple training models...")
            
            # Load simple training models (these are the ones we have)
            model_files = {
                'vectorizer': 'vectorizer.pkl',
                'emotion_classifier': 'emotion_classifier.pkl',
                'quotes_df': 'quotes_df.pkl'
            }
            
            loaded_models = 0
            for attr, filename in model_files.items():
                filepath = os.path.join(self.models_dir, filename)
                if os.path.exists(filepath):
                    with open(filepath, 'rb') as f:
                        setattr(self, attr, pickle.load(f))
                    logger.info(f"✅ Loaded {attr}")
                    loaded_models += 1
                else:
                    logger.warning(f"⚠️ Model file not found: {filepath}")
            
            # Load metadata
            metadata_path = os.path.join(self.models_dir, 'metadata.json')
            if os.path.exists(metadata_path):
                with open(metadata_path, 'r') as f:
                    self.metadata = json.load(f)
                logger.info("✅ Loaded metadata")
                logger.info(f"📊 Dataset size: {self.metadata.get('dataset_size', 'Unknown'):,} quotes")
                logger.info(f"🎭 Emotion classes: {len(self.metadata.get('emotion_classes', []))}")
            
            # Check if we have the essential models
            if self.vectorizer is not None and self.emotion_classifier is not None and self.quotes_df is not None:
                self.is_loaded = True
                logger.info("✅ Simple training models loaded successfully")
                logger.info(f"📚 Available quotes: {len(self.quotes_df):,}")
                return True
            else:
                logger.warning("⚠️ Some essential models missing, using fallback mode")
                return False
            
        except Exception as e:
            logger.error(f"❌ Error loading models: {e}")
            return False
    
    def analyze_sentiment(self, user_input: str) -> dict:
        """Analyze user input using trained emotion classifier"""
        if not self.is_loaded or self.emotion_classifier is None:
            return self._fallback_sentiment_analysis(user_input)
        
        try:
            # Vectorize input
            input_vector = self.vectorizer.transform([user_input])
            
            # Predict emotion
            predicted_emotion = self.emotion_classifier.predict(input_vector)[0]
            emotion_proba = self.emotion_classifier.predict_proba(input_vector)[0]
            confidence = max(emotion_proba)
            
            # Get insights based on predicted emotion
            insights = {
                'grief': "I hear the depth of your pain and loss. Your feelings are valid, and it's okay to not be okay. Grief has no timeline, and healing happens in its own way.",
                'depression': "I can feel the weight of what you're carrying. Depression can make everything feel dark and hopeless, but these feelings are temporary. You matter, and your pain is real.",
                'anxiety': "I understand that anxiety can feel overwhelming and suffocating. Your fears are valid, and it's okay to feel this way. Remember to breathe and take things one moment at a time.",
                'motivation': "I can see you're looking for motivation. Remember that passion drives success and every step forward counts.",
                'resilience': "Challenges are opportunities for growth. Your strength lies in perseverance and your ability to overcome obstacles.",
                'mindfulness': "Your thoughts shape your reality. Focus on what you can control and find peace in the present moment.",
                'happiness': "Happiness is a choice you make every day. Choose joy and find beauty in the simple moments.",
                'love': "Love is the most powerful force in the universe. It has the ability to heal, inspire, and transform lives.",
                'wisdom': "Every experience offers wisdom. Learn from both successes and challenges to grow stronger.",
                'hope': "Hope is the thing with feathers that perches in the soul. Even in the darkest times, it never completely disappears."
            }
            
            return {
                'primary_emotion': predicted_emotion,
                'confidence': confidence,
                'insight': insights.get(predicted_emotion, "I understand what you're going through. You're not alone in this journey."),
                'emotion_probabilities': dict(zip(self.emotion_classifier.classes_, emotion_proba))
            }
            
        except Exception as e:
            logger.error(f"❌ Error in sentiment analysis: {e}")
            return self._fallback_sentiment_analysis(user_input)
    
    def _fallback_sentiment_analysis(self, user_input: str) -> dict:
        """Fallback sentiment analysis when trained models aren't available"""
        user_input_lower = user_input.lower()
        
        # Simple keyword-based analysis
        if any(word in user_input_lower for word in ['died', 'death', 'lost', 'mom', 'mother', 'grief']):
            emotion = 'grief'
        elif any(word in user_input_lower for word in ['sad', 'depressed', 'hopeless', 'tired']):
            emotion = 'depression'
        elif any(word in user_input_lower for word in ['anxious', 'worry', 'fear', 'stress']):
            emotion = 'anxiety'
        else:
            emotion = 'general'
        
        return {
            'primary_emotion': emotion,
            'confidence': 0.7,
            'insight': "I understand what you're going through. You're not alone in this journey.",
            'emotion_probabilities': {emotion: 0.7}
        }
    
    def get_recommendations(self, user_input: str, top_k: int = 5) -> list:
        """Get personalized quote recommendations using simple training models"""
        if not self.is_loaded:
            return self._fallback_recommendations(user_input, top_k)
        
        try:
            # Analyze sentiment using simple training
            sentiment_analysis = self.analyze_sentiment(user_input)
            primary_emotion = sentiment_analysis['primary_emotion']
            confidence = sentiment_analysis['confidence']
            
            logger.info(f"🎯 Detected emotion: {primary_emotion} (confidence: {confidence:.2f})")
            
            # Get emotion-based recommendations (primary method)
            emotion_quotes = self._get_emotion_based_quotes(primary_emotion, top_k)
            
            # If we don't have enough emotion-based quotes, add some similarity-based ones
            if len(emotion_quotes) < top_k:
                remaining_k = top_k - len(emotion_quotes)
                similarity_quotes = self._get_similarity_quotes(user_input, remaining_k)
                emotion_quotes.extend(similarity_quotes)
            
            # Add confidence and emotion info to each quote
            for quote in emotion_quotes:
                quote['confidence'] = confidence
                quote['detected_emotion'] = primary_emotion
                quote['emotion_probabilities'] = sentiment_analysis['emotion_probabilities']
            
            return emotion_quotes[:top_k]
            
        except Exception as e:
            logger.error(f"❌ Error getting recommendations: {e}")
            return self._fallback_recommendations(user_input, top_k)
    
    def _get_emotion_based_quotes(self, emotion: str, top_k: int) -> list:
        """Get quotes based on predicted emotion"""
        if self.quotes_df is None:
            return []
        
        # Filter quotes by assigned_emotion (from simple training)
        if 'assigned_emotion' in self.quotes_df.columns:
            emotion_quotes = self.quotes_df[
                self.quotes_df['assigned_emotion'].str.lower() == emotion.lower()
            ]
        else:
            # Fallback to emotion column if assigned_emotion doesn't exist
            emotion_quotes = self.quotes_df[
                self.quotes_df['emotion'].str.lower() == emotion.lower()
            ]
        
        if emotion_quotes.empty:
            logger.warning(f"No quotes found for emotion: {emotion}")
            return []
        
        # Filter quotes by word count
        emotion_quotes = self._filter_quotes_by_length(emotion_quotes)

        # Sample quotes
        if len(emotion_quotes) <= top_k:
            selected_quotes = emotion_quotes
        else:
            selected_quotes = emotion_quotes.sample(n=top_k, random_state=42)
        
        results = []
        for _, quote in selected_quotes.iterrows():
            results.append({
                'text': quote['quote'] if 'quote' in quote else quote['text'],
                'author': quote.get('author', 'Unknown'),
                'emotion': emotion,
                'similarity_score': 0.9,
                'match_type': 'emotion_based'
            })
        
        return results
    
    def _get_similarity_quotes(self, user_input: str, top_k: int) -> list:
        """Get quotes using TF-IDF similarity"""
        if self.vectorizer is None or self.quotes_df is None:
            return []
        
        try:
            # Filter quotes by length first
            filtered_quotes_df = self._filter_quotes_by_length(self.quotes_df)
            
            if filtered_quotes_df.empty:
                logger.warning("No quotes available after length filtering")
                return []
            
            # Vectorize input
            input_vector = self.vectorizer.transform([user_input])
            
            # Vectorize all quotes (use 'quote' column from simple training)
            quote_texts = filtered_quotes_df['quote'] if 'quote' in filtered_quotes_df.columns else filtered_quotes_df['text']
            quote_vectors = self.vectorizer.transform(quote_texts)
            
            # Calculate similarities
            similarities = cosine_similarity(input_vector, quote_vectors).flatten()
            
            # Get top indices
            top_indices = np.argsort(similarities)[::-1][:top_k * 2]
            
            results = []
            for idx in top_indices:
                if similarities[idx] > 0.1:  # Minimum similarity threshold
                    quote = filtered_quotes_df.iloc[idx]
                    results.append({
                        'text': quote['quote'] if 'quote' in quote else quote['text'],
                        'author': quote.get('author', 'Unknown'),
                        'emotion': quote.get('assigned_emotion', quote.get('emotion', 'general')),
                        'similarity_score': float(similarities[idx]),
                        'match_type': 'similarity_based'
                    })
            
            return results[:top_k]
            
        except Exception as e:
            logger.error(f"❌ Error in similarity search: {e}")
            return []
    
    def _get_cluster_based_quotes(self, user_input: str, top_k: int) -> list:
        """Get quotes from similar clusters"""
        if self.quote_clusters is None or self.vectorizer is None or self.quotes_df is None:
            return []
        
        try:
            # Vectorize input
            input_vector = self.vectorizer.transform([user_input])
            
            # Predict cluster
            predicted_cluster = self.quote_clusters.predict(input_vector)[0]
            
            # Get quotes from the same cluster
            cluster_quotes = self.quotes_df[self.quotes_df['cluster'] == predicted_cluster]
            
            if cluster_quotes.empty:
                return []
            
            # Filter quotes by word count
            cluster_quotes = self._filter_quotes_by_length(cluster_quotes)

            # Sample quotes from cluster
            if len(cluster_quotes) <= top_k:
                selected_quotes = cluster_quotes
            else:
                selected_quotes = cluster_quotes.sample(n=top_k, random_state=42)
            
            results = []
            for _, quote in selected_quotes.iterrows():
                results.append({
                    'text': quote['text'],
                    'author': quote.get('author', 'Unknown'),
                    'emotion': quote.get('emotion', 'general'),
                    'similarity_score': 0.7,
                    'match_type': 'cluster_based'
                })
            
            return results
            
        except Exception as e:
            logger.error(f"❌ Error in cluster search: {e}")
            return []
    
    def _fallback_recommendations(self, user_input: str, top_k: int) -> list:
        """Fallback recommendations when trained models aren't available"""
        # Return some default quotes
        default_quotes = [
            {
                'text': "The only way to do great work is to love what you do.",
                'author': 'Steve Jobs',
                'emotion': 'motivation',
                'similarity_score': 0.5,
                'match_type': 'fallback'
            },
            {
                'text': "When we are no longer able to change a situation, we are challenged to change ourselves.",
                'author': 'Viktor E. Frankl',
                'emotion': 'wisdom',
                'similarity_score': 0.5,
                'match_type': 'fallback'
            }
        ]
        
        return default_quotes[:top_k]

    def _filter_quotes_by_length(self, quotes_df, max_words=50):
        """Filter quotes to only include those with max_words or less"""
        if quotes_df is None or quotes_df.empty:
            return quotes_df
        
        # Count words in each quote
        def word_count(text):
            if pd.isna(text) or not isinstance(text, str):
                return 0
            return len(text.split())
        
        # Filter quotes by word count
        filtered_quotes = quotes_df[quotes_df['quote'].apply(word_count) <= max_words]
        
        logger.info(f"📏 Filtered quotes: {len(quotes_df)} -> {len(filtered_quotes)} (max {max_words} words)")
        return filtered_quotes

# Initialize the trained quote engine
trained_engine = TrainedQuoteEngine()

# Try to load trained models
if trained_engine.load_models():
    logger.info("✅ Trained models loaded successfully")
else:
    logger.warning("⚠️ Could not load trained models, using fallback mode")

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'engine_loaded': trained_engine.is_loaded,
        'processing_method': 'simple_training_ml_engine',
        'models_available': {
            'emotion_classifier': trained_engine.emotion_classifier is not None,
            'vectorizer': trained_engine.vectorizer is not None,
            'quotes_df': trained_engine.quotes_df is not None
        },
        'dataset_info': {
            'total_quotes': len(trained_engine.quotes_df) if trained_engine.quotes_df is not None else 0,
            'emotion_classes': len(trained_engine.emotion_classifier.classes_) if trained_engine.emotion_classifier is not None else 0
        } if trained_engine.metadata else {}
    })

@app.route('/recommendations', methods=['POST'])
def get_recommendations():
    """Get personalized quote recommendations using simple training models"""
    try:
        data = request.get_json()
        user_input = data.get('text', '').strip()
        
        if not user_input:
            return jsonify({
                'error': 'No text provided',
                'status': 'error'
            }), 400
        
        logger.info(f"🎯 Processing request: '{user_input[:100]}...'")
        
        # Analyze sentiment using simple training model
        sentiment_analysis = trained_engine.analyze_sentiment(user_input)
        
        # Get recommendations using simple training models
        recommendations = trained_engine.get_recommendations(user_input, 5)
        
        # Format response
        response = {
            'status': 'success',
            'input_text': user_input,
            'insight': sentiment_analysis['insight'],
            'recommended_quotes': recommendations,
            'emotion_detected': sentiment_analysis['primary_emotion'],
            'confidence': sentiment_analysis['confidence'],
            'emotion_probabilities': sentiment_analysis['emotion_probabilities'],
            'processing_method': 'simple_training_ml_engine',
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"✅ Generated {len(recommendations)} recommendations for emotion: {sentiment_analysis['primary_emotion']} (confidence: {sentiment_analysis['confidence']:.2f})")
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"❌ Error processing recommendation request: {e}")
        return jsonify({
            'error': str(e),
            'status': 'error'
        }), 500

@app.route('/quotes', methods=['GET'])
def get_quotes():
    """Get all available quotes"""
    try:
        if trained_engine.quotes_df is None:
            return jsonify({
                'error': 'Quote database not available',
                'status': 'error'
            }), 500
        
        # Return a sample of quotes
        sample_size = min(100, len(trained_engine.quotes_df))
        sample_quotes = trained_engine.quotes_df.sample(n=sample_size)
        
        # Filter quotes by length
        filtered_quotes = trained_engine._filter_quotes_by_length(sample_quotes)
        
        quotes = []
        for _, quote in filtered_quotes.iterrows():
            quote_dict = {
                'text': quote['quote'] if 'quote' in quote else quote['text'],
                'author': quote.get('author', 'Unknown'),
                'emotion': quote.get('assigned_emotion', quote.get('emotion', 'general'))
            }
            quotes.append(quote_dict)
        
        response = {
            'status': 'success',
            'quotes': quotes,
            'total_quotes': len(trained_engine.quotes_df),
            'processing_method': 'trained_ml_engine'
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"❌ Error getting quotes: {e}")
        return jsonify({
            'error': str(e),
            'status': 'error'
        }), 500

@app.route('/emotions', methods=['GET'])
def get_emotions():
    """Get available emotion categories"""
    try:
        if trained_engine.emotion_classifier is None:
            return jsonify({
                'error': 'Emotion classifier not available',
                'status': 'error'
            }), 500
        
        # Get emotion classes from the trained classifier
        emotion_classes = list(trained_engine.emotion_classifier.classes_)
        
        # Get quote counts for each emotion
        emotion_counts = {}
        if trained_engine.quotes_df is not None and 'assigned_emotion' in trained_engine.quotes_df.columns:
            for emotion in emotion_classes:
                count = len(trained_engine.quotes_df[trained_engine.quotes_df['assigned_emotion'] == emotion])
                emotion_counts[emotion] = count
        
        return jsonify({
            'status': 'success',
            'emotions': emotion_classes,
            'emotion_counts': emotion_counts,
            'total_emotions': len(emotion_classes),
            'processing_method': 'trained_ml_engine'
        })
        
    except Exception as e:
        logger.error(f"❌ Error getting emotions: {e}")
        return jsonify({
            'error': str(e),
            'status': 'error'
        }), 500

if __name__ == '__main__':
    logger.info("🚀 Starting Trained WiseAI API Server...")
    logger.info("📱 API endpoints:")
    logger.info("   - POST /recommendations - Get personalized quotes")
    logger.info("   - GET  /quotes - Get all quotes")
    logger.info("   - GET  /emotions - Get emotion categories")
    logger.info("   - GET  /health - Health check")
    
    if trained_engine.is_loaded:
        logger.info("🤖 Using trained machine learning models")
        logger.info(f"📊 Dataset size: {len(trained_engine.quotes_df)} quotes")
        logger.info(f"🎯 Emotion classes: {len(trained_engine.emotion_classifier.classes_)}")
        if trained_engine.quote_clusters is not None:
            logger.info(f"📈 Quote clusters: {trained_engine.quote_clusters.n_clusters}")
        else:
            logger.info("📈 Quote clusters: Not available (using fallback)")
    else:
        logger.info("⚠️ Using fallback mode (no trained models)")
    
    logger.info("🌐 Server will be available at: http://localhost:5008")
    
    app.run(host='0.0.0.0', port=5008, debug=True) 