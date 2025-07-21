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
        self.quotes_df = None
        self.is_loaded = False
        self.emotion_keywords = {
            'grief': ['grief', 'loss', 'death', 'died', 'lost', 'mourning', 'bereavement', 'sadness', 'pain', 'hurt', 'broken', 'alone', 'lonely', 'empty'],
            'depression': ['depressed', 'sad', 'hopeless', 'despair', 'tired', 'exhausted', 'broken', 'hurt', 'pain', 'suffering', 'dark', 'empty', 'numb'],
            'anxiety': ['anxious', 'worry', 'fear', 'scared', 'panic', 'stress', 'overwhelmed', 'nervous', 'restless'],
            'motivation': ['motivated', 'motivate', 'drive', 'energy', 'work', 'career', 'goal', 'achieve', 'success', 'inspire', 'dream', 'aspire'],
            'resilience': ['failure', 'fail', 'challenge', 'difficult', 'hard', 'struggle', 'overcome', 'persevere', 'tough', 'strength', 'courage'],
            'mindfulness': ['mind', 'think', 'thought', 'calm', 'peace', 'meditation', 'present', 'breathe', 'breath'],
            'happiness': ['happy', 'happiness', 'joy', 'cheer', 'bright', 'smile', 'laugh', 'delight', 'pleasure'],
            'love': ['love', 'heart', 'relationship', 'romance', 'affection', 'care', 'cherish', 'adore'],
            'wisdom': ['wisdom', 'learn', 'knowledge', 'experience', 'understand', 'insight', 'truth', 'philosophy'],
            'hope': ['hope', 'faith', 'believe', 'trust', 'optimism', 'positive', 'future', 'better', 'light', 'heal']
        }
        self.emotions = list(self.emotion_keywords.keys())
        self.metadata = None
        
    def load_models(self):
        """Load trained models"""
        try:
            import pandas as pd, os
            # Load merged and cleaned archive CSV
            all_quotes_path = os.path.join('data', 'processed', 'all_archive_quotes_cleaned.csv')
            if os.path.exists(all_quotes_path):
                self.quotes_df = pd.read_csv(all_quotes_path)
                self.is_loaded = True
            else:
                self.quotes_df = None
                self.is_loaded = False
            return self.is_loaded
        except Exception as e:
            self.is_loaded = False
            return False
    
    def detect_emotion(self, user_input: str) -> str:
        """Analyze user input using trained emotion classifier"""
        user_input_lower = user_input.lower()
        for emotion, keywords in self.emotion_keywords.items():
            for kw in keywords:
                if kw in user_input_lower:
                    return emotion
        return 'general'
    
    def is_relevant_grief_quote(self, quote):
        text = str(quote).lower()
        grief_keywords = ['death', 'died', 'loss', 'lost', 'grief', 'mourning', 'bereavement']
        relationship_keywords = ['mother', 'father', 'mom', 'dad', 'parent', 'friend', 'sister', 'brother', 'loved one', 'husband', 'wife', 'child', 'son', 'daughter']
        return (any(gk in text for gk in grief_keywords) and any(rk in text for rk in relationship_keywords))

    def is_relevant_love_quote(self, quote):
        text = str(quote).lower()
        love_keywords = ['love', 'heart', 'romance', 'affection', 'cherish', 'adore', 'relationship']
        breakup_keywords = ['breakup', 'break up', 'broken heart', 'lost love', 'separation', 'divorce', 'unrequited', 'rejected', 'ex-', 'ex ']
        return (any(lk in text for lk in love_keywords) and any(bk in text for bk in breakup_keywords))

    def is_relevant_loneliness_quote(self, quote):
        text = str(quote).lower()
        loneliness_keywords = ['lonely', 'alone', 'isolation', 'solitude', 'abandoned', 'left out', 'friendless', 'nobody', 'by myself']
        sadness_keywords = ['sad', 'depressed', 'hopeless', 'empty', 'cry', 'pain', 'hurt']
        return (any(lk in text for lk in loneliness_keywords) and any(sk in text for sk in sadness_keywords))

    def is_relevant_failure_quote(self, quote):
        text = str(quote).lower()
        failure_keywords = ['fail', 'failure', 'mistake', 'lost', 'defeat', 'give up', 'quit', 'setback', 'disappoint']
        growth_keywords = ['learn', 'growth', 'try', 'improve', 'overcome', 'persevere', 'resilience', 'bounce back']
        return (any(fk in text for fk in failure_keywords) and any(gk in text for gk in growth_keywords))

    def is_relevant_motivation_quote(self, quote):
        text = str(quote).lower()
        motivation_keywords = ['motivate', 'motivation', 'inspire', 'drive', 'goal', 'achieve', 'success', 'dream', 'aspire', 'ambition']
        action_keywords = ['action', 'work', 'do', 'start', 'begin', 'move', 'push', 'progress', 'step', 'effort']
        return (any(mk in text for mk in motivation_keywords) and any(ak in text for ak in action_keywords))

    def is_relevant_happiness_quote(self, quote):
        text = str(quote).lower()
        happiness_keywords = ['happy', 'happiness', 'joy', 'cheer', 'smile', 'delight', 'pleasure', 'content', 'enjoy']
        life_keywords = ['life', 'living', 'moment', 'present', 'now', 'enjoy', 'grateful', 'gratitude']
        return (any(hk in text for hk in happiness_keywords) and any(lk in text for lk in life_keywords))

    def is_relevant_anxiety_quote(self, quote):
        text = str(quote).lower()
        anxiety_keywords = ['anxious', 'anxiety', 'panic', 'worry', 'worried', 'nervous', 'restless']
        stress_keywords = ['stress', 'fear', 'afraid', 'overwhelmed', 'scared', 'pressure']
        return (any(ak in text for ak in anxiety_keywords) and any(sk in text for sk in stress_keywords))

    def is_relevant_depression_quote(self, quote):
        text = str(quote).lower()
        depression_keywords = ['depressed', 'depression', 'hopeless', 'despair', 'numb', 'empty', 'worthless', 'tired', 'exhausted']
        hopelessness_keywords = ['hopeless', 'meaningless', 'pointless', 'empty', 'alone', 'dark', 'lost', 'nothing matters']
        return (any(dk in text for dk in depression_keywords) and any(hk in text for hk in hopelessness_keywords))
    
    def is_relevant_burnout_quote(self, quote):
        text = str(quote).lower()
        burnout_keywords = ['burnout', 'burnt out', 'tired', 'exhausted', 'overwhelmed', 'hopeless', 'gave up', 'no power', "can't continue", 'fatigued', 'drained']
        study_keywords = ['school', 'study', 'studying', 'exam', 'university', 'class', 'homework', 'assignment', 'test', 'grades', 'college', 'education', 'teacher', 'student']
        return (any(bk in text for bk in burnout_keywords) and any(sk in text for sk in study_keywords))

    def is_relevant_breakup_quote(self, quote):
        text = str(quote).lower()
        love_keywords = ['love', 'heart', 'romance', 'affection', 'cherish', 'adore', 'relationship']
        breakup_keywords = [
            'breakup', 'break up', 'broken heart', 'lost love', 'separation', 'divorce', 'unrequited', 'rejected',
            'ex-', 'ex ', 'move on', 'heartbreak', 'left me', 'cheated', 'another person', 'dumped', 'relationship ended'
        ]
        return (any(lk in text for lk in love_keywords) and any(bk in text for bk in breakup_keywords))

    def get_recommendations(self, user_input: str, top_k: int = 5) -> list:
        """Get personalized quote recommendations using simple training models"""
        if not self.is_loaded or self.quotes_df is None:
            return []
        emotion = self.detect_emotion(user_input)
        if 'assigned_emotion' in self.quotes_df.columns:
            emotion_quotes = self.quotes_df[self.quotes_df['assigned_emotion'].str.lower() == emotion]
        else:
            emotion_quotes = self.quotes_df[self.quotes_df['emotion'].str.lower() == emotion]
        if emotion_quotes.empty and emotion != 'general':
            # fallback to general
            if 'assigned_emotion' in self.quotes_df.columns:
                emotion_quotes = self.quotes_df[self.quotes_df['assigned_emotion'].str.lower() == 'general']
            else:
                emotion_quotes = self.quotes_df[self.quotes_df['emotion'].str.lower() == 'general']
        # Multi-keyword/context filtering for sensitive emotions
        if emotion == 'grief':
            emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_grief_quote)]
        elif emotion == 'love':
            # Breakup context filter
            breakup_keywords = [
                'breakup', 'break up', 'broken heart', 'lost love', 'separation', 'divorce', 'unrequited', 'rejected',
                'ex-', 'ex ', 'move on', 'heartbreak', 'left me', 'cheated', 'another person', 'dumped', 'relationship ended'
            ]
            if any(word in user_input.lower() for word in breakup_keywords):
                filtered = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_breakup_quote)]
                if not filtered.empty:
                    emotion_quotes = filtered
                else:
                    # fallback: any quote with a breakup keyword
                    emotion_quotes = emotion_quotes[emotion_quotes['quote'].str.lower().str.contains('|'.join(breakup_keywords))]
            else:
                emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_love_quote)]
        elif emotion == 'anxiety':
            emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_anxiety_quote)]
        elif emotion == 'depression':
            emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_depression_quote)]
        elif emotion == 'happiness':
            emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_happiness_quote)]
        elif emotion == 'motivation':
            emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_motivation_quote)]
        elif emotion == 'resilience':
            emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_failure_quote)]
        elif emotion == 'mindfulness':
            emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_loneliness_quote)]
        # Burnout/study/school context filter
        burnout_input_keywords = ['burnout', 'burnt out', 'study', 'school', 'exam', 'university', 'class', 'homework', 'assignment', 'test', 'grades', 'college', 'education', 'teacher', 'student']
        if any(word in user_input.lower() for word in burnout_input_keywords):
            emotion_quotes = emotion_quotes[emotion_quotes['quote'].apply(self.is_relevant_burnout_quote)]
        # Filter by length
        emotion_quotes = self._filter_quotes_by_length(emotion_quotes)
        if len(emotion_quotes) <= top_k:
            selected_quotes = emotion_quotes
        else:
            selected_quotes = emotion_quotes.sample(n=top_k, random_state=42)
        results = []
        for _, quote in selected_quotes.iterrows():
            results.append({
                'text': quote['quote'] if 'quote' in quote else quote['text'],
                'author': quote.get('author', 'Unknown'),
                'emotion': emotion
            })
        return results
    
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
        'processing_method': 'simple_keyword_engine',
        'models_available': {
            'quotes_df': trained_engine.quotes_df is not None
        },
        'dataset_info': {
            'total_quotes': len(trained_engine.quotes_df) if trained_engine.quotes_df is not None else 0,
            'emotion_classes': len(trained_engine.emotions) if hasattr(trained_engine, 'emotions') else 0
        }
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
        emotion = trained_engine.detect_emotion(user_input)
        
        # Get recommendations using simple training models
        recommendations = trained_engine.get_recommendations(user_input, 5)
        
        # Format response
        response = {
            'status': 'success',
            'input_text': user_input,
            'insight': "I understand what you're going through. You're not alone in this journey.",
            'recommended_quotes': recommendations,
            'emotion_detected': emotion,
            'confidence': 0.7, # Placeholder confidence
            'emotion_probabilities': {}, # Placeholder probabilities
            'processing_method': 'simple_training_ml_engine',
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"✅ Generated {len(recommendations)} recommendations for emotion: {emotion}")
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
        # Remove or update the following line since emotion_classifier is not used anymore
        # logger.info(f"🎯 Emotion classes: {len(trained_engine.emotion_classifier.classes_)}")
        logger.info(f"🎯 Emotion classes: {len(trained_engine.emotions)}")
        if hasattr(trained_engine, 'quote_clusters') and trained_engine.quote_clusters is not None:
            logger.info(f"📈 Quote clusters: {trained_engine.quote_clusters.n_clusters}")
        else:
            logger.info("📈 Quote clusters: Not available (using fallback)")
    else:
        logger.info("⚠️ Using fallback mode (no trained models)")
    
    logger.info("🌐 Server will be available at: http://localhost:5008")
    
    app.run(host='0.0.0.0', port=5008, debug=True) 