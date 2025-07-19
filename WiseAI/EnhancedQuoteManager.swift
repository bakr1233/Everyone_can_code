//
//  EnhancedQuoteManager.swift
//  WiseAI
//
//  Created by Bakr Bouhaya on 7/17/25.
//

import Foundation
import SwiftUI
import Speech
import Combine

struct EnhancedQuote: Codable, Identifiable {
    let id = UUID()
    let text: String
    let author: String
    let emotion: String
    let cluster: Int
    let similarityScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case text, author, emotion, cluster, similarityScore
    }
}

struct EmotionResult: Codable {
    let emotion: String
    let confidence: Double
    let quoteCategories: [String]
    
    enum CodingKeys: String, CodingKey {
        case emotion, confidence, quoteCategories
    }
}

struct EnhancedQuoteResponse: Codable {
    let inputText: String
    let emotion: EmotionResult
    let insight: String
    let recommendedQuotes: [EnhancedQuote]
    let processingMethod: String
    
    enum CodingKeys: String, CodingKey {
        case inputText, emotion, insight, recommendedQuotes, processingMethod
    }
}

struct EnhancedQuoteDatabase: Codable {
    let quotes: [EnhancedQuote]
    let emotionCategories: [String]
    let totalQuotes: Int
    let modelType: String
    let features: [String]
}

class EnhancedQuoteManager: ObservableObject {
    @Published var quotes: [EnhancedQuote] = []
    @Published var emotionCategories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isProcessingAudio = false
    @Published var transcriptionText = ""
    
    private var quoteDatabase: EnhancedQuoteDatabase?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Enhanced emotion mapping
    private var emotionToQuoteCategories: [String: [String]] = [
        "sadness": ["hope", "comfort", "wisdom"],
        "joy": ["gratitude", "love", "motivation"],
        "anger": ["wisdom", "courage", "growth"],
        "fear": ["courage", "hope", "comfort"],
        "surprise": ["wisdom", "growth", "motivation"],
        "disgust": ["wisdom", "growth", "courage"],
        "neutral": ["general", "wisdom", "motivation"]
    ]
    
    init() {
        loadQuotes()
        setupSpeechRecognition()
    }
    
    func loadQuotes() {
        isLoading = true
        errorMessage = nil
        
        // First try to load from the enhanced JSON file
        if let url = Bundle.main.url(forResource: "quotes_ios_enhanced", withExtension: "json") {
            loadQuotesFromURL(url)
        } else if let url = Bundle.main.url(forResource: "quotes_ios", withExtension: "json") {
            // Fallback to regular quotes file
            loadQuotesFromURL(url)
        } else {
            // Fallback to sample quotes
            loadSampleQuotes()
        }
    }
    
