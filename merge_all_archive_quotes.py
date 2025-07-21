import pandas as pd
import os

# Helper to count words
def word_count(text):
    if pd.isna(text) or not isinstance(text, str):
        return 0
    return len(text.split())

# Emotion keyword mapping
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

def assign_emotion(text, tags=None):
    text = str(text).lower()
    tags = str(tags).lower() if tags else ''
    for emotion, keywords in EMOTION_KEYWORDS.items():
        for kw in keywords:
            if kw in text or kw in tags:
                return emotion
    return 'general'

# Paths to archive files
data_dir = os.path.join('Everyone_can_code', 'data', 'processed', 'archive')
files = [
    'quotes.csv',
    'stoic_quotes_full.csv',
    'lessreal-data.csv',
    'Scraping_done.csv',
]

# Load and normalize all files
dfs = []
for fname in files:
    fpath = os.path.join(data_dir, fname)
    if not os.path.exists(fpath):
        print(f"[SKIP] File not found: {fname}")
        continue
    if fname == 'quotes.csv':
        df = pd.read_csv(fpath, usecols=['quote','author','category'])
        df = df.rename(columns={'category':'tags'})
    elif fname == 'stoic_quotes_full.csv':
        df = pd.read_csv(fpath)
        df = df.rename(columns={'Quote':'quote','Author':'author','Tags':'tags'})
    elif fname == 'lessreal-data.csv':
        df = pd.read_csv(fpath, sep=';')
        if 'Character' in df.columns and 'Quote' in df.columns:
            df = df[['Character', 'Quote']].rename(columns={'Character': 'author', 'Quote': 'quote'})
            df['tags'] = ''
        else:
            print(f"[SKIP] Missing columns in {fname}")
            continue
    elif fname == 'Scraping_done.csv':
        df = pd.read_csv(fpath)
        if 'quotes' in df.columns:
            df = df.rename(columns={'quotes':'quote','authors':'author'})
            if 'Unnamed: 0' in df.columns:
                df = df.drop(columns=['Unnamed: 0'])
        elif 'Quote' in df.columns:
            df = df.rename(columns={'Quote':'quote','Author':'author'})
        if 'tags' not in df.columns:
            df['tags'] = ''
    else:
        continue
    df = df.dropna(subset=['quote'])
    # Ensure required columns
    if not all(col in df.columns for col in ['quote','author','tags']):
        print(f"[SKIP] After processing, missing columns in {fname}: {df.columns}")
        continue
    if not df.empty:
        dfs.append(df[['quote','author','tags']])
        print(f"[OK] Loaded {len(df)} quotes from {fname}")
    else:
        print(f"[SKIP] No data in {fname}")

# Merge all
if not dfs:
    print("[ERROR] No dataframes to concatenate! Exiting.")
    exit(1)
all_quotes = pd.concat(dfs, ignore_index=True)

# Remove duplicates
all_quotes = all_quotes.drop_duplicates(subset=['quote'])

# Filter by length (65 words or less)
all_quotes = all_quotes[all_quotes['quote'].apply(word_count) <= 65]

# Assign emotion
all_quotes['emotion'] = all_quotes.apply(lambda row: assign_emotion(row['quote'], row['tags']), axis=1)

# Save cleaned dataset
output_path = os.path.join('Everyone_can_code', 'data', 'processed', 'all_archive_quotes_cleaned.csv')
all_quotes.to_csv(output_path, index=False)
print(f"Merged and cleaned dataset saved to {output_path}. Total quotes: {len(all_quotes)}") 