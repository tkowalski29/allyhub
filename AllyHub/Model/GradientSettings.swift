import SwiftUI
import AppKit

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