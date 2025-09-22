import Cocoa
import SwiftUI
import ApplicationServices
import Carbon

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
    let taskCreationSettings = TaskCreationSettings()
    
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
            keyboardShortcutsSettings: keyboardShortcutsSettings,
            taskCreationSettings: taskCreationSettings
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
        // Set up global keyboard shortcut monitoring
        setupGlobalKeyboardShortcuts()
        
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
    
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    private func setupGlobalKeyboardShortcuts() {
        // Remove existing monitors if any
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        print("🌍 Setting up global keyboard shortcuts...")
        print("📍 Toggle Panel: \(keyboardShortcutsSettings.togglePanelShortcut.displayName)")
        
        // Skip automatic permission check - will be done from Settings
        
        // Warn about potentially conflicting shortcuts
        let shortcut = keyboardShortcutsSettings.togglePanelShortcut
        if shortcut.key == .a && shortcut.modifiers == [.control] {
            print("⚠️ WARNING: Control+A conflicts with 'Select All' in most apps")
            print("💡 Consider using Control+Shift+A (⌃⇧A) or Control+Option+A (⌃⌥A) instead")
        } else if shortcut.key == .a && shortcut.modifiers == [.control, .option] {
            print("✅ Good choice: Control+Option+A (⌃⌥A) is a safe shortcut")
        } else if shortcut.key == .a && shortcut.modifiers == [.control, .shift] {
            print("✅ Good choice: Control+Shift+A (⌃⇧A) is a safe shortcut")
        }
        
        // Create a local event monitor to consume events when app is focused
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            return self?.handleKeyboardShortcut(event)
        }
        
        // Create a global event monitor for when app is not focused
        // Global monitors have lower priority, so we need to be more aggressive
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            _ = self?.handleKeyboardShortcut(event)
        }
        
        print("✅ Global keyboard shortcuts setup complete")
        print("🎫 Local monitor: \(localEventMonitor != nil)")
        print("🌍 Global monitor: \(globalEventMonitor != nil)")
        if checkAccessibilityPermissions() {
            print("🔐 Accessibility permissions: ✅ Granted")
        } else {
            print("🔐 Accessibility permissions: ❌ Not granted (configure in Settings)")
        }
    }
    
    private func handleKeyboardShortcut(_ event: NSEvent) -> NSEvent? {
        // Only process keyDown events for shortcuts
        guard event.type == .keyDown else {
            return event
        }
        
        // Debug: Check if app is active
        let isAppActive = NSApp.isActive
        print("🔍 Event received - App active: \(isAppActive)")
        
        let keyCode = Int(event.keyCode)
        let modifierFlags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        
        let expectedKeyCode = keyboardShortcutsSettings.togglePanelShortcut.key.keyCode
        let expectedModifiers = keyboardShortcutsSettings.togglePanelShortcut.modifiers.flags
        
        // Debug logging with more details
        let keyName = keyboardShortcutsSettings.togglePanelShortcut.key.displayName
        let modifierNames = keyboardShortcutsSettings.togglePanelShortcut.modifiers.map { $0.displayName }.joined()
        
        // More detailed debug info
        let currentApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        print("🔍 Key event from '\(currentApp)': keyCode=\(keyCode), modifiers=\(modifierFlags.rawValue), appActive=\(isAppActive)")
        print("🎯 Expected: keyCode=\(expectedKeyCode), modifiers=\(expectedModifiers.rawValue)")
        
        // Check toggle panel shortcut with exact matching
        if keyCode == expectedKeyCode && modifierFlags == expectedModifiers {
            
            print("✅ Toggle panel shortcut matched! (\(modifierNames)\(keyName)) from \(currentApp)")
            
            // Use higher priority dispatch
            DispatchQueue.main.async {
                // Force app to front when toggling
                NSApplication.shared.activate(ignoringOtherApps: true)
                self.toggleHUDExpansion()
            }
            
            return nil // Consume the event to prevent other apps from handling it
        }
        
        // Check next tab shortcut (only when panel is expanded)
        let nextTabKeyCode = keyboardShortcutsSettings.nextTabShortcut.key.keyCode
        let nextTabModifiers = keyboardShortcutsSettings.nextTabShortcut.modifiers.flags
        
        if keyCode == nextTabKeyCode && modifierFlags == nextTabModifiers {
            guard let panel = floatingPanel, panel.expansionState else {
                print("🚫 Next tab shortcut ignored - panel not expanded")
                return event
            }
            
            let nextTabNames = keyboardShortcutsSettings.nextTabShortcut.modifiers.map { $0.displayName }.joined()
            let nextTabKeyName = keyboardShortcutsSettings.nextTabShortcut.key.displayName
            print("✅ Next tab shortcut matched! (\(nextTabNames)\(nextTabKeyName)) from \(currentApp)")
            
            DispatchQueue.main.async {
                NSApplication.shared.activate(ignoringOtherApps: true)
                // Notify HUDView to switch to next tab
                NotificationCenter.default.post(name: .nextTabKeyboardShortcut, object: nil)
            }
            
            return nil // Consume the event
        }

        // Check text selection shortcut
        let textSelectionKeyCode = keyboardShortcutsSettings.textSelectionShortcut.key.keyCode
        let textSelectionModifiers = keyboardShortcutsSettings.textSelectionShortcut.modifiers.flags

        if keyCode == textSelectionKeyCode && modifierFlags == textSelectionModifiers {
            let textSelectionNames = keyboardShortcutsSettings.textSelectionShortcut.modifiers.map { $0.displayName }.joined()
            let textSelectionKeyName = keyboardShortcutsSettings.textSelectionShortcut.key.displayName
            print("✅ Text selection shortcut matched! (\(textSelectionNames)\(textSelectionKeyName)) from \(currentApp)")

            DispatchQueue.main.async {
                self.handleTextSelectionShortcut()
            }

            return nil // Consume the event
        }

        return event // Don't consume the event
    }

    // MARK: - Text Selection Handler

    private func handleTextSelectionShortcut() {
        print("📋 Handling text selection shortcut...")

        // First, copy the selected text using Cmd+C
        let keyCode = UInt16(kVK_ANSI_C)
        guard let copyEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true) else {
            print("❌ Failed to create copy event")
            return
        }

        copyEvent.flags = CGEventFlags.maskCommand
        copyEvent.post(tap: CGEventTapLocation.cghidEventTap)

        guard let copyEventUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: false) else {
            print("❌ Failed to create copy event up")
            return
        }

        copyEventUp.flags = CGEventFlags.maskCommand
        copyEventUp.post(tap: CGEventTapLocation.cghidEventTap)

        // Wait a bit for the copy to complete, then get text from clipboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let pasteboard = NSPasteboard.general
            guard let copiedText = pasteboard.string(forType: .string), !copiedText.isEmpty else {
                print("❌ No text found in clipboard")
                return
            }

            print("📋 Copied text: \"\(copiedText)\"")

            // Send to appropriate input field
            self.pasteTextToActiveInput(copiedText)
        }
    }

    private func pasteTextToActiveInput(_ text: String) {
        // Activate the app and show the HUD if needed
        NSApplication.shared.activate(ignoringOtherApps: true)
        showHUD()

        // Notify the UI components to handle the text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(
                name: .textSelectionReceived,
                object: nil,
                userInfo: ["text": text]
            )
        }
    }

    // MARK: - Accessibility Permissions
    
    private func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
    
    private func requestAccessibilityPermissions() {
        print("🔐 Requesting accessibility permissions...")
        
        // Show alert to user
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "AllyHub needs accessibility permissions to monitor global keyboard shortcuts.\n\nClick 'Open System Settings' to grant permission, then restart AllyHub."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Request permissions and open System Settings
            let options: [String: Any] = ["AXTrustedCheckOptionPrompt": true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            // Open System Settings to Privacy & Security > Accessibility
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // MARK: - Public Methods
    func showHUD() {
        guard let panel = floatingPanel else { return }
        
        print("🎆 Showing HUD with maximum level")
        
        // Force maximum window level
        panel.level = NSWindow.Level(rawValue: 2147483631)
        
        // Make sure the panel appears on all spaces
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Show the panel
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        
        // Double-check the level after showing
        panel.level = NSWindow.Level(rawValue: 2147483631)
        
        print("🎆 HUD shown - level: \(panel.level.rawValue), visible: \(panel.isVisible)")
    }
    
    func hideHUD() {
        guard let panel = floatingPanel else { return }
        
        print("🙈 Hiding HUD")
        panel.orderOut(nil)
        print("🙈 HUD hidden - visible: \(panel.isVisible)")
    }
    
    func toggleHUDExpansion() {
        guard let panel = floatingPanel else { return }
        
        print("🔄 Toggle HUD expansion called - panel visible: \(panel.isVisible), expanded: \(panel.expansionState)")
        
        // Always ensure panel is visible first
        if !panel.isVisible {
            print("👁️ Showing HUD first")
            showHUD()
        }
        
        // Toggle between expanded and compact modes
        print("🔄 Toggling expansion state from \(panel.expansionState) to \(!panel.expansionState)")
        panel.toggleExpansion()
    }
    
    @objc func toggleHUD() {
        guard let panel = floatingPanel else { return }
        
        print("🔄 Toggle HUD called - panel visible: \(panel.isVisible), expanded: \(panel.expansionState)")
        
        // Always ensure panel is visible first
        if !panel.isVisible {
            print("👁️ Showing HUD first")
            showHUD()
        }
        
        // Toggle between expanded and compact modes
        print("🔄 Toggling expansion state")
        panel.toggleExpansion()
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
        
        // Clean up event monitors
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        
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