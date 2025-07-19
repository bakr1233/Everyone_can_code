import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoSaveEnabled") private var autoSaveEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 1, green: 0.97, blue: 0.89), Color(red: 0.85, green: 0.95, blue: 1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Settings List
                    VStack(spacing: 0) {
                        // Notifications
                        SettingsRow(
                            title: "Notifications",
                            subtitle: "Get notified about new quotes",
                            icon: "bell.fill",
                            iconColor: .blue
                        ) {
                            Toggle("", isOn: $notificationsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        // Dark Mode
                        SettingsRow(
                            title: "Dark Mode",
                            subtitle: "Use dark theme",
                            icon: "moon.fill",
                            iconColor: .purple
                        ) {
                            Toggle("", isOn: $darkModeEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                        }
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        // Auto Save
                        SettingsRow(
                            title: "Auto Save",
                            subtitle: "Automatically save favorite quotes",
                            icon: "heart.fill",
                            iconColor: .red
                        ) {
                            Toggle("", isOn: $autoSaveEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                        }
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        // Sound
                        SettingsRow(
                            title: "Sound Effects",
                            subtitle: "Play sounds for interactions",
                            icon: "speaker.wave.2.fill",
                            iconColor: .green
                        ) {
                            Toggle("", isOn: $soundEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                        }
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        // Haptic Feedback
                        SettingsRow(
                            title: "Haptic Feedback",
                            subtitle: "Vibrate on interactions",
                            icon: "iphone.radiowaves.left.and.right",
                            iconColor: .orange
                        ) {
                            Toggle("", isOn: $hapticFeedbackEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                        }
                    }
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // App Info
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("WiseAI")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 30) {
                            InfoButton(title: "Privacy", icon: "lock.fill") {
                                // Privacy action
                            }
                            
                            InfoButton(title: "Terms", icon: "doc.text.fill") {
                                // Terms action
                            }
                            
                            InfoButton(title: "Support", icon: "questionmark.circle.fill") {
                                // Support action
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, subtitle: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            content
        }
        .padding()
    }
}

struct InfoButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
        }
    }
}

#Preview {
    SettingsView()
} 