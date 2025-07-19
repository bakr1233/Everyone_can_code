# WiseAI - Intelligent Quote Recommendation System

A comprehensive AI-powered quote recommendation system with iOS app integration, featuring emotion-based quote matching and intelligent problem-solution guidance.

## 🚀 Features

### 🤖 AI-Powered Quote System
- **Emotion Classification**: Machine learning model trained on 491,914 quotes
- **Problem-Solution Matching**: Intelligent quote recommendations based on user problems
- **TF-IDF Vectorization**: Advanced text processing for accurate matching
- **Random Forest Classifier**: High-accuracy emotion classification (70%+ accuracy)

### 📱 iOS App Integration
- **SwiftUI Interface**: Modern, responsive iOS app
- **Real-time API Integration**: Seamless connection to AI backend
- **Quote Management**: Save, explore, and discover quotes
- **Audio Features**: Text-to-speech functionality
- **User Profiles**: Personalized experience

### 🔧 Technical Stack
- **Backend**: Python Flask API server
- **Machine Learning**: Scikit-learn, TF-IDF, Random Forest
- **iOS**: SwiftUI, Combine, AVFoundation
- **Data Processing**: Pandas, NumPy
- **Model Persistence**: Pickle serialization

## 📁 Project Structure

```
WiseAI/
├── 📱 iOS App
│   ├── WiseAI/ - Main iOS application
│   ├── WiseAITests/ - Unit tests
│   └── WiseAIUITests/ - UI tests
├── 🤖 AI Backend
│   ├── simple_training.py - Simple training pipeline
│   ├── train_quote_system.py - Full training system
│   ├── trained_api_server.py - Flask API server
│   └── models/ - Trained models and metadata
├── 📊 Data
│   ├── raw/ - Original quote datasets
│   ├── processed/ - Processed and cleaned data
│   └── embeddings/ - Vector embeddings
└── 📚 Documentation
    ├── PROJECT_SUMMARY.md - Detailed project overview
    └── PROBLEM_SOLUTION_SYSTEM_SUMMARY.md - System architecture
```

## 🛠️ Setup & Installation

### Prerequisites
- Python 3.8+
- Xcode 12+ (for iOS development)
- iOS 14+ (for app deployment)

### Backend Setup
```bash
# Clone the repository
git clone https://github.com/bakr1233/Everyone_can_code.git
cd Everyone_can_code

# Install Python dependencies
pip install flask scikit-learn pandas numpy

# Run the API server
python trained_api_server.py
```

### iOS App Setup
1. Open `WiseAI.xcodeproj` in Xcode
2. Select your development team
3. Build and run on iOS device or simulator

## 🎯 Usage

### API Endpoints
- `GET /api/quotes/emotion/<emotion>` - Get quotes by emotion
- `GET /api/quotes/problem/<problem>` - Get quotes by problem type
- `GET /api/quotes/random` - Get random quote recommendations
- `GET /api/health` - Check API health status

### Example API Calls
```bash
# Get grief-related quotes
curl http://localhost:5008/api/quotes/emotion/grief

# Get quotes for anxiety problems
curl http://localhost:5008/api/quotes/problem/anxiety

# Get random recommendations
curl http://localhost:5008/api/quotes/random
```

### iOS App Features
- **Explore**: Discover quotes by emotion or problem
- **Save**: Bookmark your favorite quotes
- **Audio**: Listen to quotes with text-to-speech
- **Profile**: Manage your preferences and saved quotes

## 📊 Model Performance

### Simple Training System
- **Accuracy**: 70%+ on emotion classification
- **Training Time**: ~5-10 minutes
- **Dataset**: 491,914 quotes from philosophers and thinkers
- **Features**: 5,000 TF-IDF features

### Full Training System
- **Additional Features**: Problem classification, quote clustering
- **Training Time**: ~2 hours
- **Advanced Analytics**: Multi-dimensional quote analysis

## 🔍 Data Sources

The system includes quotes from:
- **Ancient Philosophers**: Aristotle, Plato, Socrates
- **Modern Thinkers**: Nietzsche, Kant, Schopenhauer
- **Contemporary Authors**: Various wisdom literature
- **Stoic Philosophy**: Marcus Aurelius, Epictetus, Seneca

## 🚀 Quick Start

1. **Start the API Server**:
   ```bash
   python trained_api_server.py
   ```

2. **Open iOS App**:
   - Launch Xcode
   - Open `WiseAI.xcodeproj`
   - Build and run

3. **Test the System**:
   ```bash
   python test_simple_training.py
   python test_multiple_emotions.py
   ```

## 📈 Performance Monitoring

The system includes comprehensive testing scripts:
- `test_simple_training.py` - Test model accuracy
- `test_multiple_emotions.py` - Test multiple emotion categories
- `test_ios_integration.py` - Test iOS app integration
- `status_check.py` - Monitor API server health

## 🔧 Configuration

### API Server Settings
- **Port**: 5008 (configurable in `trained_api_server.py`)
- **Quote Length Limit**: 50 words maximum
- **Model Path**: `models/` directory

### iOS App Settings
- **API Base URL**: `http://localhost:5008` (configurable in `APIService.swift`)
- **Quote Display**: Optimized for mobile viewing
- **Audio Settings**: Configurable speech rate and voice

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Philosophical quotes from various thinkers and authors
- Scikit-learn community for machine learning tools
- SwiftUI community for iOS development resources

## 📞 Support

For questions or issues:
1. Check the documentation in `PROJECT_SUMMARY.md`
2. Review the system architecture in `PROBLEM_SOLUTION_SYSTEM_SUMMARY.md`
3. Open an issue on GitHub

---

**WiseAI** - Bringing wisdom to your fingertips through intelligent quote recommendations.
