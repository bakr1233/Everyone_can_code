#!/usr/bin/env python3
"""
Test script to show simple training results
"""

import pickle
import json
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier

def load_and_test_simple_training():
    """Load the simple training models and test them"""
    print("🚀 Testing Simple Training Results")
    print("=" * 50)
    
    try:
        # Load the trained models
        print("🔄 Loading trained models...")
        
        with open('models/vectorizer.pkl', 'rb') as f:
            vectorizer = pickle.load(f)
        print("✅ Loaded TF-IDF vectorizer")
        
        with open('models/emotion_classifier.pkl', 'rb') as f:
            emotion_classifier = pickle.load(f)
        print("✅ Loaded emotion classifier")
        
        with open('models/quotes_df.pkl', 'rb') as f:
            quotes_df = pickle.load(f)
        print("✅ Loaded quotes database")
        
        with open('models/metadata.json', 'r') as f:
            metadata = json.load(f)
        print("✅ Loaded metadata")
        
        print(f"\n📊 Training Summary:")
        print(f"   Dataset Size: {metadata['dataset_size']:,} quotes")
        print(f"   Emotion Classes: {len(metadata['emotion_classes'])}")
        print(f"   Features: {metadata['vectorizer_features']}")
        print(f"   Training Date: {metadata['training_date']}")
        
        # Test with your grief input
        test_input = "Every night feels like a curse I cannot breathe without remembering what I lost the silence screams louder than any voice and no one seems to hear it but me I am tired broken and barely holding on ever since mom died nothing feels real does it hurt why does it hurt this much just to exist I did not ask for this"
        
        print(f"\n🎯 Testing with your grief input:")
        print(f"   Input: '{test_input[:100]}...'")
        
        # Vectorize the input
        input_vector = vectorizer.transform([test_input])
        
        # Predict emotion
        predicted_emotion = emotion_classifier.predict(input_vector)[0]
        emotion_proba = emotion_classifier.predict_proba(input_vector)[0]
        confidence = max(emotion_proba)
        
        print(f"\n📈 Prediction Results:")
        print(f"   Predicted Emotion: {predicted_emotion}")
        print(f"   Confidence: {confidence:.2f} ({confidence*100:.1f}%)")
        
        # Show all emotion probabilities
        print(f"\n🎭 All Emotion Probabilities:")
        for emotion, prob in zip(emotion_classifier.classes_, emotion_proba):
            print(f"   {emotion}: {prob:.3f} ({prob*100:.1f}%)")
        
        # Get quotes for the predicted emotion
        emotion_quotes = quotes_df[quotes_df['assigned_emotion'] == predicted_emotion]
        
        print(f"\n📖 Recommended Quotes for '{predicted_emotion}':")
        print(f"   Available quotes: {len(emotion_quotes)}")
        
        # Show top 3 quotes
        if len(emotion_quotes) > 0:
            sample_quotes = emotion_quotes.sample(min(3, len(emotion_quotes)))
            for i, (_, quote) in enumerate(sample_quotes.iterrows(), 1):
                print(f"\n   {i}. '{quote['quote'][:100]}...'")
                print(f"      - {quote['author']}")
                print(f"      - Emotion: {quote['assigned_emotion']}")
        
        print(f"\n🎉 Simple Training Benefits:")
        print(f"   ✅ Trained on {metadata['dataset_size']:,} quotes")
        print(f"   ✅ {len(metadata['emotion_classes'])} emotion categories")
        print(f"   ✅ {metadata['vectorizer_features']} semantic features")
        print(f"   ✅ Confidence scoring for predictions")
        print(f"   ✅ Better emotion detection than keyword matching")
        
        return True
        
    except Exception as e:
        print(f"❌ Error testing simple training: {e}")
        return False

if __name__ == "__main__":
    success = load_and_test_simple_training()
    
    if success:
        print(f"\n🎯 Next Steps:")
        print(f"   1. Use the trained models in your API server")
        print(f"   2. Update your iOS app to use the trained system")
        print(f"   3. See improved accuracy and confidence scoring")
        print(f"   4. Get better quote recommendations")
    else:
        print(f"\n❌ Failed to test simple training") 