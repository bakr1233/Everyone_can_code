#!/usr/bin/env python3
"""
WiseAI Quote System Training Module
Trains the system to better understand quote-emotion-problem relationships
"""

import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
import pickle
import json
import logging
from datetime import datetime
import os

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class QuoteSystemTrainer:
    def __init__(self, dataset_path='data/raw/quotes_problem_solution.csv'):
        self.dataset_path = dataset_path
        self.quotes_df = None
        self.vectorizer = None
        self.emotion_classifier = None
        self.problem_classifier = None
        self.quote_clusters = None
        self.training_data = None
        
    def load_dataset(self):
        """Load and preprocess the dataset"""
        try:
            logger.info(f"🔄 Loading dataset from: {self.dataset_path}")
            self.quotes_df = pd.read_csv(self.dataset_path, low_memory=False)
            logger.info(f"✅ Loaded {len(self.quotes_df)} quotes")
            
            # Clean and standardize the data
            self._clean_dataset()
            return True
        except Exception as e:
            logger.error(f"❌ Error loading dataset: {e}")
            return False
    
    def _clean_dataset(self):
        """Clean and standardize the dataset"""
        # Handle missing values
        self.quotes_df['quote'] = self.quotes_df['quote'].fillna('')
        self.quotes_df['author'] = self.quotes_df['author'].fillna('Unknown')
        self.quotes_df['category'] = self.quotes_df['category'].fillna('general')
        
        # Standardize column names to match expected format
        column_mapping = {
            'quote': 'text',
            'category': 'emotion'
        }
        self.quotes_df = self.quotes_df.rename(columns=column_mapping)
        
        # Remove duplicates
        self.quotes_df = self.quotes_df.drop_duplicates(subset=['text'])
        
        logger.info(f"✅ Dataset cleaned: {len(self.quotes_df)} unique quotes")
    
    def create_training_data(self):
        """Create training data for emotion and problem classification"""
        logger.info("🔄 Creating training data...")
        
        # Define emotion categories with keywords
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
        
        # Create training examples
        training_examples = []
        
        # Add examples from the dataset
        for _, quote in self.quotes_df.iterrows():
            quote_text = quote['text'].lower()
            quote_emotion = quote.get('emotion', 'general').lower()
            
            # Find matching emotions based on keywords
            matched_emotions = []
            for emotion, keywords in emotion_keywords.items():
                if any(keyword in quote_text for keyword in keywords):
                    matched_emotions.append(emotion)
            
            # If no emotion matched, use the quote's emotion
            if not matched_emotions:
                matched_emotions = [quote_emotion] if quote_emotion != 'general' else ['wisdom']
            
            # Create training example
            training_examples.append({
                'text': quote['text'],
                'emotion': matched_emotions[0],  # Use first matched emotion
                'author': quote['author'],
                'original_emotion': quote_emotion
            })
        
        self.training_data = pd.DataFrame(training_examples)
        logger.info(f"✅ Created {len(self.training_data)} training examples")
    
    def train_emotion_classifier(self):
        """Train a classifier to predict emotions from text"""
        logger.info("🔄 Training emotion classifier...")
        
        if self.training_data is None:
            self.create_training_data()
        
        # Prepare features
        self.vectorizer = TfidfVectorizer(
            max_features=5000,
            stop_words='english',
            ngram_range=(1, 2),
            min_df=2
        )
        
        X = self.vectorizer.fit_transform(self.training_data['text'])
        y = self.training_data['emotion']
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Train classifier
        self.emotion_classifier = RandomForestClassifier(n_estimators=100, random_state=42)
        self.emotion_classifier.fit(X_train, y_train)
        
        # Evaluate
        y_pred = self.emotion_classifier.predict(X_test)
        logger.info("📊 Emotion Classifier Performance:")
        logger.info(classification_report(y_test, y_pred))
        
        logger.info("✅ Emotion classifier trained successfully")
    
    def train_problem_classifier(self):
        """Train a classifier to identify problems from user input"""
        logger.info("🔄 Training problem classifier...")
        
        # Define problem categories
        problem_keywords = {
            'grief_loss': ['died', 'death', 'lost', 'loss', 'mom', 'mother', 'dad', 'father', 'parent', 'curse', 'hurt', 'pain', 'broken', 'scream', 'silence', 'alone', 'lonely', 'empty', 'nothing feels real', 'cannot breathe', 'barely holding on'],
            'work_stress': ['work', 'job', 'career', 'boss', 'deadline', 'meeting', 'project', 'stress', 'overwhelmed', 'tired', 'exhausted', 'burnout'],
            'relationship_issues': ['relationship', 'partner', 'boyfriend', 'girlfriend', 'husband', 'wife', 'marriage', 'divorce', 'breakup', 'fight', 'argument', 'love', 'heart'],
            'health_concerns': ['health', 'sick', 'ill', 'pain', 'doctor', 'hospital', 'medical', 'disease', 'symptoms', 'treatment'],
            'financial_worries': ['money', 'finance', 'debt', 'bills', 'expenses', 'budget', 'salary', 'income', 'financial', 'economic'],
            'self_doubt': ['confidence', 'doubt', 'believe', 'trust', 'sure', 'uncertain', 'fear', 'scared', 'insecure', 'worthless', 'failure'],
            'future_anxiety': ['future', 'tomorrow', 'plan', 'goal', 'dream', 'aspire', 'worry', 'anxious', 'uncertainty', 'unknown']
        }
        
        # Create problem training data
        problem_examples = []
        
        for _, quote in self.quotes_df.iterrows():
            quote_text = quote['text'].lower()
            
            # Find matching problems
            matched_problems = []
            for problem, keywords in problem_keywords.items():
                if any(keyword in quote_text for keyword in keywords):
                    matched_problems.append(problem)
            
            if matched_problems:
                problem_examples.append({
                    'text': quote['text'],
                    'problem': matched_problems[0]
                })
        
        problem_data = pd.DataFrame(problem_examples)
        
        if len(problem_data) > 0:
            # Train problem classifier
            X_problem = self.vectorizer.transform(problem_data['text'])
            y_problem = problem_data['problem']
            
            X_train, X_test, y_train, y_test = train_test_split(X_problem, y_problem, test_size=0.2, random_state=42)
            
            self.problem_classifier = RandomForestClassifier(n_estimators=100, random_state=42)
            self.problem_classifier.fit(X_train, y_train)
            
            # Evaluate
            y_pred = self.problem_classifier.predict(X_test)
            logger.info("📊 Problem Classifier Performance:")
            logger.info(classification_report(y_test, y_pred))
            
            logger.info("✅ Problem classifier trained successfully")
        else:
            logger.warning("⚠️ No problem training data found")
    
    def create_quote_clusters(self):
        """Create clusters of similar quotes for better recommendations"""
        logger.info("🔄 Creating quote clusters...")
        
        # Use TF-IDF features for clustering
        X = self.vectorizer.transform(self.quotes_df['text'])
        
        # Create clusters
        n_clusters = min(50, len(self.quotes_df) // 100)  # Adaptive number of clusters
        self.quote_clusters = KMeans(n_clusters=n_clusters, random_state=42)
        cluster_labels = self.quote_clusters.fit_predict(X)
        
        # Add cluster labels to dataframe
        self.quotes_df['cluster'] = cluster_labels
        
        logger.info(f"✅ Created {n_clusters} quote clusters")
    
    def save_trained_models(self, output_dir='models'):
        """Save all trained models and data"""
        logger.info("🔄 Saving trained models...")
        
        # Create output directory
        os.makedirs(output_dir, exist_ok=True)
        
        # Save models
        models = {
            'vectorizer': self.vectorizer,
            'emotion_classifier': self.emotion_classifier,
            'problem_classifier': self.problem_classifier,
            'quote_clusters': self.quote_clusters,
            'quotes_df': self.quotes_df,
            'training_data': self.training_data
        }
        
        for name, model in models.items():
            if model is not None:
                with open(f'{output_dir}/{name}.pkl', 'wb') as f:
                    pickle.dump(model, f)
                logger.info(f"✅ Saved {name}")
        
        # Save metadata
        metadata = {
            'training_date': datetime.now().isoformat(),
            'dataset_size': len(self.quotes_df),
            'vectorizer_features': self.vectorizer.get_feature_names_out().tolist() if self.vectorizer else [],
            'emotion_classes': self.emotion_classifier.classes_.tolist() if self.emotion_classifier else [],
            'problem_classes': self.problem_classifier.classes_.tolist() if self.problem_classifier else [],
            'n_clusters': self.quote_clusters.n_clusters if self.quote_clusters else 0
        }
        
        with open(f'{output_dir}/metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)
        
        logger.info("✅ All models saved successfully")
    
    def train_full_system(self):
        """Train the complete quote recommendation system"""
        logger.info("🚀 Starting full system training...")
        
        # Load dataset
        if not self.load_dataset():
            return False
        
        # Create training data
        self.create_training_data()
        
        # Train classifiers
        self.train_emotion_classifier()
        self.train_problem_classifier()
        
        # Create clusters
        self.create_quote_clusters()
        
        # Save models
        self.save_trained_models()
        
        logger.info("🎉 Full system training completed!")
        return True

def main():
    """Main training function"""
    trainer = QuoteSystemTrainer()
    success = trainer.train_full_system()
    
    if success:
        print("\n🎉 Training completed successfully!")
        print("📁 Models saved in 'models/' directory")
        print("🔧 You can now use the trained models in your API server")
    else:
        print("\n❌ Training failed. Please check the logs above.")

if __name__ == "__main__":
    main() 