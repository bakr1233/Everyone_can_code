import pandas as pd
import os

# Define emotion keywords
EMOTION_KEYWORDS = {
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

# Helper to assign emotion
def assign_emotion(text, tags=None):
    text = str(text).lower()
    tags = str(tags).lower() if tags else ''
    for emotion, keywords in EMOTION_KEYWORDS.items():
        for kw in keywords:
            if kw in text or kw in tags:
                return emotion
    return 'general'

# Load lessreal-data.csv
lessreal_path = os.path.join('data', 'raw', 'New quote data', 'lessreal-data.csv')
lessreal = pd.read_csv(lessreal_path, sep=';', usecols=[2,3], names=['author','quote'], header=0, encoding='utf-8', engine='python')
lessreal = lessreal.dropna(subset=['quote'])
lessreal['emotion'] = lessreal['quote'].apply(assign_emotion)

# Load stoic_quotes_full.csv
stoic_path = os.path.join('data', 'raw', 'New quote data', 'stoic_quotes_full.csv')
stoic = pd.read_csv(stoic_path)
stoic = stoic.rename(columns={'Quote':'quote','Author':'author','Tags':'tags'})
stoic = stoic.dropna(subset=['quote'])
stoic['emotion'] = stoic.apply(lambda row: assign_emotion(row['quote'], row.get('tags','')), axis=1)

# Select columns and merge
df = pd.concat([
    lessreal[['quote','author','emotion']],
    stoic[['quote','author','emotion']]
], ignore_index=True)

# Remove duplicates
final_df = df.drop_duplicates(subset=['quote'])

# Save merged dataset
output_path = os.path.join('data', 'processed', 'all_quotes.csv')
final_df.to_csv(output_path, index=False)
print(f"Merged dataset saved to {output_path}. Total quotes: {len(final_df)}") 