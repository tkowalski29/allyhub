import SwiftUI
import AVFoundation

@MainActor
final class AudioRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevels: Float = 0.0
    @Published var recordingURL: URL?
    @Published var errorMessage: String?
    @Published var transcription: String = ""
    @Published var isTranscribing = false
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private let transcriptionService = TranscriptionService()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        // On macOS, microphone permission is handled differently
        // AVAudioSession is not available on macOS
        print("📱 Audio session setup for macOS - permission will be requested on first recording attempt")
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Create temporary file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // Audio recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            recordingURL = audioURL
            isRecording = true
            recordingTime = 0
            errorMessage = nil
            
            // Start timers
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.updateRecordingTime()
                }
            }
            
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.updateAudioLevels()
                }
            }
            
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        recordingTimer = nil
        levelTimer = nil
        isRecording = false
        audioLevels = 0.0
        
        // Start transcription automatically after recording stops
        Task {
            await startTranscription()
        }
    }
    
    private func updateRecordingTime() async {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recordingTime = recorder.currentTime
    }
    
    private func updateAudioLevels() async {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10, averagePower / 20) // Convert dB to linear
        audioLevels = max(0.0, min(1.0, normalizedLevel))
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
            if !flag {
                errorMessage = "Recording failed to complete successfully"
                recordingURL = nil
            } else {
                // Start transcription when recording finishes successfully
                await startTranscription()
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            isRecording = false
            errorMessage = "Recording error: \(error?.localizedDescription ?? "Unknown error")"
            recordingURL = nil
        }
    }
    
    // MARK: - Transcription
    
    private func startTranscription() async {
        guard let audioURL = recordingURL else {
            errorMessage = "No audio recording available for transcription"
            return
        }
        
        isTranscribing = true
        transcription = ""
        errorMessage = nil
        
        let result = await transcriptionService.transcribeAudio(from: audioURL)
        
        isTranscribing = false
        
        if result.isSuccess {
            transcription = result.transcribedText
            print("🎙️ Transcription completed: \(transcription)")
        } else {
            errorMessage = result.error
            print("❌ Transcription failed: \(result.error ?? "Unknown error")")
        }
    }
}

struct AudioRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioManager = AudioRecorderManager()
    @State private var taskTitle: String = ""
    @State private var taskDescription: String = ""
    @State private var transcriptionText: String = ""
    @State private var showTranscription: Bool = false
    @State private var showUploadProgress: Bool = false
    @StateObject private var uploadService = FileUploadService()
    
    let onTaskCreated: (TaskItem) -> Void
    let communicationSettings: CommunicationSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Record Audio Task")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(audioManager.isRecording ? "Recording in progress..." : "Tap to start recording")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Recording interface
            VStack(spacing: 20) {
                // Audio level visualization
                if audioManager.isRecording {
                    VStack(spacing: 8) {
                        Text(formatTime(audioManager.recordingTime))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        
                        // Audio level bars
                        HStack(spacing: 4) {
                            ForEach(0..<20, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(audioManager.audioLevels > Float(index) / 20.0 ? .green : .white.opacity(0.3))
                                    .frame(width: 8, height: CGFloat(12 + index * 2))
                            }
                        }
                    }
                }
                
                // Record button
                Button(action: {
                    if audioManager.isRecording {
                        audioManager.stopRecording()
                        showTranscription = true
                    } else {
                        audioManager.startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(audioManager.isRecording ? .red : .green)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: audioManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(audioManager.errorMessage != nil)
                
                if let error = audioManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 20)
            
            // Task details form (shown after recording)
            if showTranscription && !audioManager.isRecording {
                VStack(spacing: 16) {
                    // Title field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Task Title")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        TextField("Enter task title", text: $taskTitle)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(.white)
                    }
                    
                    // Description field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        TextField("Enter task description", text: $taskDescription, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(2...4)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(.white)
                    }
                    
                    // Transcription section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Transcription")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            
                            if audioManager.isTranscribing {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else if !audioManager.transcription.isEmpty {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                        }
                        
                        if audioManager.isTranscribing {
                            Text("Transcribing audio...")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.blue.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(.blue.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        } else if !audioManager.transcription.isEmpty {
                            Text(audioManager.transcription)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        } else {
                            Text("No transcription available yet")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white.opacity(0.02))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(.white.opacity(0.05), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    if audioManager.isRecording {
                        audioManager.stopRecording()
                    }
                    dismiss()
                }
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.1))
                )
                
                if showTranscription && !audioManager.isRecording {
                    Button("Create Task") {
                        createTask()
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.green)
                    )
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: showTranscription && !audioManager.isRecording ? 600 : 450)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: showTranscription)
        .overlay(
            // Upload progress overlay
            Group {
                if showUploadProgress {
                    Color.black.opacity(0.5)
                        .overlay(
                            UploadProgressView(uploadService: uploadService) {
                                showUploadProgress = false
                            }
                        )
                        .transition(.opacity)
                }
            }
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time * 100).truncatingRemainder(dividingBy: 100))
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func createTask() {
        // Show upload progress
        showUploadProgress = true
        
        Task {
            await uploadAndCreateTask()
        }
    }
    
    private func uploadAndCreateTask() async {
        guard let audioURL = audioManager.recordingURL else {
            await MainActor.run {
                uploadService.errorMessage = "No audio recording found"
                showUploadProgress = false
            }
            return
        }
        
        // Create upload metadata
        let metadata = AudioUploadMetadata(
            title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            transcription: audioManager.transcription.isEmpty ? nil : audioManager.transcription,
            duration: audioManager.recordingTime
        )
        
        // Get upload endpoint from CommunicationSettings
        let uploadEndpoint = communicationSettings.taskCreateURL
        
        let result = await uploadService.uploadAudioRecording(
            from: audioURL,
            to: uploadEndpoint,
            withMetadata: metadata
        )
        
        await MainActor.run {
            showUploadProgress = false
            
            if result.isSuccess {
                // Create local task item for immediate UI update
                let task = TaskItem(
                    title: metadata.title,
                    description: metadata.description,
                    status: .todo,
                    priority: .medium,
                    isCompleted: false,
                    createdAt: Date(),
                    creationType: .microphone,
                    audioUrl: audioURL.path,
                    transcription: metadata.transcription?.content
                )
                
                onTaskCreated(task)
                dismiss()
            } else {
                // Handle upload failure - could retry or create local task
                uploadService.errorMessage = result.error
            }
        }
    }
}

#Preview {
    AudioRecorderView(onTaskCreated: { task in
        print("Created audio task: \(task.title)")
    }, communicationSettings: CommunicationSettings())
    .preferredColorScheme(.dark)
}