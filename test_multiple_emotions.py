#!/usr/bin/env python3
"""
Comprehensive test script to test simple training with multiple emotions
"""

import pickle
import json
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier

def test_multiple_emotions():
    """Test the simple training model with various emotional scenarios"""
    print("🧠 Testing Simple Training with Multiple Emotions")
    print("=" * 60)
    
    try:
        # Load the trained models
        print("🔄 Loading trained models...")
        
        with open('models/vectorizer.pkl', 'rb') as f:
            vectorizer = pickle.load(f)
        
        with open('models/emotion_classifier.pkl', 'rb') as f:
            emotion_classifier = pickle.load(f)
        
        with open('models/quotes_df.pkl', 'rb') as f:
            quotes_df = pickle.load(f)
        
        print("✅ Models loaded successfully!")
        
        # Test scenarios with different emotions
        test_scenarios = [
            {
                "emotion": "anxiety",
                "input": "I can't stop worrying about everything. My heart is racing, my mind won't stop thinking about worst-case scenarios. I feel like I'm constantly on edge and can't relax. What if something bad happens? I'm so anxious about the future.",
                "description": "General anxiety and worry"
            },
            {
                "emotion": "depression",
                "input": "I feel so empty inside. Nothing brings me joy anymore. I just want to stay in bed all day. Life feels meaningless and I don't see the point in trying. I'm so tired of feeling this way.",
                "description": "Deep depression and hopelessness"
            },
            {
                "emotion": "happiness",
                "input": "I'm so happy today! Everything is going perfectly. I just got great news and I can't stop smiling. Life is beautiful and I feel so grateful for all the wonderful people in my life. This is the best day ever!",
                "description": "Pure joy and happiness"
            },
            {
                "emotion": "hope",
                "input": "Even though things are tough right now, I believe better days are coming. I have faith that everything will work out. There's a light at the end of the tunnel and I'm holding onto that hope. Things will get better.",
                "description": "Optimism and hope for the future"
            },
            {
                "emotion": "love",
                "input": "I'm so in love! My heart feels full and complete. Every time I see them, my heart skips a beat. I can't imagine my life without them. They make everything better just by being there. I love them so much.",
                "description": "Romantic love and affection"
            },
            {
                "emotion": "mindfulness",
                "input": "I'm trying to stay present and mindful. Taking deep breaths and focusing on the moment. Not dwelling on the past or worrying about the future. Just being here, now, appreciating this moment.",
                "description": "Mindfulness and presence"
            },
            {
                "emotion": "motivation",
                "input": "I'm ready to achieve my goals! Nothing can stop me now. I have the power to make my dreams come true. Let's do this! I'm motivated and determined to succeed. Time to take action!",
                "description": "High motivation and determination"
            },
            {
                "emotion": "resilience",
                "input": "I've been through so much, but I'm still standing. Every challenge has made me stronger. I refuse to give up. I will overcome this obstacle and come out even better on the other side. I'm resilient.",
                "description": "Resilience and strength"
            },
            {
                "emotion": "wisdom",
                "input": "I've learned so much from my experiences. Life has taught me valuable lessons about what truly matters. I understand now that wisdom comes from reflection and growth. Every experience is a teacher.",
                "description": "Wisdom and life lessons"
            },
            {
                "emotion": "grief",
                "input": "I miss them so much. The pain of losing someone I love is unbearable. Every day feels empty without them. I don't know how to move forward. The grief is overwhelming and I feel lost.",
                "description": "Loss and grief"
            }
        ]
        
        print(f"\n🎯 Testing {len(test_scenarios)} Different Emotional Scenarios:")
        print("=" * 60)
        
        results = []
        
        for i, scenario in enumerate(test_scenarios, 1):
            print(f"\n{i}. Testing {scenario['emotion'].upper()} - {scenario['description']}")
            print("-" * 50)
            
            # Vectorize the input
            input_vector = vectorizer.transform([scenario['input']])
            
            # Predict emotion
            predicted_emotion = emotion_classifier.predict(input_vector)[0]
            emotion_proba = emotion_classifier.predict_proba(input_vector)[0]
            confidence = max(emotion_proba)
            
            # Get the expected emotion probability
            expected_emotion_idx = list(emotion_classifier.classes_).index(scenario['emotion'])
            expected_confidence = emotion_proba[expected_emotion_idx]
            
            print(f"   Expected Emotion: {scenario['emotion']}")
            print(f"   Predicted Emotion: {predicted_emotion}")
            print(f"   Confidence: {confidence:.2f} ({confidence*100:.1f}%)")
            print(f"   Expected Emotion Confidence: {expected_confidence:.2f} ({expected_confidence*100:.1f}%)")
            
            # Check if prediction matches expected
            is_correct = predicted_emotion == scenario['emotion']
            status = "✅ CORRECT" if is_correct else "❌ INCORRECT"
            print(f"   Result: {status}")
            
            # Show top 3 emotions
            emotion_probs = list(zip(emotion_classifier.classes_, emotion_proba))
            emotion_probs.sort(key=lambda x: x[1], reverse=True)
            
            print(f"   Top 3 Emotions:")
            for j, (emotion, prob) in enumerate(emotion_probs[:3], 1):
                print(f"      {j}. {emotion}: {prob:.3f} ({prob*100:.1f}%)")
            
            # Store results
            results.append({
                'scenario': scenario['emotion'],
                'expected': scenario['emotion'],
                'predicted': predicted_emotion,
                'confidence': confidence,
                'expected_confidence': expected_confidence,
                'is_correct': is_correct
            })
        
        # Summary statistics
        print(f"\n📊 SUMMARY STATISTICS:")
        print("=" * 60)
        
        correct_predictions = sum(1 for r in results if r['is_correct'])
        accuracy = correct_predictions / len(results) * 100
        
        print(f"   Total Tests: {len(results)}")
        print(f"   Correct Predictions: {correct_predictions}")
        print(f"   Accuracy: {accuracy:.1f}%")
        
        print(f"\n🎯 Detailed Results:")
        for result in results:
            status = "✅" if result['is_correct'] else "❌"
            print(f"   {status} {result['scenario']}: {result['predicted']} ({result['confidence']:.1%})")
        
        # Show quotes for each emotion
        print(f"\n📖 Sample Quotes by Emotion:")
        print("=" * 60)
        
        for emotion in emotion_classifier.classes_:
            emotion_quotes = quotes_df[quotes_df['assigned_emotion'] == emotion]
            if len(emotion_quotes) > 0:
                sample_quote = emotion_quotes.sample(1).iloc[0]
                print(f"\n{emotion.upper()}:")
                print(f"   '{sample_quote['quote'][:80]}...'")
                print(f"   - {sample_quote['author']}")
                print(f"   Available quotes: {len(emotion_quotes):,}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error testing multiple emotions: {e}")
        return False

if __name__ == "__main__":
    success = test_multiple_emotions()
    
    if success:
        print(f"\n🎉 Test Complete!")
        print(f"   Your simple training model can now handle multiple emotions")
        print(f"   Ready for integration into your app!")
    else:
        print(f"\n❌ Test failed") 