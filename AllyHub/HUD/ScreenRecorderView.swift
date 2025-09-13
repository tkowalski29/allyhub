import SwiftUI
import ScreenCaptureKit
import AVFoundation
import OSLog

@available(macOS 12.3, *)
@MainActor
final class ScreenRecorderManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var isAvailable = false
    @Published var recordingURL: URL?
    @Published var errorMessage: String?
    @Published var availableApps: [SCRunningApplication] = []
    @Published var selectedApp: SCRunningApplication?
    @Published var availableDisplays: [SCDisplay] = []
    @Published var selectedDisplay: SCDisplay?
    @Published var recordingMode: RecordingMode = .application
    
    private var recordingTimer: Timer?
    private var startTime: Date?
    private var screenRecorder: ScreenRecorder?
    private var captureEngine: SCStreamConfiguration?
    
    enum RecordingMode: String, CaseIterable {
        case application = "application"
        case display = "display"
        
        var displayName: String {
            switch self {
            case .application: return "Application Window"
            case .display: return "Entire Screen"
            }
        }
    }
    
    init() {
        checkAvailability()
    }
    
    private func checkAvailability() {
        // ScreenCaptureKit is available on macOS 12.3+
        if #available(macOS 12.3, *) {
            isAvailable = true
            loadAvailableApps()
        } else {
            isAvailable = false
            errorMessage = "Screen recording requires macOS 12.3 or later"
        }
    }
    
    private func loadAvailableApps() {
        Task {
            do {
                // Request content from ScreenCaptureKit
                let content = try await SCShareableContent.current
                
                // Filter running applications
                let filteredApps = content.applications.filter { app in
                    // Filter for visible applications with windows
                    app.applicationName.count > 1 && 
                    content.windows.contains { window in
                        window.owningApplication == app && window.isOnScreen
                    }
                }.sorted { $0.applicationName < $1.applicationName }
                
                availableApps = filteredApps
                selectedApp = filteredApps.first
                
                // Get available displays
                availableDisplays = content.displays
                selectedDisplay = content.displays.first
                
                print("🖥️ Found \(filteredApps.count) applications and \(content.displays.count) displays")
                
            } catch {
                errorMessage = "Failed to load available content: \(error.localizedDescription)"
                print("❌ ScreenCaptureKit content loading failed: \(error)")
            }
        }
    }
    
    func startRecording() {
        guard !isRecording, isAvailable else { return }
        
        Task {
            do {
                // Create temporary file URL
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let videoURL = documentsPath.appendingPathComponent("screen_recording_\(Date().timeIntervalSince1970).mov")
                
                recordingURL = videoURL
                isRecording = true
                recordingTime = 0
                startTime = Date()
                errorMessage = nil
                
                print("🖥️ Starting screen recording to: \(videoURL.path)")
                
                // Create and start screen recorder
                screenRecorder = try await createScreenRecorder(outputURL: videoURL)
                try await screenRecorder?.startRecording()
                
                // Start timer for UI updates
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        await self?.updateRecordingTime()
                    }
                }
                
            } catch {
                isRecording = false
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
                print("❌ Screen recording start failed: \(error)")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        Task {
            do {
                recordingTimer?.invalidate()
                recordingTimer = nil
                
                await screenRecorder?.stopRecording()
                screenRecorder = nil
                
                isRecording = false
                print("🛑 Screen recording stopped")
                
            } catch {
                isRecording = false
                errorMessage = "Failed to stop recording: \(error.localizedDescription)"
                print("❌ Screen recording stop failed: \(error)")
            }
        }
    }
    
    private func createScreenRecorder(outputURL: URL) async throws -> ScreenRecorder {
        let content = try await SCShareableContent.current
        
        let filter: SCContentFilter
        
        switch recordingMode {
        case .application:
            guard let selectedApp = selectedApp else {
                throw ScreenRecordingError.noAppSelected
            }
            
            // Get windows for the selected application
            let appWindows = content.windows.filter { $0.owningApplication == selectedApp && $0.isOnScreen }
            guard !appWindows.isEmpty else {
                throw ScreenRecordingError.noVisibleWindows
            }
            
            filter = SCContentFilter(desktopIndependentWindow: appWindows.first!)
            
        case .display:
            guard let selectedDisplay = selectedDisplay else {
                throw ScreenRecordingError.noDisplaySelected
            }
            
            filter = SCContentFilter(display: selectedDisplay, excludingWindows: [])
        }
        
        // Configure recording settings
        let configuration = SCStreamConfiguration()
        configuration.videoCodecType = .h264
        configuration.scalesToFit = true
        configuration.width = 1920
        configuration.height = 1080
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30 FPS
        configuration.queueDepth = 5
        configuration.showsCursor = true
        configuration.capturesAudio = true
        configuration.sampleRate = 44100
        configuration.channelCount = 2
        
        return try ScreenRecorder(
            filter: filter,
            configuration: configuration,
            outputURL: outputURL
        )
    }
    
    private func updateRecordingTime() async {
        guard let startTime = startTime, isRecording else { return }
        recordingTime = Date().timeIntervalSince(startTime)
    }
}

