//
//  QuoteManager.swift
//  WiseAI
//
//  Created by Bakr Bouhaya on 7/17/25.
//

import Foundation
import SwiftUI

struct BasicQuote: Codable, Identifiable {
    let id = UUID()
    let text: String
    let author: String
    let emotion: String
    let cluster: Int
    
    enum CodingKeys: String, CodingKey {
        case text, author, emotion, cluster
    }
}

struct BasicQuoteDatabase: Codable {
    let quotes: [BasicQuote]
    let emotionCategories: [String]
    let totalQuotes: Int
}

class QuoteManager: ObservableObject {
    @Published var quotes: [BasicQuote] = []
    @Published var emotionCategories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var quoteDatabase: BasicQuoteDatabase?
    private var emotionKeywords: [String: [String]] = [
        "motivation": ["motivation", "inspire", "success", "achieve", "goal", "dream", "ambition", "drive"],
        "hope": ["hope", "faith", "believe", "trust", "optimism", "positive", "future", "better"],
        "courage": ["courage", "brave", "strength", "fear", "overcome", "challenge", "difficult", "adversity"],
        "love": ["love", "heart", "care", "compassion", "kindness", "relationship", "family", "friend"],
        "wisdom": ["wisdom", "learn", "knowledge", "experience", "understand", "truth", "life", "philosophy"],
        "perseverance": ["perseverance", "persist", "endure", "continue", "never", "give", "up", "resilience"],
        "gratitude": ["gratitude", "thankful", "blessed", "appreciate", "grateful", "blessing", "joy"],
        "growth": ["growth", "change", "evolve", "improve", "better", "progress", "develop", "transform"]
    ]
    
    init() {
        loadQuotes()
    }
    
    func loadQuotes() {
        isLoading = true
        errorMessage = nil
        
        // First try to load from the bundled JSON file
        if let url = Bundle.main.url(forResource: "quotes_ios", withExtension: "json") {
            loadQuotesFromURL(url)
        } else {
            // Fallback to sample quotes if no JSON file is found
            loadSampleQuotes()
        }
    }
    
