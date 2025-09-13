import Cocoa
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    private var statusBarController: StatusBarController?
    private var floatingPanel: FloatingPanel?
    
    // Shared models
    let timerModel = TimerModel()
    let tasksModel = TasksModel()
    let gradientSettings = GradientSettings()
    let communicationSettings = CommunicationSettings()
    let keyboardShortcutsSettings = KeyboardShortcutsSettings()
    
    // MARK: - Application Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AllyHub application launching...")
        setupApplication()
        print("📱 Setting up status bar...")
        setupStatusBar()
        print("🪟 Setting up floating panel...")
        setupFloatingPanel()
        print("🔔 Setting up notifications...")
        setupNotifications()
        print("✅ AllyHub setup complete!")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate when closing windows - this is a menu bar app
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show HUD when app is reopened
        showHUD()
        return true
    }
    
    // MARK: - Setup Methods
    private func setupApplication() {
        // Configure the application for menu bar mode
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Hide dock icon (this is also controlled by LSUIElement in Info.plist)
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Configure app appearance
        if #available(macOS 14.0, *) {
            NSApplication.shared.appearance = NSAppearance(named: .aqua)
        }
    }
    
    private func setupStatusBar() {
        statusBarController = StatusBarController(
            timerModel: timerModel,
            tasksModel: tasksModel
        )
        statusBarController?.delegate = self
    }
    
    private func setupFloatingPanel() {
        floatingPanel = FloatingPanel(
            timerModel: timerModel,
            tasksModel: tasksModel,
            gradientSettings: gradientSettings,
            communicationSettings: communicationSettings,
            keyboardShortcutsSettings: keyboardShortcutsSettings
        )
        floatingPanel?.appDelegate = self
        
        // Show the panel by default for testing
        showHUD()
        print("🪟 HUD automatically shown on startup")
    }
    
    private func setupNotifications() {
        // Listen for timer completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timerCompleted),
            name: .timerCompleted,
            object: nil
        )
        
        // Listen for application state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: NSApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Setup keyboard shortcuts
        setupKeyboardShortcuts()
    }
    
    private func setupKeyboardShortcuts() {
        // Add menu item with keyboard shortcut for testing
        let mainMenu = NSApplication.shared.mainMenu
        if let appMenu = mainMenu?.items.first?.submenu {
            let toggleItem = NSMenuItem(
                title: "Toggle HUD",
                action: #selector(toggleHUD),
                keyEquivalent: "t"
            )
            toggleItem.keyEquivalentModifierMask = [.command, .option]
            toggleItem.target = self
            appMenu.addItem(toggleItem)
            print("⌨️ Keyboard shortcut added: ⌘⌥T")
        }
    }
    
    // MARK: - Public Methods
    func showHUD() {
        floatingPanel?.level = NSWindow.Level(rawValue: 2147483631)  // Force maximum level
        floatingPanel?.makeKeyAndOrderFront(nil)
        floatingPanel?.orderFrontRegardless()  // Force to front
    }
    
    func hideHUD() {
        floatingPanel?.orderOut(nil)
    }
    
    @objc func toggleHUD() {
        guard let panel = floatingPanel else { return }
        
        if panel.isVisible {
            hideHUD()
        } else {
            showHUD()
        }
    }
    
    func startTimer() {
        timerModel.start()
    }
    
    func stopTimer() {
        timerModel.stop()
    }
    
    func toggleTimer() {
        timerModel.toggle()
    }
    
    func resetTimer() {
        timerModel.reset()
    }
    
    func nextTask() {
        tasksModel.nextTask()
    }
    
    // MARK: - Notification Handlers
    @objc private func timerCompleted() {
        // Show notification when timer completes
        showTimerCompletionNotification()
        
        // Optionally show HUD if it's hidden
        if floatingPanel?.isVisible == false {
            showHUD()
        }
    }
    
    @objc private func applicationWillResignActive() {
        // App is becoming inactive - save state
        // The models handle their own persistence, but we could add app-level state here
    }
    
    @objc private func applicationDidBecomeActive() {
        // App is becoming active - refresh state if needed
        // The models handle their own state loading
    }
    
    // MARK: - Private Methods
    private func showTimerCompletionNotification() {
        let notification = NSUserNotification()
        notification.title = "AllyHub Timer"
        notification.informativeText = "Timer completed! Time for the next task."
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func updateWindowSize() {
        floatingPanel?.updateWindowSize()
    }
    
    private func cleanup() {
        // Clean up resources
        NotificationCenter.default.removeObserver(self)
        statusBarController = nil
        floatingPanel = nil
    }
}

// MARK: - StatusBarController Delegate
extension AppDelegate: StatusBarControllerDelegate {
    nonisolated func statusBarControllerDidRequestShowHUD(_ controller: StatusBarController) {
        Task { @MainActor in
            showHUD()
        }
    }
    
    nonisolated func statusBarControllerDidRequestHideHUD(_ controller: StatusBarController) {
        Task { @MainActor in
            hideHUD()
        }
    }
    
    nonisolated func statusBarControllerDidRequestToggleHUD(_ controller: StatusBarController) {
        Task { @MainActor in
            toggleHUD()
        }
    }
    
    nonisolated func statusBarControllerDidRequestStartTimer(_ controller: StatusBarController) {
        Task { @MainActor in
            startTimer()
        }
    }
    
    nonisolated func statusBarControllerDidRequestStopTimer(_ controller: StatusBarController) {
        Task { @MainActor in
            stopTimer()
        }
    }
    
    nonisolated func statusBarControllerDidRequestToggleTimer(_ controller: StatusBarController) {
        Task { @MainActor in
            toggleTimer()
        }
    }
    
    nonisolated func statusBarControllerDidRequestQuit(_ controller: StatusBarController) {
        Task { @MainActor in
            NSApplication.shared.terminate(nil)
        }
    }
}

// MARK: - StatusBarControllerDelegate Protocol
@MainActor
protocol StatusBarControllerDelegate: AnyObject {
    func statusBarControllerDidRequestShowHUD(_ controller: StatusBarController)
    func statusBarControllerDidRequestHideHUD(_ controller: StatusBarController)
    func statusBarControllerDidRequestToggleHUD(_ controller: StatusBarController)
    func statusBarControllerDidRequestStartTimer(_ controller: StatusBarController)
    func statusBarControllerDidRequestStopTimer(_ controller: StatusBarController)
    func statusBarControllerDidRequestToggleTimer(_ controller: StatusBarController)
    func statusBarControllerDidRequestQuit(_ controller: StatusBarController)
}