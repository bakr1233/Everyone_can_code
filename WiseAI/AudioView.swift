import SwiftUI
import AVFoundation
import Combine
import Speech

struct AudioView: View {
    @StateObject private var enhancedQuoteManager = EnhancedQuoteManagerWithAPI()
    @EnvironmentObject var savedItemsManager: SavedItemsManager
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recordingURL: URL?
    @State private var showingPermissionAlert = false
    @State private var showingRecordingMessage = false
    @State private var recordingMessage = ""
    @State private var isAnalyzing = false
    @State private var aiAnalysisComplete = false
    @State private var motivationalQuote = ""
    @State private var quoteAuthor = ""
    @State private var aiInsight = ""
    @State private var recommendedQuotes: [APIQuote] = []
    @State private var selectedQuoteIndex = 0
    @State private var cancellables = Set<AnyCancellable>()
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @StateObject private var audioDelegate = AudioPlayerDelegate()
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var transcribedText = ""
    @State private var showingSaveNotification = false
    
    private var buttonBackgroundColor: Color {
        if isRecording {
            return .red
        } else if isPlaying {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var buttonIconName: String {
        if isRecording || isPlaying {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private var buttonText: String {
        if isRecording {
            return "Stop Recording"
        } else if isPlaying {
            return "Stop Playback"
        } else {
            return "Start Recording"
        }
    }
    
    private var statusText: String {
        if isRecording {
            return "Recording..."
        } else if isPlaying {
            return "Playing..."
        } else if isAnalyzing {
            return "Analyzing your thoughts..."
        } else {
            return "Tap to start recording"
        }
    }
    
    private var statusColor: Color {
        if isRecording {
            return .red
        } else if isPlaying {
            return .blue
        } else if isAnalyzing {
            return .purple
        } else {
            return .black
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1, green: 0.97, blue: 0.89),
                Color(red: 0.85, green: 0.95, blue: 1)
            ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
    }
            
    private var headerView: some View {
                VStack(spacing: 8) {
                    Text("Tell me, I'm with you.")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    // API Connection Status
                    HStack(spacing: 6) {
                        Circle()
                    .fill(enhancedQuoteManager.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                Text(enhancedQuoteManager.isConnected ? "AI Connected" : "AI Disconnected")
                            .font(.caption)
                    .foregroundColor(enhancedQuoteManager.isConnected ? Color.green : Color.red)
                    }
                }
                .padding(.top, 20)
    }
                
    private var animationView: some View {
        Group {
                if isRecording {
                    VoiceAnimationView()
                        .frame(width: 120, height: 120)
                } else if isPlaying {
                    PlaybackAnimationView()
                        .frame(width: 120, height: 120)
                } else {
                    // Static microphone icon when not recording or playing
                    Image(systemName: "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .frame(width: 120, height: 120)
            }
        }
                }
                
    private var statusTextView: some View {
        Group {
                if isRecording {
                    VStack(spacing: 4) {
                        Text(statusText)
                            .font(.headline)
                            .foregroundColor(statusColor)
                            .fontWeight(.medium)
                        
                        Text(formatDuration(recordingDuration))
                            .font(.caption)
                            .foregroundColor(statusColor)
                            .fontWeight(.medium)
                    }
                } else {
                    Text(statusText)
                        .font(.headline)
                        .foregroundColor(statusColor)
                        .fontWeight(.medium)
            }
        }
                }
                
    private var recordingButton: some View {
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else if isPlaying {
                        stopPlayback()
                    } else {
                        startRecording()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: buttonIconName)
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(buttonText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(buttonBackgroundColor)
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
                .disabled(isAnalyzing)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 30) {
                headerView
                
                Spacer()
                
                animationView
                
                statusTextView
                
                recordingButton
                
                // Message Area (appears after recording stops)
                if showingRecordingMessage {
                    messageAreaView
                }
                
                Spacer()
            }
        }
        .onAppear {
            setupAudioSession()
        }
        .onReceive(audioDelegate.$isPlaying) { playing in
            isPlaying = playing
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings", role: .none) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to record audio.")
                .foregroundColor(.black)
        }
        .overlay(
            // Save Notification
            Group {
                if showingSaveNotification {
                    VStack {
                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(.blue)
                            Text("Recording saved!")
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
                                showingSaveNotification = false
                            }
                        }
                    }
                }
            }
        )
    }
    
    private var messageAreaView: some View {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "message.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text("Your Recording")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Spacer()
                            }
                            
                            Text(recordingMessage)
                                .font(.body)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    playRecording()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                            .font(.title3)
                                        Text("Play")
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                                }
                                
                                Button(action: {
                                    saveRecording()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bookmark")
                                            .font(.title3)
                                        Text("Save")
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                                }
                                
                                Button(action: {
                                    deleteRecording()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash")
                                            .font(.title3)
                                        Text("Delete")
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.red)
                                    .cornerRadius(20)
                                }
                            }
                            
                            // AI Analysis Button
                            if !aiAnalysisComplete {
                                Button(action: {
                                    startAIAnalysis()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "brain.head.profile")
                                            .font(.title3)
                                        Text("Get AI Support & Motivation")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 25)
                                    .padding(.vertical, 12)
                        .background(Color.purple)
                                    .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                }
                            }
                            
