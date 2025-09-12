import SwiftUI

@main
struct AllyHubApp: App {
    // Use AppDelegate for NSApplication lifecycle management
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Since this is a menu bar app with LSUIElement = true,
        // we don't need to define any WindowGroups
        // All UI is managed through NSStatusItem and NSPanel in AppDelegate
        Settings {
            EmptyView()
        }
    }
}

// MARK: - Empty Settings View
// This is required to satisfy SwiftUI App protocol
// but won't be shown since we're a menu bar only app
private struct EmptyView: View {
    var body: some View {
        VStack {
            Text("AllyHub")
                .font(.title)
            Text("Smart Assistant Hub")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(width: 300, height: 200)
    }
}