    private func loadQuotesFromURL(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            quoteDatabase = try decoder.decode(BasicQuoteDatabase.self, from: data)
            
            DispatchQueue.main.async {
                self.quotes = self.quoteDatabase?.quotes ?? []
                self.emotionCategories = self.quoteDatabase?.emotionCategories ?? []
                self.isLoading = false
                print("Loaded \(self.quotes.count) quotes from database")
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
        // Fallback sample quotes if the JSON file is not available
        let sampleQuotes = [
            BasicQuote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", emotion: "motivation", cluster: 0),
            BasicQuote(text: "When we are no longer able to change a situation, we are challenged to change ourselves.", author: "Viktor E. Frankl", emotion: "growth", cluster: 1),
            BasicQuote(text: "The human spirit is stronger than anything that can happen to it.", author: "C.C. Scott", emotion: "courage", cluster: 2),
            BasicQuote(text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis", emotion: "hope", cluster: 3),
            BasicQuote(text: "The wound is the place where the Light enters you.", author: "Rumi", emotion: "wisdom", cluster: 4),
            BasicQuote(text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", author: "Ralph Waldo Emerson", emotion: "courage", cluster: 5),
            BasicQuote(text: "The only impossible journey is the one you never begin.", author: "Tony Robbins", emotion: "motivation", cluster: 6),
            BasicQuote(text: "Every day is a new beginning. Take a deep breath and start again.", author: "Anonymous", emotion: "hope", cluster: 7),
            BasicQuote(text: "You have power over your mind - not outside events. Realize this, and you will find strength.", author: "Marcus Aurelius", emotion: "wisdom", cluster: 8),
            BasicQuote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela", emotion: "perseverance", cluster: 9)
        ]
        
        DispatchQueue.main.async {
            self.quotes = sampleQuotes
            self.emotionCategories = Array(self.emotionKeywords.keys)
            self.isLoading = false
            print("Loaded \(sampleQuotes.count) sample quotes")
        }
    }
    
    // MARK: - Quote Recommendation Methods
    
    func getRandomQuote() -> BasicQuote? {
        return quotes.randomElement()
    }
    
    func getQuoteByEmotion(_ emotion: String) -> BasicQuote? {
        let filteredQuotes = quotes.filter { $0.emotion.lowercased() == emotion.lowercased() }
        return filteredQuotes.randomElement() ?? getRandomQuote()
    }
    
    func getQuotesByEmotion(_ emotion: String, count: Int = 5) -> [BasicQuote] {
        let filteredQuotes = quotes.filter { $0.emotion.lowercased() == emotion.lowercased() }
        let shuffled = filteredQuotes.shuffled()
        return Array(shuffled.prefix(count))
    }
    
    func getQuoteForContext(_ context: String) -> BasicQuote? {
        let contextLower = context.lowercased()
        
        // Find the best matching emotion based on keywords
        var bestEmotion = "general"
        var maxScore = 0
        
        for (emotion, keywords) in emotionKeywords {
            let score = keywords.reduce(0) { score, keyword in
                score + (contextLower.contains(keyword) ? 1 : 0)
            }
            if score > maxScore {
                maxScore = score
                bestEmotion = emotion
            }
        }
        
        // Get a quote for the best matching emotion
        return getQuoteByEmotion(bestEmotion)
    }
    
    func getQuotesForContext(_ context: String, count: Int = 3) -> [BasicQuote] {
        let contextLower = context.lowercased()
        
        // Score all quotes based on context relevance
        var scoredQuotes = quotes.map { quote -> (BasicQuote, Int) in
            let quoteText = quote.text.lowercased()
            let emotionKeywords = emotionKeywords[quote.emotion] ?? []
            
            var score = 0
            
            // Score based on emotion keywords in context
            for keyword in emotionKeywords {
                if contextLower.contains(keyword) {
                    score += 2
                }
            }
            
            // Score based on quote text relevance to context
            for keyword in emotionKeywords {
                if quoteText.contains(keyword) {
                    score += 1
                }
            }
            
            // Bonus for exact emotion match
            if contextLower.contains(quote.emotion) {
                score += 3
            }
            
            return (quote, score)
        }
        
        // Sort by score and return top quotes
        scoredQuotes.sort { $0.1 > $1.1 }
        return Array(scoredQuotes.prefix(count).map { $0.0 })
    }
    
    func getQuotesForMood(_ mood: String) -> [BasicQuote] {
        let moodLower = mood.lowercased()
        
        // Map common mood words to emotions
        let moodToEmotion: [String: String] = [
            "sad": "hope",
            "depressed": "hope",
            "anxious": "courage",
            "scared": "courage",
            "stressed": "wisdom",
            "overwhelmed": "wisdom",
            "tired": "motivation",
            "lazy": "motivation",
            "lonely": "love",
            "grateful": "gratitude",
            "thankful": "gratitude",
            "stuck": "growth",
            "lost": "hope",
            "confused": "wisdom",
            "angry": "wisdom",
            "frustrated": "perseverance"
        ]
        
        let targetEmotion = moodToEmotion[moodLower] ?? "general"
        return getQuotesByEmotion(targetEmotion, count: 5)
    }
    
    // MARK: - Advanced Recommendation Methods
    
    func getPersonalizedQuote(for userInput: String, userMood: String? = nil) -> BasicQuote? {
        var context = userInput
        
        if let mood = userMood {
            context += " " + mood
        }
        
        // Get context-based quotes
        let contextQuotes = getQuotesForContext(context, count: 5)
        
        if !contextQuotes.isEmpty {
            return contextQuotes.randomElement()
        }
        
        // Fallback to mood-based quotes
        if let mood = userMood {
            let moodQuotes = getQuotesForMood(mood)
            if !moodQuotes.isEmpty {
                return moodQuotes.randomElement()
            }
        }
        
        // Final fallback to random quote
        return getRandomQuote()
    }
    
    func getQuoteSet(for situation: String) -> (insight: String, quote: BasicQuote?) {
        // Generate contextual insight
        let insight = generateInsight(for: situation)
        
        // Get appropriate quote
        let quote = getPersonalizedQuote(for: situation)
        
        return (insight, quote)
    }
    
    private func generateInsight(for situation: String) -> String {
        let situationLower = situation.lowercased()
        
        let insights = [
            "I hear that you're going through a challenging time. It's completely normal to feel overwhelmed, and your feelings are valid. Remember, every difficult moment is temporary, and you have the strength within you to overcome this.",
            "It sounds like you're dealing with some heavy emotions right now. That takes courage to acknowledge. You're not alone in this journey, and there are people who care about you and want to support you.",
            "I can sense the weight of what you're carrying. It's okay to not have all the answers right now. Sometimes the bravest thing we can do is simply take one step forward, even when the path ahead seems unclear.",
            "Your feelings are important and deserve to be heard. It's okay to take time to process what you're experiencing. Remember that growth often comes from the most challenging moments in life.",
            "I understand that this situation feels difficult right now. You're showing incredible strength by facing it head-on. Every step you take, no matter how small, is progress worth celebrating."
        ]
        
        // Choose insight based on keywords in the situation
        if situationLower.contains("overwhelm") || situationLower.contains("stress") {
            return insights.isEmpty ? "I understand what you're going through." : insights[0]
        } else if situationLower.contains("sad") || situationLower.contains("depress") {
            return insights.count > 1 ? insights[1] : (insights.isEmpty ? "I understand what you're going through." : insights[0])
        } else if situationLower.contains("fear") || situationLower.contains("scared") {
            return insights.count > 2 ? insights[2] : (insights.isEmpty ? "I understand what you're going through." : insights[0])
        } else if situationLower.contains("confus") || situationLower.contains("lost") {
            return insights.count > 3 ? insights[3] : (insights.isEmpty ? "I understand what you're going through." : insights[0])
        } else {
            return insights.randomElement() ?? (insights.isEmpty ? "I understand what you're going through." : insights[0])
        }
    }
    
    // MARK: - Utility Methods
    
    func getAvailableEmotions() -> [String] {
        return emotionCategories
    }
    
    func getQuoteCount() -> Int {
        return quotes.count
    }
    
    func searchQuotes(query: String) -> [BasicQuote] {
        let queryLower = query.lowercased()
        return quotes.filter { quote in
            quote.text.lowercased().contains(queryLower) ||
            quote.author.lowercased().contains(queryLower) ||
            quote.emotion.lowercased().contains(queryLower)
        }
    }
} 