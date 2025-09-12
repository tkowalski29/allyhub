import Cocoa
import SwiftUI

final class FloatingPanel: NSPanel {
    // MARK: - Properties
    private let timerModel: TimerModel
    private let tasksModel: TasksModel
    private let gradientSettings: GradientSettings
    private let communicationSettings: CommunicationSettings
    private var hostingView: NSHostingView<HUDView>?
    private let compactSize = NSSize(width: 300, height: 44)  // Same width as expanded
    private let expandedWidth: CGFloat = 300
    private var expandedSize: NSSize {
        let screenHeight = NSScreen.main?.frame.height ?? 800
        let menuBarHeight: CGFloat = 24  // Standard macOS menu bar height
        return NSSize(width: expandedWidth, height: screenHeight - menuBarHeight)
    }
    private var isExpanded = false
    private var isOnLeftSide = false
    
    weak var appDelegate: AppDelegate?
    
    // MARK: - Initialization
    init(timerModel: TimerModel, tasksModel: TasksModel, gradientSettings: GradientSettings, communicationSettings: CommunicationSettings) {
        self.timerModel = timerModel
        self.tasksModel = tasksModel
        self.gradientSettings = gradientSettings
        self.communicationSettings = communicationSettings
        
        // Initialize panel with compact size
        super.init(
            contentRect: NSRect(origin: .zero, size: compactSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupPanel()
        setupContent()
    }
    
    // MARK: - Panel Setup
    private func setupPanel() {
        // Configure panel behavior
        level = NSWindow.Level(rawValue: 2147483631)  // Maximum possible window level
        isOpaque = false
        hasShadow = true
        backgroundColor = .clear
        
        // Enable dragging
        isMovableByWindowBackground = true
        
        // Configure for floating behavior
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Set up autosave for position persistence
        setFrameAutosaveName("AllyHubPanel")
        
        // Configure animation
        animationBehavior = .default
        
        // Enable text field focus in non-activating panel
        acceptsMouseMovedEvents = true
        
        // Handle window close - use NSWindowDelegate instead of custom protocol
        delegate = self
    }
    
    private func setupContent() {
        // Create SwiftUI hosting view
        let hudView = HUDView(
            timerModel: timerModel,
            tasksModel: tasksModel,
            gradientSettings: gradientSettings,
            communicationSettings: communicationSettings,
            isExpanded: isExpanded,
            isOnLeftSide: isOnLeftSide,
            onExpand: { [weak self] in
                self?.toggleExpansion()
            },
            onClose: { [weak self] in
                self?.handleClose()
            }
        )
        
        hostingView = NSHostingView(rootView: hudView)
        
        guard let hostingView = hostingView else { return }
        
        hostingView.frame = NSRect(origin: .zero, size: compactSize)
        hostingView.autoresizingMask = [.width, .height]
        
        // Configure hosting view
        hostingView.layer?.cornerRadius = 12
        hostingView.layer?.masksToBounds = true
        
        contentView = hostingView
        
        // Set initial position if no saved position exists
        if !setFrameUsingName("AllyHubPanel") {
            center()
        }
    }
    
    // MARK: - Animation and Layout
    func toggleExpansion(animated: Bool = true) {
        isExpanded.toggle()
        
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let currentFrame = frame
        
        let newSize = isExpanded ? expandedSize : compactSize
        var newFrame: NSRect
        
        if isExpanded {
            // When expanding, snap to edge and full height (minus menu bar)
            isOnLeftSide = currentFrame.midX < screenFrame.midX
            let menuBarHeight: CGFloat = 24  // Standard macOS menu bar height
            let availableHeight = screenFrame.height - menuBarHeight
            
            if isOnLeftSide {
                // Snap to left edge, full available height
                newFrame = NSRect(
                    x: 0,
                    y: 0,
                    width: expandedWidth,
                    height: availableHeight
                )
            } else {
                // Snap to right edge, full available height
                newFrame = NSRect(
                    x: screenFrame.width - expandedWidth,
                    y: 0,
                    width: expandedWidth,
                    height: availableHeight
                )
            }
        } else {
            // When collapsing, return to compact size at same position
            newFrame = NSRect(
                x: currentFrame.origin.x,
                y: currentFrame.origin.y - (newSize.height - currentFrame.height),
                width: newSize.width,
                height: newSize.height
            )
        }
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                animator().setFrame(newFrame, display: true)
            }
        } else {
            setFrame(newFrame, display: true)
        }
        
        // Update the hosting view
        updateHostingViewForExpansion()
    }
    
