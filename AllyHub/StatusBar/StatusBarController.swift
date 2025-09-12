import Cocoa
import Combine

@MainActor
final class StatusBarController: NSObject {
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private let timerModel: TimerModel
    private let tasksModel: TasksModel
    private var cancellables = Set<AnyCancellable>()
    
    weak var delegate: StatusBarControllerDelegate?
    
    // Menu items that need to be updated
    private weak var showHideMenuItem: NSMenuItem?
    private weak var timerMenuItem: NSMenuItem?
    private weak var taskMenuItem: NSMenuItem?
    
    // MARK: - Initialization
    init(timerModel: TimerModel, tasksModel: TasksModel) {
        self.timerModel = timerModel
        self.tasksModel = tasksModel
        super.init()
        
        setupStatusItem()
        setupMenu()
        observeModels()
    }
    
    // MARK: - Setup Methods
    private func setupStatusItem() {
        // Create status item
        print("🔧 Setting up status item...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("✅ Status item created: \(statusItem != nil)")
        
        guard let statusItem = statusItem else { return }
        
        // Configure button
        if let button = statusItem.button {
            // Use a simple text icon as fallback
            button.title = "⏱ AllyHub"
            button.toolTip = "AllyHub - Smart Assistant Hub"
            print("🔧 Button configured with title: \(button.title ?? "nil")")
            
            // Set up click handling
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            print("🔧 Click handling configured")
        } else {
            print("❌ Failed to get status item button")
        }
        
        updateStatusItemAppearance()
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
        // Show/Hide HUD
        let showHideItem = NSMenuItem(
            title: "Show HUD",
            action: #selector(toggleHUD),
            keyEquivalent: "h"
        )
        showHideItem.target = self
        showHideMenuItem = showHideItem
        menu?.addItem(showHideItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Timer controls
        let timerItem = NSMenuItem(
            title: "Start Timer",
            action: #selector(toggleTimer),
            keyEquivalent: "t"
        )
        timerItem.target = self
        timerMenuItem = timerItem
        menu?.addItem(timerItem)
        
        let resetItem = NSMenuItem(
            title: "Reset Timer",
            action: #selector(resetTimer),
            keyEquivalent: "r"
        )
        resetItem.target = self
        menu?.addItem(resetItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Task controls
        let taskItem = NSMenuItem(
            title: "Current Task: Loading...",
            action: nil,
            keyEquivalent: ""
        )
        taskItem.isEnabled = false
        taskMenuItem = taskItem
        menu?.addItem(taskItem)
        
        let nextTaskItem = NSMenuItem(
            title: "Next Task",
            action: #selector(nextTask),
            keyEquivalent: "n"
        )
        nextTaskItem.target = self
        menu?.addItem(nextTaskItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // App controls
        let quitItem = NSMenuItem(
            title: "Quit AllyHub",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func observeModels() {
        // Observe timer state changes
        timerModel.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
                self?.updateMenuItems()
            }
            .store(in: &cancellables)
        
        timerModel.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)
        
        timerModel.$isPaused
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuItems()
            }
            .store(in: &cancellables)
        
        // Observe task changes
        tasksModel.$currentTaskIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuItems()
            }
            .store(in: &cancellables)
        
        tasksModel.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuItems()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Status Item Updates
    private func updateStatusItemAppearance() {
        guard let button = statusItem?.button else { return }
        
        // Update icon based on timer state
        let symbolName: String
        if timerModel.isCompleted {
            symbolName = "timer.square"
        } else if timerModel.isRunning {
            symbolName = "play.circle.fill"
        } else if timerModel.isPaused {
            symbolName = "pause.circle.fill"
        } else {
            symbolName = "timer"
        }
        
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "AllyHub Timer")
        button.image?.isTemplate = true
        
        // Update tooltip with current time
        let timeRemaining = timerModel.formattedTime
        let status = timerModel.isRunning ? "Running" : timerModel.isPaused ? "Paused" : "Stopped"
        button.toolTip = "AllyHub - \(timeRemaining) (\(status))"
        
        // Update tint color for visual feedback
        if timerModel.isRunning {
            button.contentTintColor = .systemBlue
        } else if timerModel.isPaused {
            button.contentTintColor = .systemOrange
        } else if timerModel.isCompleted {
            button.contentTintColor = .systemRed
        } else {
            button.contentTintColor = .controlAccentColor
        }
    }
    
    private func updateMenuItems() {
        // Update timer menu item
        if timerModel.isRunning {
            timerMenuItem?.title = "Pause Timer (\(timerModel.formattedTime))"
        } else if timerModel.isPaused {
            timerMenuItem?.title = "Resume Timer (\(timerModel.formattedTime))"
        } else if timerModel.isCompleted {
            timerMenuItem?.title = "Timer Completed"
            timerMenuItem?.isEnabled = false
        } else {
            timerMenuItem?.title = "Start Timer (\(timerModel.formattedTime))"
        }
        
        // Update task menu item
        let currentTask = tasksModel.currentTaskTitle
        let taskProgress = "\(tasksModel.currentTaskIndex + 1)/\(tasksModel.tasks.count)"
        taskMenuItem?.title = "Task \(taskProgress): \(currentTask)"
    }
    
    // MARK: - Actions
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        print("🖱️ Status item clicked!")
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click - show menu
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
        } else {
            // Left click - toggle HUD
            delegate?.statusBarControllerDidRequestToggleHUD(self)
        }
    }
    
    @objc private func toggleHUD() {
        delegate?.statusBarControllerDidRequestToggleHUD(self)
        updateShowHideMenuItem()
    }
    
    @objc private func toggleTimer() {
        delegate?.statusBarControllerDidRequestToggleTimer(self)
    }
    
    @objc private func resetTimer() {
        delegate?.statusBarControllerDidRequestStopTimer(self)
        // Reset will be handled by the timer model
        timerModel.reset()
    }
    
    @objc private func nextTask() {
        tasksModel.nextTask()
    }
    
    @objc private func quit() {
        delegate?.statusBarControllerDidRequestQuit(self)
    }
    
    private func updateShowHideMenuItem() {
        // This would need to be coordinated with AppDelegate to know HUD visibility
        // For now, we'll keep it simple
        showHideMenuItem?.title = "Toggle HUD"
    }
}

// MARK: - Public Interface
extension StatusBarController {
    func updateHUDVisibility(_ isVisible: Bool) {
        showHideMenuItem?.title = isVisible ? "Hide HUD" : "Show HUD"
    }
}