    private func loadQuotesFromURL(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            quoteDatabase = try decoder.decode(EnhancedQuoteDatabase.self, from: data)
            
            DispatchQueue.main.async {
                self.quotes = self.quoteDatabase?.quotes ?? []
                self.emotionCategories = self.quoteDatabase?.emotionCategories ?? []
                self.isLoading = false
                print("Loaded \(self.quotes.count) enhanced quotes")
                print("Model type: \(self.quoteDatabase?.modelType ?? "basic")")
                print("Features: \(self.quoteDatabase?.features ?? [])")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load quotes: \(error.localizedDescription)"
                self.isLoading = false
                self.loadSampleQuotes()
            }
        }
    }
    
    private func loadSampleQuotes() {
        // Enhanced sample quotes with similarity scores
        let sampleQuotes = [
            EnhancedQuote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", emotion: "motivation", cluster: 0, similarityScore: 0.95),
            EnhancedQuote(text: "When we are no longer able to change a situation, we are challenged to change ourselves.", author: "Viktor E. Frankl", emotion: "growth", cluster: 1, similarityScore: 0.92),
            EnhancedQuote(text: "The human spirit is stronger than anything that can happen to it.", author: "C.C. Scott", emotion: "courage", cluster: 2, similarityScore: 0.89),
            EnhancedQuote(text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis", emotion: "hope", cluster: 3, similarityScore: 0.87),
            EnhancedQuote(text: "The wound is the place where the Light enters you.", author: "Rumi", emotion: "wisdom", cluster: 4, similarityScore: 0.85)
        ]
        
        DispatchQueue.main.async {
            self.quotes = sampleQuotes
            self.emotionCategories = Array(self.emotionToQuoteCategories.keys)
            self.isLoading = false
            print("Loaded \(sampleQuotes.count) sample enhanced quotes")
        }
    }
    
    // MARK: - Speech Recognition Setup
    
    private func setupSpeechRecognition() {
        speechRecognizer?.delegate = nil
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition denied")
                case .restricted:
                    print("Speech recognition restricted")
                case .notDetermined:
                    print("Speech recognition not determined")
                @unknown default:
                    print("Speech recognition unknown status")
                }
            }
        }
    }
    
    // MARK: - Audio Processing
    
    func startAudioRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognition not available")
            return
        }
        
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
            return
        }
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcriptionText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil {
                self.stopAudioRecording()
            }
        }
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isProcessingAudio = true
            }
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopAudioRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        DispatchQueue.main.async {
            self.isProcessingAudio = false
        }
    }
    
    // MARK: - Enhanced Quote Recommendation Methods
    
    func getEnhancedRecommendations(for input: String) -> EnhancedQuoteResponse {
        // Simulate enhanced NLP processing
        let emotion = detectEmotion(from: input)
        let insight = generateInsight(for: input, emotion: emotion.emotion)
        let recommendedQuotes = getQuotesForEmotion(emotion.emotion, count: 5)
        
        return EnhancedQuoteResponse(
            inputText: input,
            emotion: emotion,
            insight: insight,
            recommendedQuotes: recommendedQuotes,
            processingMethod: "enhanced_nlp"
        )
    }
    
    func getEnhancedRecommendationsFromAudio() -> EnhancedQuoteResponse? {
        guard !transcriptionText.isEmpty else { return nil }
        return getEnhancedRecommendations(for: transcriptionText)
    }
    
    private func detectEmotion(from text: String) -> EmotionResult {
        let textLower = text.lowercased()
        
        // Simple emotion detection based on keywords
        let emotionKeywords = [
            "sadness": ["sad", "depressed", "lonely", "hopeless", "miserable", "grief", "sorrow"],
            "joy": ["happy", "joy", "excited", "thrilled", "elated", "ecstatic", "delighted"],
            "anger": ["angry", "furious", "mad", "irritated", "frustrated", "rage", "hate"],
            "fear": ["scared", "afraid", "terrified", "anxious", "worried", "nervous", "panic"],
            "surprise": ["surprised", "shocked", "amazed", "astonished", "stunned", "wow"],
            "disgust": ["disgusted", "revolted", "sick", "nauseated", "repulsed"]
        ]
        
        var maxScore = 0.0
        var detectedEmotion = "neutral"
        var confidence = 0.0
        
        for (emotion, keywords) in emotionKeywords {
            let score = keywords.reduce(0.0) { score, keyword in
                score + (textLower.contains(keyword) ? 1.0 : 0.0)
            }
            
            if score > maxScore {
                maxScore = score
                detectedEmotion = emotion
                confidence = min(score / Double(keywords.count), 1.0)
            }
        }
        
        let quoteCategories = emotionToQuoteCategories[detectedEmotion] ?? ["general"]
        
        return EmotionResult(
            emotion: detectedEmotion,
            confidence: confidence,
            quoteCategories: quoteCategories
        )
    }
    
    private func generateInsight(for text: String, emotion: String) -> String {
        let insightsByEmotion = [
            "sadness": [
                "I hear the weight of what you're carrying. It's completely normal to feel this way, and your feelings are valid. Remember, even the darkest nights end with sunrise.",
                "I can sense the heaviness in your words. You're not alone in feeling this way. Sometimes the bravest thing we can do is simply acknowledge our pain.",
                "Your feelings matter, and it's okay to not be okay right now. Every difficult moment is temporary, and you have more strength than you realize."
            ],
            "joy": [
                "Your positive energy is contagious! It's wonderful to see you in such a good place. Remember to savor these moments and share your light with others.",
                "Your happiness radiates through your words. These are the moments that make life beautiful and worth living.",
                "I can feel your joy and it's inspiring! Keep embracing these positive feelings and let them guide you forward."
            ],
            "anger": [
                "I understand that you're feeling frustrated and angry. These feelings are valid, and it's important to acknowledge them. Remember, anger often masks deeper emotions.",
                "Your anger is telling you something important about what matters to you. It's okay to feel this way, and it's also okay to take time to process these emotions.",
                "I hear the intensity in your words. Anger can be a powerful motivator for change, but it's also important to find healthy ways to express it."
            ],
            "fear": [
                "I can sense the anxiety and fear in your words. It's completely natural to feel this way when facing uncertainty. Remember, you're stronger than your fears.",
                "Your concerns are valid, and it's okay to feel afraid. Sometimes the bravest thing we can do is acknowledge our fears and take one small step forward.",
                "I understand that you're feeling scared and uncertain. These feelings are temporary, and you have the inner resources to navigate through this."
            ],
            "neutral": [
                "I appreciate you sharing your thoughts with me. Sometimes the most profound insights come from simply being present with our experiences.",
                "Thank you for opening up. Every perspective is valuable, and your thoughts matter.",
                "I hear what you're saying, and I'm here to support you. Sometimes the best wisdom comes from simply being heard."
            ]
        ]
        
        let emotionInsights = insightsByEmotion[emotion] ?? insightsByEmotion["neutral"]!
        return emotionInsights.randomElement() ?? (emotionInsights.isEmpty ? "I understand what you're going through." : emotionInsights[0])
    }
    
    private func getQuotesForEmotion(_ emotion: String, count: Int) -> [EnhancedQuote] {
        let emotionCategories = emotionToQuoteCategories[emotion] ?? ["general"]
        
        let filteredQuotes = quotes.filter { quote in
            emotionCategories.contains(quote.emotion)
        }
        
        if filteredQuotes.isEmpty {
            return Array(quotes.shuffled().prefix(count))
        }
        
        return Array(filteredQuotes.shuffled().prefix(count))
    }
    
    // MARK: - Utility Methods
    
    func getAvailableEmotions() -> [String] {
        return emotionCategories
    }
    
    func getQuoteCount() -> Int {
        return quotes.count
    }
    
    func searchQuotes(query: String) -> [EnhancedQuote] {
        let queryLower = query.lowercased()
        return quotes.filter { quote in
            quote.text.lowercased().contains(queryLower) ||
            quote.author.lowercased().contains(queryLower) ||
            quote.emotion.lowercased().contains(queryLower)
        }
    }
    
    func clearTranscription() {
        transcriptionText = ""
    }
    
    // MARK: - API Integration
    
    func getRecommendations(for text: String) -> AnyPublisher<APIRecommendationResponse, Error> {
        let apiService = APIService()
        return apiService.getRecommendations(for: text)
    }
} 