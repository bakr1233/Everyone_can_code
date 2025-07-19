import Foundation

struct SavedItem: Identifiable, Codable {
    let id: UUID
    let type: SavedItemType
    let content: String
    let author: String?
    let date: Date
    let audioURL: URL?
    let category: String?
    
    enum SavedItemType: String, Codable {
        case quote = "quote"
        case audio = "audio"
    }
    
    init(type: SavedItemType, content: String, author: String? = nil, audioURL: URL? = nil, category: String? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.author = author
        self.date = Date()
        self.audioURL = audioURL
        self.category = category
    }
}

// MARK: - Saved Items Manager
class SavedItemsManager: ObservableObject {
    @Published var savedItems: [SavedItem] = []
    private let userDefaults = UserDefaults.standard
    private let savedItemsKey = "SavedItems"
    
    init() {
        loadSavedItems()
    }
    
    func saveQuote(_ quote: Quote) {
        let savedItem = SavedItem(
            type: .quote,
            content: quote.text,
            author: quote.author,
            category: quote.category
        )
        addSavedItem(savedItem)
    }
    
    func saveAudioRecording(_ text: String, audioURL: URL) {
        let savedItem = SavedItem(
            type: .audio,
            content: text,
            audioURL: audioURL
        )
        addSavedItem(savedItem)
    }
    
    private func addSavedItem(_ item: SavedItem) {
        DispatchQueue.main.async {
            self.savedItems.insert(item, at: 0) // Add to beginning
            self.saveToUserDefaults()
        }
    }
    
    func deleteSavedItem(_ item: SavedItem) {
        DispatchQueue.main.async {
            self.savedItems.removeAll { $0.id == item.id }
            self.saveToUserDefaults()
        }
    }
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(savedItems) {
            userDefaults.set(encoded, forKey: savedItemsKey)
        }
    }
    
    private func loadSavedItems() {
        if let data = userDefaults.data(forKey: savedItemsKey),
           let decoded = try? JSONDecoder().decode([SavedItem].self, from: data) {
            savedItems = decoded
        }
    }
} 