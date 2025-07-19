#!/usr/bin/env python3
"""
Simple Quote System Training
Quick training for better quote recommendations
"""

import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier
import pickle
import json
import logging
from datetime import datetime
import os

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def train_simple_system():
    """Train a simple but effective quote recommendation system"""
    logger.info("🚀 Starting simple system training...")
    
    try:
        # Load dataset
        logger.info("🔄 Loading dataset...")
        df = pd.read_csv('data/raw/quotes_problem_solution.csv', low_memory=False)
        logger.info(f"✅ Loaded {len(df)} quotes")
        
        # Clean data
        df['quote'] = df['quote'].fillna('')
        df['author'] = df['author'].fillna('Unknown')
        df['category'] = df['category'].fillna('general')
        
        # Remove duplicates
        df = df.drop_duplicates(subset=['quote'])
        logger.info(f"✅ Cleaned dataset: {len(df)} unique quotes")
        
        # Create emotion mapping
        emotion_keywords = {
            'grief': ['grief', 'loss', 'death', 'died', 'lost', 'mourning', 'bereavement', 'sadness', 'pain', 'hurt', 'broken', 'curse', 'silence', 'alone', 'lonely', 'empty', 'nothing feels real', 'cannot breathe', 'barely holding on'],
            'depression': ['depressed', 'sad', 'hopeless', 'despair', 'tired', 'exhausted', 'broken', 'hurt', 'pain', 'suffering', 'dark', 'empty', 'numb', 'nothing matters', 'why does it hurt', 'exist', 'did not ask for this'],
            'anxiety': ['anxious', 'worry', 'fear', 'scared', 'panic', 'stress', 'overwhelmed', 'cannot breathe', 'tight', 'nervous', 'restless', 'scream'],
            'motivation': ['motivated', 'motivate', 'drive', 'energy', 'work', 'career', 'goal', 'achieve', 'success', 'inspire', 'dream', 'aspire'],
            'resilience': ['failure', 'fail', 'challenge', 'difficult', 'hard', 'struggle', 'overcome', 'persevere', 'tough', 'strength', 'courage'],
            'mindfulness': ['mind', 'think', 'thought', 'calm', 'peace', 'meditation', 'present', 'breathe', 'breath'],
            'happiness': ['happy', 'happiness', 'joy', 'cheer', 'bright', 'smile', 'laugh', 'delight', 'pleasure'],
            'love': ['love', 'heart', 'relationship', 'romance', 'affection', 'care', 'cherish', 'adore'],
            'wisdom': ['wisdom', 'learn', 'knowledge', 'experience', 'understand', 'insight', 'truth', 'philosophy'],
            'hope': ['hope', 'faith', 'believe', 'trust', 'optimism', 'positive', 'future', 'better', 'light', 'heal']
        }
        
        # Assign emotions to quotes
        logger.info("🔄 Assigning emotions to quotes...")
        assigned_emotions = []
        
        for _, row in df.iterrows():
            quote_text = row['quote'].lower()
            matched_emotions = []
            
            for emotion, keywords in emotion_keywords.items():
                if any(keyword in quote_text for keyword in keywords):
                    matched_emotions.append(emotion)
            
            if matched_emotions:
                assigned_emotions.append(matched_emotions[0])
            else:
                assigned_emotions.append('wisdom')  # Default
        
        df['assigned_emotion'] = assigned_emotions
        
        # Create TF-IDF vectorizer
        logger.info("🔄 Creating TF-IDF vectorizer...")
        vectorizer = TfidfVectorizer(
            max_features=3000,
            stop_words='english',
            ngram_range=(1, 2),
            min_df=5
        )
        
        # Fit vectorizer
        X = vectorizer.fit_transform(df['quote'])
        y = df['assigned_emotion']
        
        # Train emotion classifier
        logger.info("🔄 Training emotion classifier...")
        emotion_classifier = RandomForestClassifier(n_estimators=50, random_state=42)
        emotion_classifier.fit(X, y)
        
        # Test the classifier
        test_quotes = [
            "Every night feels like a curse I cannot breathe without remembering what I lost",
            "I need motivation to achieve my goals",
            "I am feeling anxious and overwhelmed",
            "I want to find happiness in life"
        ]
        
        test_vectors = vectorizer.transform(test_quotes)
        predictions = emotion_classifier.predict(test_vectors)
        
        logger.info("📊 Test predictions:")
        for quote, pred in zip(test_quotes, predictions):
            logger.info(f"  '{quote[:50]}...' -> {pred}")
        
        # Save models
        logger.info("🔄 Saving models...")
        os.makedirs('models', exist_ok=True)
        
        models = {
            'vectorizer': vectorizer,
            'emotion_classifier': emotion_classifier,
            'quotes_df': df
        }
        
        for name, model in models.items():
            with open(f'models/{name}.pkl', 'wb') as f:
                pickle.dump(model, f)
            logger.info(f"✅ Saved {name}")
        
        # Save metadata
        metadata = {
            'training_date': datetime.now().isoformat(),
            'dataset_size': len(df),
            'emotion_classes': emotion_classifier.classes_.tolist(),
            'vectorizer_features': len(vectorizer.get_feature_names_out())
        }
        
        with open('models/metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)
        
        logger.info("✅ All models saved successfully")
        logger.info("🎉 Simple training completed!")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Training failed: {e}")
        return False

if __name__ == "__main__":
    success = train_simple_system()
    
    if success:
        print("\n🎉 Training completed successfully!")
        print("📁 Models saved in 'models/' directory")
        print("🔧 You can now use the trained models in your API server")
    else:
        print("\n❌ Training failed. Please check the logs above.") 