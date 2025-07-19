//
//  ContentView.swift
//  WiseAI
//
//  Created by 33GOParticipant on 7/18/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var savedItemsManager = SavedItemsManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .environmentObject(savedItemsManager)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .tag(0)
            
            SavedQuotesView()
                .environmentObject(savedItemsManager)
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Saved")
                }
                .tag(1)
            
            AudioView()
                .environmentObject(savedItemsManager)
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("Voice")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
