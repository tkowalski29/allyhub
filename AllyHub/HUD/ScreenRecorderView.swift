import SwiftUI
@preconcurrency import ScreenCaptureKit
import AVFoundation
import OSLog

@available(macOS 12.3, *)
@MainActor
final class ScreenRecorderManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var availableApps: [SCRunningApplication] = []
    @Published var availableDisplays: [SCDisplay] = []
    @Published var selectedApp: SCRunningApplication?
    @Published var selectedDisplay: SCDisplay?
    @Published var recordingMode: RecordingMode = .application
    @Published var errorMessage: String?
    @Published var recordingURL: URL?
    
    private var screenRecorder: ScreenRecorder?
    private var timer: Timer?
    
    var isAvailable: Bool {
        if #available(macOS 12.3, *) {
            return true
        } else {
            return false
        }
    }
    
    enum RecordingMode: String, CaseIterable {
        case application = "application"
        case display = "display"
        
        var displayName: String {
            switch self {
            case .application: return "Application"
            case .display: return "Entire Screen"
            }
        }
    }
    
    init() {
        if #available(macOS 12.3, *) {
            loadAvailableApps()
        } else {
            errorMessage = "Screen recording requires macOS 12.3 or later"
        }
    }
    
    private func loadAvailableApps() {
        Task {
            do {
                // Request content from ScreenCaptureKit
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                
                // Filter running applications
                let filteredApps = content.applications.filter { app in
                    // Filter for visible applications with windows
                    app.applicationName.count > 1 && 
                    content.windows.contains { window in
                        window.owningApplication == app && window.isOnScreen
                    }
                }.sorted { $0.applicationName < $1.applicationName }
                
                await MainActor.run {
                    availableApps = filteredApps
                    selectedApp = filteredApps.first
                }
                
                await MainActor.run {
                    // Get available displays
                    availableDisplays = content.displays
                    selectedDisplay = content.displays.first
                }
                
                print("🖥️ Found \(filteredApps.count) applications and \(content.displays.count) displays")
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load available apps: \(error.localizedDescription)"
                }
                print("❌ Error loading apps: \(error)")
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        Task {
            do {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let outputURL = documentsPath.appendingPathComponent("screen_recording_\(Date().timeIntervalSince1970).mov")
                
                let recorder = try await createScreenRecorder(outputURL: outputURL)
                try await recorder.startRecording()
                
                await MainActor.run {
                    screenRecorder = recorder
                    isRecording = true
                    recordingTime = 0
                    recordingURL = outputURL
                    errorMessage = nil
                    
                    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        Task { @MainActor in
                            self.recordingTime += 0.1
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to start recording: \(error.localizedDescription)"
                    isRecording = false
                }
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        Task {
            let recorder = await MainActor.run { screenRecorder }
            await recorder?.stopRecording()
            
            await MainActor.run {
                screenRecorder = nil
                isRecording = false
                timer?.invalidate()
                timer = nil
                errorMessage = nil
            }
        }
    }
    
    private func createScreenRecorder(outputURL: URL) async throws -> ScreenRecorder {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        let filter: SCContentFilter
        
        switch recordingMode {
        case .application:
            guard let selectedApp = selectedApp else {
                throw ScreenRecordingError.noAppSelected
            }
            
            let appWindows = content.windows.filter { window in
                window.owningApplication == selectedApp && window.isOnScreen
            }
            
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
}

struct ScreenRecorderView: View {
    let onTaskCreated: (TaskItem) -> Void
    let communicationSettings: CommunicationSettings
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var screenManager = ScreenRecorderManager()
    @StateObject private var uploadService = FileUploadService()
    
    @State private var showTaskDetails = false
    @State private var taskTitle = ""
    @State private var taskDescription = ""
    @State private var showUploadProgress = false
    
    var isReadyToRecord: Bool {
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
                        }
                    }
                    
                    // Recording controls
                    VStack(spacing: 20) {
                        // Recording status and button
                        if screenManager.isRecording {
                            VStack(spacing: 8) {
                                Text(formatTime(screenManager.recordingTime))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                if screenManager.recordingMode == .application, let app = screenManager.selectedApp {
                                    Text(app.applicationName)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                } else if screenManager.recordingMode == .display, let display = screenManager.selectedDisplay {
                                    Text("Display \(display.displayID)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                
                                // Recording indicator
                                Circle()
                                    .fill(.red)
                                    .frame(width: 12, height: 12)
                                    .opacity(screenManager.isRecording ? 1 : 0)
                                    .animation(.easeInOut(duration: 1).repeatForever(), value: screenManager.isRecording)
                            }
                        }
                        
                        // Recording button
                        Button(action: {
                            if screenManager.isRecording {
                                screenManager.stopRecording()
                                showTaskDetails = true
                            } else {
                                screenManager.startRecording()
                            }
                        }) {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(screenManager.isRecording ? .red : .purple)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: screenManager.isRecording ? "stop.fill" : "display")
                                            .font(.system(size: 24))
                                            .foregroundStyle(.white)
                                    )
                                Text(screenManager.isRecording ? "Stop" : "Start")
                                    .font(.caption)
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
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Task form (show after recording)
                    if showTaskDetails && !screenManager.isRecording {
                        VStack(spacing: 16) {
                            Text("Create Task from Recording")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
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
                                Text("Task Description")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                TextField("Enter task description", text: $taskDescription, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .lineLimit(3...6)
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
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
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
                            .fill(.blue)
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
            Group {
                if showUploadProgress {
                    Color.black.opacity(0.3)
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
        
        let appName = screenManager.selectedApp?.applicationName ?? "Screen"
        let metadata = ScreenUploadMetadata(
            title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: .medium,
            appName: appName,
            recordingMode: screenManager.recordingMode.rawValue,
            duration: screenManager.recordingTime
        )
        
        // Try to upload if API is configured
        if !communicationSettings.taskCreateURL.isEmpty {
            let result = await uploadService.uploadScreenRecording(
                from: videoURL,
                to: communicationSettings.taskCreateURL,
                withMetadata: metadata
            )
            
            await MainActor.run {
                if result.success {
                    // Create local task after successful upload
                    createLocalTask(metadata: metadata, audioUrl: videoURL.path)
                } else {
                    // Fall back to local task if upload fails
                    createLocalTask(metadata: metadata, audioUrl: videoURL.path)
                }
                showUploadProgress = false
            }
        } else {
            // Create local task if no API configured
            await MainActor.run {
                createLocalTask(metadata: metadata, audioUrl: videoURL.path)
                showUploadProgress = false
            }
        }
    }
    
    private func createLocalTask(metadata: ScreenUploadMetadata, audioUrl: String) {
        let task = TaskItem(
            title: metadata.title,
            description: metadata.description,
            status: .todo,
            priority: TaskPriority(rawValue: metadata.priority) ?? .medium,
            isCompleted: false,
            createdAt: Date(),
            creationType: .screen,
            audioUrl: audioUrl,
            transcription: "Screen recording: \(metadata.appName ?? "Unknown app")"
        )
        
        onTaskCreated(task)
        dismiss()
    }
}

// MARK: - Fallback View for older macOS

struct ScreenRecorderFallbackView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Screen Recording Not Available")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("Screen recording requires macOS 12.3 or later")
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
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

// MARK: - Screen Recorder

@available(macOS 12.3, *)
final class ScreenRecorder: @unchecked Sendable {
    private let stream: SCStream
    private let videoWriter: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let audioInput: AVAssetWriterInput?
    private let outputURL: URL
    
    private let logger = Logger(subsystem: "AllyHub", category: "ScreenRecorder")
    
    init(filter: SCContentFilter, configuration: SCStreamConfiguration, outputURL: URL) throws {
        self.outputURL = outputURL
        self.stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        
        // Initialize video writer
        self.videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        // Video input settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: configuration.width,
            AVVideoHeightKey: configuration.height
        ]
        
        self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true
        
        if videoWriter.canAdd(videoInput) {
            videoWriter.add(videoInput)
        }
        
        // Audio input settings (if audio capture is enabled)
        if configuration.capturesAudio {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: configuration.sampleRate,
                AVNumberOfChannelsKey: configuration.channelCount
            ]
            
            self.audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = true
            
            if let audioInput = audioInput, videoWriter.canAdd(audioInput) {
                videoWriter.add(audioInput)
            }
        } else {
            self.audioInput = nil
        }
    }
    
    func startRecording() async throws {
        guard videoWriter.startWriting() else {
            throw ScreenRecordingError.failedToStartWriting
        }
        
        do {
            try await stream.startCapture()
            logger.info("Screen recording started successfully")
        } catch {
            logger.error("Failed to start screen capture: \(error.localizedDescription)")
            throw ScreenRecordingError.failedToStartCapture(error)
        }
    }
    
    func stopRecording() async {
        do {
            try await stream.stopCapture()
            
            videoInput.markAsFinished()
            audioInput?.markAsFinished()
            
            await videoWriter.finishWriting()
            
            logger.info("Screen recording stopped successfully")
        } catch {
            logger.error("Error stopping screen recording: \(error.localizedDescription)")
        }
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