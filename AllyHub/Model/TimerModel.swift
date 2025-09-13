import Foundation
import Combine

@MainActor
final class TimerModel: ObservableObject {
    // MARK: - Published Properties
    @Published var elapsedTime: TimeInterval = 0 // elapsed seconds from 0
    @Published var isRunning = false
    @Published var isPaused = false
    
    // MARK: - Private Properties
    private var timer: Timer?
    private let totalTime: TimeInterval = 60 * 60 // 60 minutes
    
    // For safe cleanup in deinit
    private let timerContainer = TimerContainer()
    
    // UserDefaults keys
    private let elapsedTimeKey = "AllyHub_ElapsedTime"
    private let isRunningKey = "AllyHub_IsRunning"
    private let lastSaveTimeKey = "AllyHub_LastSaveTime"
    
    // MARK: - Computed Properties
    var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var progress: Double {
        return max(0, min(1, elapsedTime / totalTime))
    }
    
    var isCompleted: Bool {
        return elapsedTime >= totalTime
    }
    
    // MARK: - Initialization
    init() {
        loadTimerState()
    }
    
    // MARK: - Public Methods
    func start() {
        guard !isCompleted else { return }
        
        isRunning = true
        isPaused = false
        
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        timer = newTimer
        timerContainer.timer = newTimer
        
        saveTimerState()
    }
    
    func pause() {
        isRunning = false
        isPaused = true
        invalidateTimer()
        
        saveTimerState()
    }
    
    func stop() {
        isRunning = false
        isPaused = false
        invalidateTimer()
        
        saveTimerState()
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        
        saveTimerState()
    }
    
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    // MARK: - Private Methods
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
        timerContainer.timer = nil
    }
    
    private func tick() {
        guard isRunning else { return }
        
        elapsedTime += 1
        
        // Check if completed (optional - can run indefinitely)
        if elapsedTime >= totalTime {
            complete()
            return
        }
        
        // Save state periodically (every 10 seconds to avoid excessive I/O)
        if Int(elapsedTime) % 10 == 0 {
            saveTimerState()
        }
    }
    
    private func complete() {
        stop()
        
        // Post notification for timer completion
        NotificationCenter.default.post(name: .timerCompleted, object: nil)
    }
    
    private func saveTimerState() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(elapsedTime, forKey: elapsedTimeKey)
        userDefaults.set(isRunning, forKey: isRunningKey)
        userDefaults.set(Date(), forKey: lastSaveTimeKey)
    }
    
    private func loadTimerState() {
        let userDefaults = UserDefaults.standard
        
        // Load saved elapsed time
        let savedElapsedTime = userDefaults.double(forKey: elapsedTimeKey)
        elapsedTime = max(0, savedElapsedTime)
        
        // Check if timer was running when app was closed
        let wasRunning = userDefaults.bool(forKey: isRunningKey)
        if wasRunning, let lastSaveTime = userDefaults.object(forKey: lastSaveTimeKey) as? Date {
            // Calculate additional elapsed time while app was closed
            let additionalElapsedTime = Date().timeIntervalSince(lastSaveTime)
            elapsedTime += additionalElapsedTime
            
            // Start in paused state, user can resume
            isPaused = true
        }
        
        // Clean up if needed
        if elapsedTime < 0 {
            elapsedTime = 0
            isRunning = false
            isPaused = false
        }
    }
}

// MARK: - Timer Container
private final class TimerContainer: @unchecked Sendable {
    var timer: Timer?
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let timerCompleted = Notification.Name("TimerCompleted")
}