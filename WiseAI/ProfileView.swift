import SwiftUI

struct ProfileView: View {
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 1, green: 0.97, blue: 0.89), Color(red: 0.85, green: 0.95, blue: 1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Name and Settings Button
                HStack {
                    Text("QuoteMe")
                        .font(.headline)
                        .padding(8)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(12)
                        .padding(.leading)
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(12)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 16)
                
                // Profile Card
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 90))
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(radius: 4)

                    Text("Spencer James (He/Him/His)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Personal Goal:")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("I want to create boldly, love deeply, and be present within my life—art and connection are my spark.")
                            .italic()
                            .foregroundColor(.black)
                    }
                    .font(.body)
                    .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.white.opacity(0.85))
                .cornerRadius(20)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Stats Row
                HStack(spacing: 16) {
                    StatButton(icon: "heart.fill", label: "32 Saved")
                    StatButton(icon: "calendar", label: "1 Day Active")
                    StatButton(icon: "smiley", label: "1.8/5 for Average Mood")
                }
                .padding(.horizontal)
                
                // Menu List
                VStack(spacing: 0) {
                    MenuRow(title: "Mood Check-In")
                    Divider()
                    MenuRow(title: "Coaching")
                    Divider()
                    MenuRow(title: "Themes")
                    Divider()
                    MenuRow(title: "Manage Data")
                }
                .background(Color.white.opacity(0.85))
                .cornerRadius(20)
                .padding(.horizontal)

                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}

struct StatButton: View {
    let icon: String
    let label: String
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.gray)
            Text(label)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
    }
}

struct MenuRow: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} 