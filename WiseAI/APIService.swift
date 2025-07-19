//
//  APIService.swift
//  WiseAI
//
//  Created by WiseAI Team on 7/19/25.
//

import Foundation
import Combine

// MARK: - API Models

struct APIQuote: Codable {
    let text: String
    let author: String
    let emotion: String
    let similarityScore: Double?
    let matchType: String?
    let confidence: Double?
    let detectedEmotion: String?
    
    enum CodingKeys: String, CodingKey {
        case text, author, emotion
        case similarityScore = "similarity_score"
        case matchType = "match_type"
        case confidence
        case detectedEmotion = "detected_emotion"
    }
}

struct APIRecommendationResponse: Codable {
    let status: String
    let inputText: String
    let insight: String
    let recommendedQuotes: [APIQuote]
    let emotionDetected: String
    let confidence: Double?
    let emotionProbabilities: [String: Double]?
    let processingMethod: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case status, insight, timestamp, confidence
        case inputText = "input_text"
        case recommendedQuotes = "recommended_quotes"
        case emotionDetected = "emotion_detected"
        case emotionProbabilities = "emotion_probabilities"
        case processingMethod = "processing_method"
    }
}

struct APIHealthResponse: Codable {
    let status: String
    let engineLoaded: Bool
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case status, timestamp
        case engineLoaded = "engine_loaded"
    }
}

// MARK: - API Service

class APIService: ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:5008"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkConnection()
    }
    
    // MARK: - Connection Check
    
    func checkConnection() {
        guard let url = URL(string: "\(baseURL)/health") else {
            DispatchQueue.main.async {
                self.isConnected = false
                self.errorMessage = "Invalid URL"
            }
            return
        }
        
        print("🔍 Checking API connection to: \(url)")
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: APIHealthResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.isConnected = false
                        self.errorMessage = "Connection failed: \(error.localizedDescription)"
                        print("❌ API Connection failed: \(error)")
                        print("🔍 URL attempted: \(url)")
                    }
                },
                receiveValue: { response in
                    self.isConnected = response.engineLoaded
                    self.errorMessage = nil
                    print("✅ API Connected: \(response.status)")
                    print("🔍 Engine loaded: \(response.engineLoaded)")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Get Recommendations
    
    func getRecommendations(for text: String) -> AnyPublisher<APIRecommendationResponse, Error> {
        guard let url = URL(string: "\(baseURL)/recommendations") else {
            print("❌ Invalid URL for recommendations")
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["text": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🎯 Sending recommendation request to: \(url)")
        print("📝 Text: \(text)")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: APIRecommendationResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { response in
                    print("✅ Received \(response.recommendedQuotes.count) recommendations")
                    print("💡 Insight: \(response.insight)")
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Recommendation request completed successfully")
                    case .failure(let error):
                        print("❌ Recommendation request failed: \(error)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get All Quotes
    
    func getAllQuotes() -> AnyPublisher<[APIQuote], Error> {
        guard let url = URL(string: "\(baseURL)/quotes") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap { data -> [APIQuote] in
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let quotesData = json?["quotes"] as? [[String: Any]] else {
                    throw URLError(.cannotParseResponse)
                }
                
                return try quotesData.compactMap { quoteDict in
                    // Handle the new structure without cluster field
                    var modifiedQuoteDict = quoteDict
                    // Remove cluster if it exists to avoid decoding errors
                    modifiedQuoteDict.removeValue(forKey: "cluster")
                    
                    let quoteData = try JSONSerialization.data(withJSONObject: modifiedQuoteDict)
                    return try JSONDecoder().decode(APIQuote.self, from: quoteData)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Search Quotes
    
    func searchQuotes(query: String) -> AnyPublisher<[APIQuote], Error> {
        guard let url = URL(string: "\(baseURL)/search") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .tryMap { data -> [APIQuote] in
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let resultsData = json?["results"] as? [[String: Any]] else {
                    throw URLError(.cannotParseResponse)
                }
                
                return try resultsData.compactMap { quoteDict in
                    let quoteData = try JSONSerialization.data(withJSONObject: quoteDict)
                    return try JSONDecoder().decode(APIQuote.self, from: quoteData)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Emotions
    
    func getEmotions() -> AnyPublisher<[String], Error> {
        guard let url = URL(string: "\(baseURL)/emotions") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap { data -> [String] in
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let emotions = json?["emotions"] as? [String] else {
                    throw URLError(.cannotParseResponse)
                }
                return emotions
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Enhanced Quote Manager with API Integration

class EnhancedQuoteManagerWithAPI: ObservableObject {
    @Published var quotes: [APIQuote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isConnected = false
    @Published var transcriptionText = ""
    
    private let apiService = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadQuotes()
    }
    
    private func setupBindings() {
        apiService.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
    }
    
    func loadQuotes() {
        isLoading = true
        errorMessage = nil
        
        apiService.getAllQuotes()
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            self.errorMessage = "Failed to load quotes: \(error.localizedDescription)"
                            print("❌ Failed to load quotes: \(error)")
                        }
                    }
                },
                receiveValue: { quotes in
                    DispatchQueue.main.async {
                        self.quotes = quotes
                        self.isLoading = false
                        print("✅ Loaded \(quotes.count) quotes from API")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func getRecommendations(for text: String) -> AnyPublisher<APIRecommendationResponse, Error> {
        return apiService.getRecommendations(for: text)
    }
    
    func searchQuotes(query: String) -> AnyPublisher<[APIQuote], Error> {
        return apiService.searchQuotes(query: query)
    }
    
    func getEmotions() -> AnyPublisher<[String], Error> {
        return apiService.getEmotions()
    }
    
    func refreshConnection() {
        apiService.checkConnection()
    }
} 