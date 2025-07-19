import SwiftUI
import AVFoundation

struct SavedQuotesView: View {
    @EnvironmentObject var savedItemsManager: SavedItemsManager
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: SavedItem?
    @State private var showingNotification = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playingItemId: UUID?
    
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
                    Text("Saved Items")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    
                    Text("\(savedItemsManager.savedItems.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                }
                .padding()
                
                if savedItemsManager.savedItems.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No saved items yet")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        Text("Start exploring and save your favorite quotes and recordings!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Items List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(savedItemsManager.savedItems) { item in
                                SavedItemCard(
                                    item: item,
                                    isPlaying: isPlaying && playingItemId == item.id,
                                    onDelete: {
                                        itemToDelete = item
                                        showingDeleteAlert = true
                                    },
                                    onPlayAudio: {
                                        if item.type == .audio {
                                            playAudio(for: item)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    deleteItem(item)
                }
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
                .foregroundColor(.black)
        }
        .overlay(
            // Notification
            Group {
                if showingNotification {
                    VStack {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Item deleted!")
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
    
    private func deleteItem(_ item: SavedItem) {
        withAnimation {
            savedItemsManager.deleteSavedItem(item)
            showingNotification = true
        }
    }
    
    private func playAudio(for item: SavedItem) {
        guard let audioURL = item.audioURL else { return }
        
        if isPlaying && playingItemId == item.id {
            // Stop playing
            audioPlayer?.stop()
            isPlaying = false
            playingItemId = nil
        } else {
            // Start playing
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.delegate = nil // We'll handle completion manually
                audioPlayer?.play()
                isPlaying = true
                playingItemId = item.id
                
                // Set up completion handler
                DispatchQueue.main.asyncAfter(deadline: .now() + audioPlayer!.duration) {
                    if self.playingItemId == item.id {
                        self.isPlaying = false
                        self.playingItemId = nil
                    }
                }
            } catch {
                print("Error playing audio: \(error)")
            }
        }
    }
}

struct SavedItemCard: View {
    let item: SavedItem
    let isPlaying: Bool
    let onDelete: () -> Void
    let onPlayAudio: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item Type Indicator
            HStack {
                Image(systemName: item.type == .quote ? "quote.bubble" : "mic.fill")
                    .foregroundColor(item.type == .quote ? .blue : .purple)
                    .font(.caption)
                
                Text(item.type == .quote ? "Quote" : "Audio Recording")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(item.type == .quote ? .blue : .purple)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            // Content
            Text(item.content)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let author = item.author {
                        Text("- \(author)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                    
                    Text(formatDate(item.date))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Audio Play Button (only for audio items)
                if item.type == .audio {
                    Button(action: onPlayAudio) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Audio Player Delegate
// Using the AudioPlayerDelegate from AudioView.swift

#Preview {
    SavedQuotesView()
} 