@available(macOS 12.3, *)
struct ScreenRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var screenManager = ScreenRecorderManager()
    @State private var taskTitle: String = ""
    @State private var taskDescription: String = ""
    @State private var showTaskDetails: Bool = false
    @State private var showUploadProgress: Bool = false
    @StateObject private var uploadService = FileUploadService()
    
    let onTaskCreated: (TaskItem) -> Void
    let communicationSettings: CommunicationSettings
    
    private var isReadyToRecord: Bool {
        switch screenManager.recordingMode {
        case .application:
            return screenManager.selectedApp != nil
        case .display:
            return screenManager.selectedDisplay != nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Record Screen Activity")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(screenManager.isRecording ? "Recording in progress..." : "Select app and start recording")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            if !screenManager.isAvailable {
                // Not available message
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    
                    Text("Screen recording requires macOS 12.3 or later")
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    if let error = screenManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            } else {
                // Recording interface
                VStack(spacing: 20) {
                    // Recording mode selector (only show when not recording)
                    if !screenManager.isRecording {
                        VStack(alignment: .leading, spacing: 12) {
                            // Recording mode picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Recording Mode")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                Picker("Mode", selection: $screenManager.recordingMode) {
                                    ForEach(ScreenRecorderManager.RecordingMode.allCases, id: \.self) { mode in
                                        Text(mode.displayName)
                                            .tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .colorScheme(.dark)
                            }
                            
                            // Application selector (for application mode)
                            if screenManager.recordingMode == .application {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Select Application")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                    
                                    if screenManager.availableApps.isEmpty {
                                        Text("Loading applications...")
                                            .font(.body)
                                            .foregroundStyle(.white.opacity(0.7))
                                            .padding()
                                    } else {
                                        Picker("Application", selection: $screenManager.selectedApp) {
                                            ForEach(screenManager.availableApps, id: \.bundleIdentifier) { app in
                                                Text(app.applicationName)
                                                    .tag(app as SCRunningApplication?)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .foregroundStyle(.white)
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
                                    }
                                }
                            }
                            
                            // Display selector (for display mode)
                            if screenManager.recordingMode == .display {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Select Display")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                    
                                    if screenManager.availableDisplays.isEmpty {
                                        Text("Loading displays...")
                                            .font(.body)
                                            .foregroundStyle(.white.opacity(0.7))
                                            .padding()
                                    } else {
                                        Picker("Display", selection: $screenManager.selectedDisplay) {
                                            ForEach(screenManager.availableDisplays, id: \.displayID) { display in
                                                Text("Display \(display.displayID) (\(Int(display.width))x\(Int(display.height)))")
                                                    .tag(display as SCDisplay?)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .foregroundStyle(.white)
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
                                    }
                                }
                            }
                        }
                    }
                    
                    // Recording time display
                    if screenManager.isRecording {
                        VStack(spacing: 8) {
                            Text(formatTime(screenManager.recordingTime))
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                            
                            if screenManager.recordingMode == .application, let app = screenManager.selectedApp {
                                Text("Recording: \(app.applicationName)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            } else if screenManager.recordingMode == .display, let display = screenManager.selectedDisplay {
                                Text("Recording: Display \(display.displayID)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            
                            // Recording indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 12, height: 12)
                                    .opacity(screenManager.isRecording ? 1 : 0)
                                    .animation(.easeInOut(duration: 1).repeatForever(), value: screenManager.isRecording)
                                
                                Text("REC")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    // Record button
                    Button(action: {
                        if screenManager.isRecording {
                            screenManager.stopRecording()
                            showTaskDetails = true
                        } else {
                            screenManager.startRecording()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(screenManager.isRecording ? .red : .purple)
                                .frame(width: 120, height: 50)
                            
                            HStack(spacing: 8) {
                                Image(systemName: screenManager.isRecording ? "stop.fill" : "display")
                                    .font(.system(size: 18))
                                
                                Text(screenManager.isRecording ? "Stop" : "Start")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!screenManager.isAvailable || (!screenManager.isRecording && !isReadyToRecord))
                    
                    if let error = screenManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 20)
                
                // Task details form (shown after recording)
                if showTaskDetails && !screenManager.isRecording {
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
                        
                        // Recording info
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recording Info")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            
                            Text("App: \(screenManager.selectedApp ?? "Unknown")\nDuration: \(formatTime(screenManager.recordingTime))")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
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
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    if screenManager.isRecording {
                        screenManager.stopRecording()
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
                
                if showTaskDetails && !screenManager.isRecording {
                    Button("Create Task") {
                        createTask()
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.purple)
                    )
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 450, height: showTaskDetails && !screenManager.isRecording ? 650 : 500)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: showTaskDetails)
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
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func createTask() {
        // Show upload progress
        showUploadProgress = true
        
        Task {
            await uploadAndCreateTask()
        }
    }
    
    private func uploadAndCreateTask() async {
        guard let videoURL = screenManager.recordingURL else {
            await MainActor.run {
                uploadService.errorMessage = "No screen recording found"
                showUploadProgress = false
            }
            return
        }
        
        // Create upload metadata
        let metadata = ScreenUploadMetadata(
            title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: .medium,
            appName: screenManager.selectedApp?.applicationName,
            recordingMode: screenManager.recordingMode.rawValue,
            duration: screenManager.recordingTime
        )
        
        // Get upload endpoint from CommunicationSettings
        let uploadEndpoint = communicationSettings.taskCreateURL
        
        let result = await uploadService.uploadScreenRecording(
            from: videoURL,
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
                    creationType: .screen,
                    audioUrl: videoURL.path,
                    transcription: "Screen recording: \(metadata.appName ?? "Unknown app")"
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

// Fallback view for macOS versions < 12.3
struct ScreenRecorderFallbackView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Screen Recording Unavailable")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("Screen recording requires macOS 12.3 or later.\nThis feature is not available on your system.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Close") {
                dismiss()
            }
            .foregroundStyle(.white)
            .fontWeight(.medium)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray)
            )
        }
        .frame(width: 400, height: 300)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - ScreenRecorder Implementation

@available(macOS 12.3, *)
class ScreenRecorder: NSObject {
    private let filter: SCContentFilter
    private let configuration: SCStreamConfiguration
    private let outputURL: URL
    private var stream: SCStream?
    private var videoWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private let logger = Logger(subsystem: "com.sembot.AllyHub", category: "ScreenRecorder")
    
    init(filter: SCContentFilter, configuration: SCStreamConfiguration, outputURL: URL) throws {
        self.filter = filter
        self.configuration = configuration
        self.outputURL = outputURL
        super.init()
        try setupWriter()
    }
    
    private func setupWriter() throws {
        videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        // Video input setup
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: configuration.width,
            AVVideoHeightKey: configuration.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 5_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true
        
        if let videoInput = videoInput, videoWriter?.canAdd(videoInput) == true {
            videoWriter?.add(videoInput)
        }
        
        // Audio input setup
        if configuration.capturesAudio {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: configuration.sampleRate,
                AVNumberOfChannelsKey: configuration.channelCount,
                AVEncoderBitRateKey: 128_000
            ]
            
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = true
            
            if let audioInput = audioInput, videoWriter?.canAdd(audioInput) == true {
                videoWriter?.add(audioInput)
            }
        }
    }
    
    func startRecording() async throws {
        guard let videoWriter = videoWriter else {
            throw ScreenRecordingError.writerNotInitialized
        }
        
        // Start the asset writer
        guard videoWriter.startWriting() else {
            throw ScreenRecordingError.failedToStartWriting
        }
        
        videoWriter.startSession(atSourceTime: .zero)
        
        // Create and start the screen capture stream
        stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        
        do {
            try await stream?.startCapture()
            logger.info("Screen recording started successfully")
        } catch {
            logger.error("Failed to start screen capture: \(error.localizedDescription)")
            throw ScreenRecordingError.failedToStartCapture(error)
        }
    }
    
    func stopRecording() async {
        do {
            try await stream?.stopCapture()
            stream = nil
            
            videoInput?.markAsFinished()
            audioInput?.markAsFinished()
            
            await videoWriter?.finishWriting()
            videoWriter = nil
            
            logger.info("Screen recording stopped successfully")
        } catch {
            logger.error("Error stopping screen recording: \(error.localizedDescription)")
        }
    }
}

// MARK: - SCStreamDelegate

@available(macOS 12.3, *)
extension ScreenRecorder: SCStreamDelegate {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard let videoWriter = videoWriter,
              videoWriter.status == .writing else { return }
        
        switch type {
        case .screen:
            if let videoInput = videoInput, videoInput.isReadyForMoreMediaData {
                videoInput.append(sampleBuffer)
            }
        case .audio:
            if let audioInput = audioInput, audioInput.isReadyForMoreMediaData {
                audioInput.append(sampleBuffer)
            }
        @unknown default:
            logger.warning("Unknown sample buffer type received")
        }
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        logger.error("Stream stopped with error: \(error.localizedDescription)")
    }
}

// MARK: - Error Types

enum ScreenRecordingError: LocalizedError {
    case noAppSelected
    case noDisplaySelected
    case noVisibleWindows
    case writerNotInitialized
    case failedToStartWriting
    case failedToStartCapture(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAppSelected:
            return "No application selected for recording"
        case .noDisplaySelected:
            return "No display selected for recording"
        case .noVisibleWindows:
            return "Selected application has no visible windows"
        case .writerNotInitialized:
            return "Video writer not properly initialized"
        case .failedToStartWriting:
            return "Failed to start video writing"
        case .failedToStartCapture(let error):
            return "Failed to start screen capture: \(error.localizedDescription)"
        }
    }
}

#Preview {
    if #available(macOS 12.3, *) {
        ScreenRecorderView(onTaskCreated: { task in
            print("Created screen recording task: \(task.title)")
        }, communicationSettings: CommunicationSettings())
        .preferredColorScheme(.dark)
    } else {
        ScreenRecorderFallbackView()
            .preferredColorScheme(.dark)
    }
}