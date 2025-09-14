import SwiftUI
import AppKit
import Carbon

extension Notification.Name {
    static let nextTabKeyboardShortcut = Notification.Name("nextTabKeyboardShortcut")
}

@MainActor
final class GradientSettings: ObservableObject {
    @Published var selectedGradient: GradientType = .blue
    @Published var expandedOpacity: Double = 0.7  // Default 70%
    @Published var compactBarMode: CompactBarMode = .tasks
    @Published var windowSize: WindowSize = .small
    
    enum WindowSize: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var id: String { rawValue }
        
        var width: CGFloat {
            switch self {
            case .small: return 300
            case .medium: return 360
            case .large: return 420
            }
        }
    }
    
    enum CompactBarMode: String, CaseIterable, Identifiable {
        case tasks = "Tasks"
        case chat = "Chat Input"
        
        var id: String { rawValue }
    }
    
    enum GradientType: String, CaseIterable, Identifiable {
        case blue = "blue"
        case red = "red"
        case green = "green"
        case purple = "purple"
        case orange = "orange"
        case teal = "teal"
        
        var id: String { rawValue }
        
        var name: String {
            switch self {
            case .blue: return "Blue"
            case .red: return "Red"
            case .green: return "Green"
            case .purple: return "Purple"
            case .orange: return "Orange"
            case .teal: return "Teal"
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .blue:
                return LinearGradient(
                    colors: [Color.blue, Color.cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .red:
                return LinearGradient(
                    colors: [Color.red, Color.pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .green:
                return LinearGradient(
                    colors: [Color.green, Color.mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .purple:
                return LinearGradient(
                    colors: [Color.purple, Color.indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .orange:
                return LinearGradient(
                    colors: [Color.orange, Color.yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .teal:
                return LinearGradient(
                    colors: [Color.teal, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        if let savedGradient = UserDefaults.standard.string(forKey: "AllyHub.Gradient"),
           let gradientType = GradientType(rawValue: savedGradient) {
            selectedGradient = gradientType
        }
        
        let savedOpacity = UserDefaults.standard.double(forKey: "AllyHub.ExpandedOpacity")
        if savedOpacity > 0 {
            expandedOpacity = savedOpacity
        }
        
        if let savedMode = UserDefaults.standard.string(forKey: "AllyHub.CompactBarMode"),
           let barMode = CompactBarMode(rawValue: savedMode) {
            compactBarMode = barMode
        }
        
        if let savedWindowSize = UserDefaults.standard.string(forKey: "AllyHub.WindowSize"),
           let windowSizeType = WindowSize(rawValue: savedWindowSize) {
            windowSize = windowSizeType
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(selectedGradient.rawValue, forKey: "AllyHub.Gradient")
        UserDefaults.standard.set(expandedOpacity, forKey: "AllyHub.ExpandedOpacity")
        UserDefaults.standard.set(compactBarMode.rawValue, forKey: "AllyHub.CompactBarMode")
        UserDefaults.standard.set(windowSize.rawValue, forKey: "AllyHub.WindowSize")
    }
    
    func setGradient(_ gradient: GradientType) {
        selectedGradient = gradient
        saveSettings()
    }
    
    func setExpandedOpacity(_ opacity: Double) {
        expandedOpacity = opacity
        saveSettings()
    }
    
    func setCompactBarMode(_ mode: CompactBarMode) {
        compactBarMode = mode
        saveSettings()
    }
    
    func setWindowSize(_ size: WindowSize) {
        windowSize = size
        saveSettings()
        
        // Update floating panel size
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.updateWindowSize()
        }
    }
}

// MARK: - KeyboardShortcutsSettings

extension Set where Element == KeyboardShortcutsSettings.Modifier {
    var flags: NSEvent.ModifierFlags {
        var result: NSEvent.ModifierFlags = []
        for modifier in self {
            result.insert(modifier.flag)
        }
        return result
    }
}

@MainActor
class KeyboardShortcutsSettings: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var togglePanelShortcut: KeyboardShortcut
    @Published var nextTabShortcut: KeyboardShortcut
    
    // MARK: - Initialization
    
    init() {
        // Default shortcuts
        self.togglePanelShortcut = KeyboardShortcut(
            key: .space,
            modifiers: [.command, .option],
            displayName: "⌘⌥Space"
        )
        
        self.nextTabShortcut = KeyboardShortcut(
            key: .tab,
            modifiers: [.command],
            displayName: "⌘Tab"
        )
        
        loadSettings()
    }
    
    // MARK: - Nested Types
    
    struct KeyboardShortcut: Codable, Equatable {
        let key: Key
        let modifiers: Set<Modifier>
        let displayName: String
        
        init(key: Key, modifiers: Set<Modifier>, displayName: String) {
            self.key = key
            self.modifiers = modifiers
            self.displayName = displayName
        }
        
        // Create display string from key and modifiers
        static func createDisplayName(key: Key, modifiers: Set<Modifier>) -> String {
            var parts: [String] = []
            
            if modifiers.contains(.command) { parts.append("⌘") }
            if modifiers.contains(.option) { parts.append("⌥") }
            if modifiers.contains(.control) { parts.append("⌃") }
            if modifiers.contains(.shift) { parts.append("⇧") }
            
            parts.append(key.displayName)
            
            return parts.joined()
        }
    }
    
    enum Key: String, CaseIterable, Codable {
        case space = "Space"
        case tab = "Tab"
        case escape = "Escape"
        case enter = "Enter"
        case f1 = "F1"
        case f2 = "F2"
        case f3 = "F3"
        case f4 = "F4"
        case f5 = "F5"
        case f6 = "F6"
        case f7 = "F7"
        case f8 = "F8"
        case f9 = "F9"
        case f10 = "F10"
        case f11 = "F11"
        case f12 = "F12"
        case a = "A"
        case b = "B"
        case c = "C"
        case d = "D"
        case e = "E"
        case f = "F"
        case g = "G"
        case h = "H"
        case i = "I"
        case j = "J"
        case k = "K"
        case l = "L"
        case m = "M"
        case n = "N"
        case o = "O"
        case p = "P"
        case q = "Q"
        case r = "R"
        case s = "S"
        case t = "T"
        case u = "U"
        case v = "V"
        case w = "W"
        case x = "X"
        case y = "Y"
        case z = "Z"
        case num1 = "1"
        case num2 = "2"
        case num3 = "3"
        case num4 = "4"
        case num5 = "5"
        case num6 = "6"
        case num7 = "7"
        case num8 = "8"
        case num9 = "9"
        case num0 = "0"
        
        var displayName: String {
            switch self {
            case .space: return "Space"
            case .tab: return "Tab"
            case .escape: return "Esc"
            case .enter: return "Enter"
            default: return rawValue
            }
        }
        
        var keyCode: Int {
            switch self {
            case .space: return kVK_Space
            case .tab: return kVK_Tab
            case .escape: return kVK_Escape
            case .enter: return kVK_Return
            case .f1: return kVK_F1
            case .f2: return kVK_F2
            case .f3: return kVK_F3
            case .f4: return kVK_F4
            case .f5: return kVK_F5
            case .f6: return kVK_F6
            case .f7: return kVK_F7
            case .f8: return kVK_F8
            case .f9: return kVK_F9
            case .f10: return kVK_F10
            case .f11: return kVK_F11
            case .f12: return kVK_F12
            case .a: return kVK_ANSI_A
            case .b: return kVK_ANSI_B
            case .c: return kVK_ANSI_C
            case .d: return kVK_ANSI_D
            case .e: return kVK_ANSI_E
            case .f: return kVK_ANSI_F
            case .g: return kVK_ANSI_G
            case .h: return kVK_ANSI_H
            case .i: return kVK_ANSI_I
            case .j: return kVK_ANSI_J
            case .k: return kVK_ANSI_K
            case .l: return kVK_ANSI_L
            case .m: return kVK_ANSI_M
            case .n: return kVK_ANSI_N
            case .o: return kVK_ANSI_O
            case .p: return kVK_ANSI_P
            case .q: return kVK_ANSI_Q
            case .r: return kVK_ANSI_R
            case .s: return kVK_ANSI_S
            case .t: return kVK_ANSI_T
            case .u: return kVK_ANSI_U
            case .v: return kVK_ANSI_V
            case .w: return kVK_ANSI_W
            case .x: return kVK_ANSI_X
            case .y: return kVK_ANSI_Y
            case .z: return kVK_ANSI_Z
            case .num1: return kVK_ANSI_1
            case .num2: return kVK_ANSI_2
            case .num3: return kVK_ANSI_3
            case .num4: return kVK_ANSI_4
            case .num5: return kVK_ANSI_5
            case .num6: return kVK_ANSI_6
            case .num7: return kVK_ANSI_7
            case .num8: return kVK_ANSI_8
            case .num9: return kVK_ANSI_9
            case .num0: return kVK_ANSI_0
            }
        }
    }
    
    enum Modifier: String, CaseIterable, Codable {
        case command = "Command"
        case option = "Option"
        case control = "Control"
        case shift = "Shift"
        
        var displayName: String {
            switch self {
            case .command: return "⌘"
            case .option: return "⌥"
            case .control: return "⌃"
            case .shift: return "⇧"
            }
        }
        
        var flag: NSEvent.ModifierFlags {
            switch self {
            case .command: return .command
            case .option: return .option
            case .control: return .control
            case .shift: return .shift
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    
    private enum UserDefaultsKeys {
        static let togglePanelShortcut = "keyboardShortcuts_togglePanel"
        static let nextTabShortcut = "keyboardShortcuts_nextTab"
    }
    
    // MARK: - Settings Management
    
    func saveSettings() {
        if let togglePanelData = try? JSONEncoder().encode(togglePanelShortcut) {
            UserDefaults.standard.set(togglePanelData, forKey: UserDefaultsKeys.togglePanelShortcut)
        }
        
        if let nextTabData = try? JSONEncoder().encode(nextTabShortcut) {
            UserDefaults.standard.set(nextTabData, forKey: UserDefaultsKeys.nextTabShortcut)
        }
    }
    
    private func loadSettings() {
        if let togglePanelData = UserDefaults.standard.data(forKey: UserDefaultsKeys.togglePanelShortcut),
           let savedTogglePanelShortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: togglePanelData) {
            self.togglePanelShortcut = savedTogglePanelShortcut
        }
        
        if let nextTabData = UserDefaults.standard.data(forKey: UserDefaultsKeys.nextTabShortcut),
           let savedNextTabShortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: nextTabData) {
            self.nextTabShortcut = savedNextTabShortcut
        }
    }
    
    // MARK: - Shortcut Updates
    
    func setTogglePanelShortcut(key: Key, modifiers: Set<Modifier>) {
        let displayName = KeyboardShortcut.createDisplayName(key: key, modifiers: modifiers)
        self.togglePanelShortcut = KeyboardShortcut(key: key, modifiers: modifiers, displayName: displayName)
        saveSettings()
    }
    
    func setNextTabShortcut(key: Key, modifiers: Set<Modifier>) {
        let displayName = KeyboardShortcut.createDisplayName(key: key, modifiers: modifiers)
        self.nextTabShortcut = KeyboardShortcut(key: key, modifiers: modifiers, displayName: displayName)
        saveSettings()
    }
    
    // MARK: - Shortcut Validation
    
    func isShortcutConflicting(key: Key, modifiers: Set<Modifier>, excluding: String? = nil) -> Bool {
        let newShortcut = KeyboardShortcut(key: key, modifiers: modifiers, displayName: "")
        
        if excluding != "togglePanel" && newShortcut.key == togglePanelShortcut.key && newShortcut.modifiers == togglePanelShortcut.modifiers {
            return true
        }
        
        if excluding != "nextTab" && newShortcut.key == nextTabShortcut.key && newShortcut.modifiers == nextTabShortcut.modifiers {
            return true
        }
        
        return false
    }
}

// MARK: - TaskCreationSettings

@MainActor
final class TaskCreationSettings: ObservableObject {
    @Published var floatingPanelDefaultAction: FloatingPanelAction = .microphone
    
    enum FloatingPanelAction: String, CaseIterable, Identifiable {
        case microphone = "microphone"
        case screen = "screen"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .microphone: return "Record Audio"
            case .screen: return "Record Screen"
            }
        }
        
        var iconName: String {
            switch self {
            case .microphone: return "mic.fill"
            case .screen: return "display"
            }
        }
    }
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        if let savedAction = UserDefaults.standard.string(forKey: "AllyHub.FloatingPanelAction"),
           let action = FloatingPanelAction(rawValue: savedAction) {
            floatingPanelDefaultAction = action
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(floatingPanelDefaultAction.rawValue, forKey: "AllyHub.FloatingPanelAction")
    }
    
    func setFloatingPanelAction(_ action: FloatingPanelAction) {
        floatingPanelDefaultAction = action
        saveSettings()
    }
}