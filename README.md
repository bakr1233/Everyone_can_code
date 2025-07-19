# 🧠 WiseAI - Intelligent Quote Recommendation System

A comprehensive iOS app with advanced NLP capabilities for personalized quote recommendations based on user speech and emotions.

## 📁 **Project Structure**

```
WiseAI/
├── 📱 WiseAI/                    # iOS App
│   ├── WiseAI/                   # Main app files
│   ├── WiseAI.xcodeproj/         # Xcode project
│   └── WiseAITests/              # iOS tests
├── 🐍 nlp_pipeline/              # Python NLP System
│   ├── quote_processor.py        # Quote processing & embedding
│   ├── recommendation_engine.py  # Recommendation system
│   ├── config.json              # Configuration
│   └── requirements*.txt        # Dependencies
├── 📊 data/                      # Data Management
│   ├── raw/                     # Raw datasets
│   ├── processed/               # Processed quotes
│   └── embeddings/              # Generated embeddings
├── 🔧 scripts/                   # Utility Scripts
│   ├── test_nlp_pipeline.py     # System testing
│   └── process_quotes_for_ios.py # iOS integration
├── 📚 docs/                      # Documentation
│   ├── TESTING_GUIDE.md         # Testing instructions
│   └── ENHANCED_SETUP.md        # Setup guide
├── 🧪 tests/                     # Test files
├── 📝 main.py                    # Main orchestration script
└── README.md                     # This file
```

## 🚀 **Quick Start**

### **1. Setup the System**
```bash
# Run the main script to set up everything
python3 main.py
```

### **2. Build iOS App**
```bash
cd WiseAI
xcodebuild -project WiseAI.xcodeproj -scheme WiseAI -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### **3. Run in Simulator**
```bash
xcrun simctl install "iPhone 16" /path/to/WiseAI.app
xcrun simctl launch "iPhone 16" WiseAI.WiseAI
```

## 🎯 **Features**

### **iOS App Features**
- 🎤 **Audio Recording** with speech recognition
- 🧠 **AI Analysis** of user speech and emotions
- 💬 **Personalized Quotes** based on context
- 📱 **Modern SwiftUI** interface
- 🔒 **Privacy-First** design

### **NLP Pipeline Features**
- 📝 **Quote Processing** with emotion categorization
- 🔍 **Semantic Search** using SentenceTransformers
- 🎯 **Personalized Recommendations** 
- 🗣️ **Speech-to-Text** integration
- 🧮 **Embedding Generation** and clustering

## 📊 **Data Flow**

1. **Raw Quotes** → `data/raw/quotes.csv`
2. **Processing** → `nlp_pipeline/quote_processor.py`
3. **Embeddings** → `data/embeddings/quote_embeddings.pkl`
4. **iOS Format** → `WiseAI/WiseAI/quotes_ios.json`
5. **App Integration** → Personalized recommendations

## 🛠️ **Development**

### **Adding New Quotes**
```bash
# Place your quotes CSV in data/raw/
# Run the processing pipeline
python3 main.py
```

### **Testing the System**
```bash
# Run comprehensive tests
python3 scripts/test_nlp_pipeline.py

# Test specific components
python3 -c "from nlp_pipeline.recommendation_engine import QuoteRecommendationEngine; print('System ready!')"
```

### **iOS Development**
```bash
# Open in Xcode
open WiseAI/WiseAI.xcodeproj

# Build from command line
cd WiseAI && xcodebuild -project WiseAI.xcodeproj -scheme WiseAI build
```

## 📋 **Requirements**

### **Python Dependencies**
- Python 3.8+
- pandas, numpy, scikit-learn
- transformers, torch, sentence-transformers
- nltk, openai-whisper

### **iOS Requirements**
- Xcode 15+
- iOS 17.0+
- Microphone permission

## 🧪 **Testing**

### **Audio Features**
1. Open WiseAI app in simulator
2. Navigate to Audio tab
3. Tap Record and speak
4. Verify personalized insights

### **NLP Pipeline**
```bash
# Test the complete pipeline
python3 scripts/test_nlp_pipeline.py

# Test with your dataset
python3 main.py
```

## 📈 **Performance**

- **Quote Processing**: ~10 seconds for 1000 quotes
- **Recommendation Generation**: < 1 second
- **Audio Analysis**: < 5 seconds for 30-second recording
- **Memory Usage**: < 2GB for full pipeline

## 🔧 **Configuration**

Edit `nlp_pipeline/config.json` to customize:
- Embedding dimensions
- Clustering parameters
- Model settings
- File paths

## 🐛 **Troubleshooting**

### **Common Issues**
- **Permission denied**: Check microphone settings
- **Import errors**: Install missing dependencies
- **Memory issues**: Reduce batch size in config
- **Build failures**: Check Xcode project settings

### **Getting Help**
1. Check `docs/TESTING_GUIDE.md` for detailed testing
2. Review error logs in Xcode console
3. Verify all dependencies are installed
4. Ensure dataset is in correct format

## 📄 **License**

This project is for educational and personal use.

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**Ready to get started?** Run `python3 main.py` to set up the complete system! 🚀
