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
            // Use system symbol icon only (no title/text)
            button.title = ""
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "AllyHub")
            button.image?.isTemplate = true  // This makes it white in menu bar
            button.toolTip = "AllyHub - Smart Assistant Hub"
            print("🔧 Button configured with icon only")
            
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
        
        // Show/Hide - minimalizuje/wznawia aplikację
        let showHideItem = NSMenuItem(
            title: "Show",
            action: #selector(toggleHUD),
            keyEquivalent: "h"
        )
        showHideItem.target = self
        showHideMenuItem = showHideItem
        menu?.addItem(showHideItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Close - zamyka aplikację całkowicie
        let closeItem = NSMenuItem(
            title: "Close",
            action: #selector(closeApp),
            keyEquivalent: "q"
        )
        closeItem.target = self
        menu?.addItem(closeItem)
        
        statusItem?.menu = menu
    }
    
    private func observeModels() {
        // No longer observing models for simplified menu bar
        // App visibility changes will be handled directly in toggleHUD
    }
    
    // MARK: - Status Item Updates
    private func updateStatusItemAppearance() {
        guard let button = statusItem?.button else { return }
        
        // Keep the icon simple and always white
        button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "AllyHub")
        button.image?.isTemplate = true
        
        // Update tooltip with current time
        let timeRemaining = timerModel.formattedTime
        let status = timerModel.isRunning ? "Running" : timerModel.isPaused ? "Paused" : "Stopped"
        button.toolTip = "AllyHub - \(timeRemaining) (\(status))"
        
        // Keep icon white (template image automatically adapts to menu bar)
        button.contentTintColor = nil
    }
    
    // Removed updateMenuItems - no longer needed for simplified menu
    
    // MARK: - Actions
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        print("🖱️ Status item clicked!")
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click - show menu
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
        } else {
            // Left click - toggle HUD expansion (not minimize/show)
            delegate?.statusBarControllerDidRequestToggleHUD(self)
        }
    }
    
    @objc private func toggleHUD() {
        // This is called from the menu item - toggle between minimizing and restoring the app
        if NSApp.isHidden {
            print("👁️ Restoring app from hidden state")
            NSApp.activate(ignoringOtherApps: true)
            NSApp.unhide(nil)
            showHideMenuItem?.title = "Hide"
        } else {
            print("🙈 Hiding/minimizing app")
            NSApp.hide(nil)
            showHideMenuItem?.title = "Show"
        }
    }
    
    @objc private func closeApp() {
        print("🚪 Closing AllyHub application")
        NSApp.terminate(nil)
    }
    
    // Removed timer and task actions - simplified to show/hide + close
    
    private func updateShowHideMenuItem() {
        // Update menu item based on app visibility state
        showHideMenuItem?.title = NSApp.isHidden ? "Show" : "Hide"
    }
}

// MARK: - Public Interface
extension StatusBarController {
    func updateHUDVisibility(_ isVisible: Bool) {
        // Update menu item based on app visibility
        showHideMenuItem?.title = isVisible ? "Hide" : "Show"
    }
    
    func updateAppVisibilityState() {
        // Called when app becomes active/inactive to update menu item
        updateShowHideMenuItem()
    }
}