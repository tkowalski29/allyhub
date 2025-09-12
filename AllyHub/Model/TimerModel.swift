import Foundation
import Combine

@MainActor
final class TimerModel: ObservableObject {
    // MARK: - Published Properties
    @Published var remainingTime: TimeInterval = 60 * 60 // 60 minutes in seconds
    @Published var isRunning = false
    @Published var isPaused = false
    
    // MARK: - Private Properties
    private var timer: Timer?
    private let totalTime: TimeInterval = 60 * 60 // 60 minutes
    
    // For safe cleanup in deinit
    private let timerContainer = TimerContainer()
    
    // UserDefaults keys
    private let remainingTimeKey = "AllyHub_RemainingTime"
    private let isRunningKey = "AllyHub_IsRunning"
    private let lastSaveTimeKey = "AllyHub_LastSaveTime"
    
    // MARK: - Computed Properties
    var formattedTime: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var progress: Double {
        return max(0, min(1, (totalTime - remainingTime) / totalTime))
    }
    
    var isCompleted: Bool {
        return remainingTime <= 0
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
        remainingTime = totalTime
        
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
        guard isRunning && remainingTime > 0 else {
            complete()
            return
        }
        
        remainingTime = max(0, remainingTime - 1)
        
        // Save state periodically (every 10 seconds to avoid excessive I/O)
        if Int(remainingTime) % 10 == 0 {
            saveTimerState()
        }
    }
    
    private func complete() {
        remainingTime = 0
        stop()
        
        // Post notification for timer completion
        NotificationCenter.default.post(name: .timerCompleted, object: nil)
    }
    
    private func saveTimerState() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(remainingTime, forKey: remainingTimeKey)
        userDefaults.set(isRunning, forKey: isRunningKey)
        userDefaults.set(Date(), forKey: lastSaveTimeKey)
    }
    
    private func loadTimerState() {
        let userDefaults = UserDefaults.standard
        
        // Load saved remaining time
        let savedRemainingTime = userDefaults.double(forKey: remainingTimeKey)
        if savedRemainingTime > 0 {
            remainingTime = savedRemainingTime
        }
        
        // Check if timer was running when app was closed
        let wasRunning = userDefaults.bool(forKey: isRunningKey)
        if wasRunning, let lastSaveTime = userDefaults.object(forKey: lastSaveTimeKey) as? Date {
            // Calculate elapsed time while app was closed
            let elapsedTime = Date().timeIntervalSince(lastSaveTime)
            remainingTime = max(0, remainingTime - elapsedTime)
            
            // If there's still time remaining and it was running, continue the timer
            if remainingTime > 0 {
                isPaused = true // Start in paused state, user can resume
            }
        }
        
        // Clean up if timer was completed
        if remainingTime <= 0 {
            remainingTime = 0
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