                            // AI Analysis Results
                            if aiAnalysisComplete {
                                VStack(spacing: 16) {
                        // AI Insight
                        if !aiInsight.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.title3)
                                        .foregroundColor(.yellow)
                                        
                                    Text("AI Insight")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                    }
                                            
                                            Text(aiInsight)
                                                .font(.body)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading)
                                        .padding()
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(15)
                            }
                                    }
                                    
                        // Motivational Quote
                                    if !motivationalQuote.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "quote.bubble.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                    
                                    Text("Motivational Quote")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                                .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    // Quote Navigation
                                            if recommendedQuotes.count > 1 {
                                        HStack(spacing: 8) {
                                                    Button(action: previousQuote) {
                                                Image(systemName: "chevron.left")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    }
                                                    
                                            Text("\(selectedQuoteIndex + 1)/\(recommendedQuotes.count)")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                    
                                                    Button(action: nextQuote) {
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(motivationalQuote)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text("- \(quoteAuthor)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .italic()
                                    
                                    if selectedQuoteIndex < recommendedQuotes.count,
                                       let similarityScore = recommendedQuotes[selectedQuoteIndex].similarityScore {
                                                    HStack {
                                                        Text("Relevance:")
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                        
                                                        Text("\(Int(similarityScore * 100))%")
                                                            .font(.caption)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.purple)
                                                    }
                                                    .padding(.top, 4)
                                                }
                                            }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                                        }
                                    }
                                    
                                    // Feedback Button
                                    Button(action: {
                                        provideFeedback()
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "hand.thumbsup")
                                                .font(.title3)
                                            Text("This helped me")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.green)
                                        .cornerRadius(20)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                        }
                        .padding()
                    }
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
    // MARK: - Audio Functions
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    private func startRecording() {
        // Request microphone permission (iOS 17+)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.recordAudio()
                    } else {
                        self.showingPermissionAlert = true
                    }
                }
            }
        } else {
            // Fallback for older iOS versions
            let audioSession = AVAudioSession.sharedInstance()
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.recordAudio()
                    } else {
                        self.showingPermissionAlert = true
                    }
                }
            }
        }
    }
    
    private func recordAudio() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
        recordingURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,  // Higher sample rate for better quality
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000  // Higher bitrate for better quality
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = nil
            audioRecorder?.record()
            isRecording = true
            
            // Start recording timer
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                recordingDuration += 1
            }
            
            print("🎤 Started recording: \(audioFilename.lastPathComponent)")
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        // Stop recording timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        print("🎤 Stopped recording. Duration: \(formatDuration(recordingDuration))")
        
        // Transcribe the audio recording
        transcribeAudio()
        
        // Use transcribed text or fallback message
        if !transcribedText.isEmpty {
            recordingMessage = transcribedText
        } else {
            recordingMessage = "Your voice recording has been saved successfully. You can now play it back, share it with others, or get AI support to help you through your challenges."
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            showingRecordingMessage = true
        }
    }
    
    private func playRecording() {
        guard let url = recordingURL else {
            print("❌ No recording URL available for playback")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = audioDelegate
            audioPlayer?.play()
            isPlaying = true
            print("🎵 Started playback: \(url.lastPathComponent)")
        } catch {
            print("❌ Could not play recording: \(error)")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    private func saveRecording() {
        guard let audioURL = recordingURL else {
            print("❌ No recording URL available for saving")
            return
        }
        
        // Save the recording with transcribed text
        savedItemsManager.saveAudioRecording(recordingMessage, audioURL: audioURL)
        
        // Show save notification
        withAnimation {
            showingSaveNotification = true
        }
        
        print("💾 Saved recording: \(audioURL.lastPathComponent)")
    }
    
    private func deleteRecording() {
        // Simulate deletion
        withAnimation(.easeInOut(duration: 0.3)) {
            showingRecordingMessage = false
        }
        recordingMessage = ""
        recordingURL = nil
        aiAnalysisComplete = false
        motivationalQuote = ""
        quoteAuthor = ""
        aiInsight = ""
        recommendedQuotes = []
        selectedQuoteIndex = 0
    }
    
    private func provideFeedback() {
        // Simulate feedback submission
        withAnimation(.easeInOut(duration: 0.3)) {
            // Show feedback confirmation
        }
    }
    
    private func startAIAnalysis() {
        isAnalyzing = true
        
        // Simulate AI analysis with realistic processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.completeAIAnalysis()
        }
    }
    
    private func completeAIAnalysis() {
        isAnalyzing = false
        aiAnalysisComplete = true
        
        // Use the API service to get personalized insights and quotes
        enhancedQuoteManager.getRecommendations(for: recordingMessage)
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print("❌ API Error: \(error)")
                            // Fallback to random quote
                            if let randomQuote = enhancedQuoteManager.quotes.randomElement() {
                                self.motivationalQuote = randomQuote.text
                                self.quoteAuthor = randomQuote.author
                            } else {
                                self.motivationalQuote = "The only way to do great work is to love what you do."
                                self.quoteAuthor = "Steve Jobs"
                            }
                            self.aiInsight = "I understand what you're going through. Remember, every challenge is an opportunity for growth."
                        }
                    }
                },
                receiveValue: { response in
                    DispatchQueue.main.async {
                        self.aiInsight = response.insight
                        self.recommendedQuotes = response.recommendedQuotes
                        self.selectedQuoteIndex = 0
                        
                        if let firstQuote = response.recommendedQuotes.first {
                            self.motivationalQuote = firstQuote.text
                            self.quoteAuthor = firstQuote.author
                        } else {
                            // Fallback to random quote
                            if let randomQuote = enhancedQuoteManager.quotes.randomElement() {
                                self.motivationalQuote = randomQuote.text
                                self.quoteAuthor = randomQuote.author
                            } else {
                                self.motivationalQuote = "The only way to do great work is to love what you do."
                                self.quoteAuthor = "Steve Jobs"
                            }
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func transcribeAudio() {
        guard let url = recordingURL else {
            print("❌ No recording URL available for transcription")
            return
        }
        
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.performTranscription(url: url)
                case .denied, .restricted, .notDetermined:
                    print("❌ Speech recognition not authorized")
                    self.transcribedText = "I'm feeling overwhelmed and need some support right now."
                @unknown default:
                    print("❌ Unknown speech recognition authorization status")
                    self.transcribedText = "I'm going through a difficult time and could use some encouragement."
                }
            }
        }
    }
    
    private func performTranscription(url: URL) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ Speech recognizer not available")
            self.transcribedText = "I'm feeling stressed and need some motivation."
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Transcription error: \(error)")
                    self.transcribedText = "I'm going through a challenging time and need some wisdom."
                    return
                }
                
                if let result = result, result.isFinal {
                    let transcribed = result.bestTranscription.formattedString
                    print("🎤 Transcribed text: \(transcribed)")
                    self.transcribedText = transcribed
                    
                    // Update the recording message with transcribed text
                    if !transcribed.isEmpty {
                        self.recordingMessage = transcribed
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func nextQuote() {
        guard !recommendedQuotes.isEmpty else { return }
            selectedQuoteIndex = (selectedQuoteIndex + 1) % recommendedQuotes.count
        guard selectedQuoteIndex < recommendedQuotes.count else { return }
            let quote = recommendedQuotes[selectedQuoteIndex]
            motivationalQuote = quote.text
            quoteAuthor = quote.author
    }
    
    private func previousQuote() {
        guard !recommendedQuotes.isEmpty else { return }
            selectedQuoteIndex = selectedQuoteIndex == 0 ? recommendedQuotes.count - 1 : selectedQuoteIndex - 1
        guard selectedQuoteIndex < recommendedQuotes.count else { return }
            let quote = recommendedQuotes[selectedQuoteIndex]
            motivationalQuote = quote.text
            quoteAuthor = quote.author
    }
}

struct VoiceAnimationView: View {
    @State private var animationAmount = 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 4, height: 20 + CGFloat(index * 8))
                    .scaleEffect(y: animationAmount, anchor: .bottom)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: animationAmount
                    )
            }
        }
        .onAppear {
            animationAmount = 2.0
        }
    }
}

struct PlaybackAnimationView: View {
    @State private var animationAmount = 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4, height: 20 + CGFloat(index * 8))
                    .scaleEffect(y: animationAmount, anchor: .bottom)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: animationAmount
                    )
            }
        }
        .onAppear {
            animationAmount = 2.0
        }
    }
}

#Preview {
    AudioView()
}

// MARK: - Audio Player Delegate

class AudioPlayerDelegate: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            print("🎵 Audio playback finished successfully: \(flag)")
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
            print("❌ Audio playback error: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
} 