    private func updateHostingViewForExpansion() {
        guard let hostingView = hostingView else { return }
        
        // Update the SwiftUI view to reflect expansion state
        let hudView = HUDView(
            timerModel: timerModel,
            tasksModel: tasksModel,
            gradientSettings: gradientSettings,
            communicationSettings: communicationSettings,
            isExpanded: isExpanded,
            isOnLeftSide: isOnLeftSide,
            onExpand: { [weak self] in
                self?.toggleExpansion()
            },
            onClose: { [weak self] in
                self?.handleClose()
            }
        )
        
        hostingView.rootView = hudView
    }
    
    // MARK: - Window Management
    override func makeKeyAndOrderFront(_ sender: Any?) {
        // Force maximum window level BEFORE showing
        level = NSWindow.Level(rawValue: 2147483631)  // Maximum possible window level
        super.makeKeyAndOrderFront(sender)
        
        // Force level again AFTER showing (sometimes macOS resets it)
        level = NSWindow.Level(rawValue: 2147483631)
        
        // Ensure panel appears on current space
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Force to front with highest priority
        orderFrontRegardless()
    }
    
    override func orderOut(_ sender: Any?) {
        super.orderOut(sender)
        // Notify app delegate directly instead of using protocol
        if let appDelegate = appDelegate {
            Task { @MainActor in
                appDelegate.hideHUD()
            }
        }
    }
    
    override func setFrameOrigin(_ point: NSPoint) {
        super.setFrameOrigin(point)
        // No need to notify for simple move events
    }
    
    // MARK: - Key Window Override
    override var canBecomeKey: Bool {
        return true  // Allow TextField focus in non-activating panel
    }
    
    // MARK: - Event Handling
    override func mouseDown(with event: NSEvent) {
        // Enable dragging
        super.mouseDown(with: event)
    }
    
    override func keyDown(with event: NSEvent) {
        // Handle keyboard shortcuts
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "w":
                handleClose()
                return
            case " ":
                timerModel.toggle()
                return
            case "n":
                tasksModel.nextTask()
                return
            case "e":
                toggleExpansion()
                return
            default:
                break
            }
        }
        
        super.keyDown(with: event)
    }
    
    // MARK: - Actions
    private func handleClose() {
        orderOut(nil)
    }
    
    // MARK: - Accessibility
    override func accessibilityLabel() -> String? {
        return "AllyHub Timer Panel"
    }
    
    override func accessibilityRole() -> NSAccessibility.Role? {
        return .window
    }
    
    override func accessibilityHelp() -> String? {
        return "Floating timer and task panel. Drag to move, use keyboard shortcuts to control."
    }
}

// MARK: - NSWindowDelegate
extension FloatingPanel: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Notify app delegate directly
        if let appDelegate = appDelegate {
            Task { @MainActor in
                appDelegate.hideHUD()
            }
        }
    }
    
    func windowDidMove(_ notification: Notification) {
        // Panel position is automatically saved by NSPanel's autosave functionality
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Always allow closing
        return true
    }
}

// MARK: - Panel State Management
extension FloatingPanel {
    var currentSize: NSSize {
        return frame.size
    }
    
    var isCompact: Bool {
        return !isExpanded
    }
    
    func setExpanded(_ expanded: Bool, animated: Bool = true) {
        guard expanded != isExpanded else { return }
        toggleExpansion(animated: animated)
    }
    
    func resetToCompactSize(animated: Bool = true) {
        if isExpanded {
            toggleExpansion(animated: animated)
        }
    }
}