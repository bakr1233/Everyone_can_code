# WiseAI Project - Cleaned Up Structure

## 🎯 Project Overview
This is a cleaned-up version of the WiseAI quote recommendation system using simple training with machine learning.

## 📁 Project Structure

### 🤖 Core System Files
- **`simple_training.py`** - Simple training pipeline (491k quotes, 70% accuracy)
- **`trained_api_server.py`** - API server with simple training models (port 5008)
- **`train_quote_system.py`** - Full system training (kept for future use)

### 📊 Models & Data
- **`models/`** - Trained models directory
  - `emotion_classifier.pkl` - Trained emotion classifier
  - `vectorizer.pkl` - TF-IDF vectorizer
  - `quotes_df.pkl` - Processed quotes database
  - `metadata.json` - Training metadata
- **`data/`** - Raw and processed data

### 📱 iOS App
- **`WiseAI/`** - iOS app source code
  - `APIService.swift` - API integration (port 5008)
  - `ContentView.swift` - Main app interface
  - Other Swift files
- **`WiseAI.xcodeproj/`** - Xcode project
- **`WiseAITests/`** - iOS unit tests
- **`WiseAIUITests/`** - iOS UI tests

### 🧪 Testing Files
- **`test_simple_training.py`** - Test simple training results
- **`test_multiple_emotions.py`** - Test multiple emotion scenarios

### 📚 Documentation
- **`README.md`** - Project documentation
- **`PROBLEM_SOLUTION_SYSTEM_SUMMARY.md`** - System overview

## 🚀 Current Status

### ✅ Working Features
- **Simple Training:** 70% accuracy across 10 emotions
- **API Server:** Running on port 5008
- **Quote Filtering:** 50 words max per quote
- **iOS Integration:** Updated and working
- **Grief Detection:** 96% confidence

### 🎯 Key Capabilities
- **Emotion Detection:** 10 categories (grief, depression, anxiety, etc.)
- **Quote Recommendations:** 491k+ quotes with filtering
- **Confidence Scoring:** Shows prediction confidence
- **Mobile Ready:** iOS app integration

## 🔧 How to Use

### 1. Start API Server
```bash
python3 trained_api_server.py
```

### 2. Test Simple Training
```bash
python3 test_simple_training.py
```

### 3. Test Multiple Emotions
```bash
python3 test_multiple_emotions.py
```

### 4. Run iOS App
- Open `WiseAI.xcodeproj` in Xcode
- Build and run on simulator/device
- App connects to `http://localhost:5008`

## 📊 Performance Metrics
- **Dataset Size:** 491,914 quotes
- **Emotion Classes:** 10
- **Accuracy:** 70% overall
- **Grief Detection:** 96% confidence
- **Quote Length:** 50 words max

## 🎉 Benefits of Cleanup
- **Simplified Structure:** Only essential files
- **Clear Organization:** Easy to understand
- **Focused Functionality:** Simple training system
- **Ready for Production:** iOS app integration complete
- **Maintainable Code:** Clean, organized structure

## 🔮 Future Enhancements
- **Full Training Integration:** When `train_quote_system.py` completes
- **Additional Emotions:** Expand emotion categories
- **Performance Optimization:** Improve accuracy
- **User Analytics:** Track usage patterns 