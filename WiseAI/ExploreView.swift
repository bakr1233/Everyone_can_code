import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingNotification = false
    @EnvironmentObject var savedItemsManager: SavedItemsManager
    
    let categories = ["All", "Motivation", "Love", "Success", "Happiness", "Wisdom"]
    
    let sampleQuotes = [
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Success"),
        Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon", category: "Life"),
        Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", category: "Motivation"),
        Quote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill", category: "Success"),
        Quote(text: "Happiness is not something ready made. It comes from your own actions.", author: "Dalai Lama", category: "Happiness"),
        Quote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela", category: "Motivation")
    ]
    
    var filteredQuotes: [Quote] {
        let categoryFiltered = selectedCategory == "All" ? sampleQuotes : sampleQuotes.filter { $0.category == selectedCategory }
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { $0.text.localizedCaseInsensitiveContains(searchText) || $0.author.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 1, green: 0.97, blue: 0.89), Color(red: 0.85, green: 0.95, blue: 1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Explore Quotes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search quotes...", text: $searchText)
                        .foregroundColor(.black)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedCategory == category ? .white : .black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCategory == category ? Color.blue : Color.white.opacity(0.9)
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Quotes List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredQuotes, id: \.text) { quote in
                            QuoteCard(quote: quote) {
                                savedItemsManager.saveQuote(quote)
                                showingNotification = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .overlay(
            // Notification
            Group {
                if showingNotification {
                    VStack {
                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.blue)
                            Text("Quote saved!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingNotification = false
                            }
                        }
                    }
                }
            }
        )
    }
}

struct QuoteCard: View {
    let quote: Quote
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(quote.text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text("- \(quote.author)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: onSave) {
                    Image(systemName: "bookmark")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct Quote {
    let text: String
    let author: String
    let category: String
}

#Preview {
    ExploreView()
} 