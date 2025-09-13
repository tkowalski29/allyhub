import SwiftUI

struct SettingsView: View {
    @ObservedObject var communicationSettings: CommunicationSettings
    @ObservedObject var gradientSettings: GradientSettings
    @ObservedObject var keyboardShortcutsSettings: KeyboardShortcutsSettings
    
    @State private var chatAccordionExpanded = false
    @State private var tasksAccordionExpanded = false
    @State private var notificationsAccordionExpanded = false
    @State private var actionsAccordionExpanded = false
    @State private var appearanceAccordionExpanded = true
    @State private var keyboardShortcutsAccordionExpanded = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                chatAccordion
                tasksAccordion
                notificationsAccordion
                actionsAccordion
                keyboardShortcutsAccordion
                appearanceAccordion
            }
            .padding()
        }
    }
    
    // MARK: - Keyboard Shortcuts Accordion
    
    private var keyboardShortcutsAccordion: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardShortcutsAccordionExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Text("Keyboard Shortcuts")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: keyboardShortcutsAccordionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if keyboardShortcutsAccordionExpanded {
                keyboardShortcutsSettingsView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var keyboardShortcutsSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Accessibility permissions notice
            accessibilityPermissionsView
            
            // Toggle Panel Shortcut
            keyboardShortcutField(
                title: "Toggle Panel",
                description: "Expand/collapse the floating panel",
                shortcut: keyboardShortcutsSettings.togglePanelShortcut,
                onUpdate: { key, modifiers in
                    keyboardShortcutsSettings.setTogglePanelShortcut(key: key, modifiers: modifiers)
                }
            )
            
            // Next Tab Shortcut
            keyboardShortcutField(
                title: "Next Tab",
                description: "Switch to the next tab in expanded view",
                shortcut: keyboardShortcutsSettings.nextTabShortcut,
                onUpdate: { key, modifiers in
                    keyboardShortcutsSettings.setNextTabShortcut(key: key, modifiers: modifiers)
                }
            )
        }
    }
    
    @State private var showingAccessibilityAlert = false
    
    private var accessibilityPermissionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.system(size: 16))
                
                Text("Global Shortcuts Permissions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            
            Text("For global keyboard shortcuts to work, AllyHub needs Accessibility permissions.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            
            Button("Open System Preferences") {
                showAccessibilityPreferences()
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.7), Color.orange.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .alert("Accessibility Permissions Required", isPresented: $showingAccessibilityAlert) {
            Button("Open System Preferences") {
                showAccessibilityPreferences()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To enable global keyboard shortcuts, please:\n\n1. Open System Preferences > Privacy & Security > Accessibility\n2. Find AllyHub in the list\n3. Toggle it ON\n4. Restart AllyHub")
        }
    }
    
    private func showAccessibilityPreferences() {
        // Try to open System Preferences directly to Accessibility
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func keyboardShortcutField(
        title: String,
        description: String,
        shortcut: KeyboardShortcutsSettings.KeyboardShortcut,
        onUpdate: @escaping (KeyboardShortcutsSettings.Key, Set<KeyboardShortcutsSettings.Modifier>) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                // Current shortcut display
                Text(shortcut.displayName)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Change button with Execute button styling
                Menu("Change Shortcut") {
                    // Modifier combinations
                    ForEach(modifierCombinations, id: \.self) { modifiers in
                        Menu(modifierDisplayName(modifiers)) {
                            ForEach(commonKeys, id: \.self) { key in
                                Button("\(modifierDisplayName(modifiers))\(key.displayName)") {
                                    onUpdate(key, modifiers)
                                }
                            }
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // Helper computed properties for keyboard shortcuts
    private var modifierCombinations: [Set<KeyboardShortcutsSettings.Modifier>] {
        [
            [.command],
            [.option],
            [.control],
            [.command, .option],
            [.command, .shift],
            [.command, .control],
            [.option, .shift],
            [.control, .shift],
            [.command, .option, .shift]
        ]
    }
    
    private var commonKeys: [KeyboardShortcutsSettings.Key] {
        [
            .space, .tab, .escape, .enter,
            .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12,
            .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m,
            .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z,
            .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9, .num0
        ]
    }
    
    private func modifierDisplayName(_ modifiers: Set<KeyboardShortcutsSettings.Modifier>) -> String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        return parts.joined()
    }
    
    // MARK: - Chat Accordion
    
    private var chatAccordion: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    chatAccordionExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "message")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Text("Chat")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: chatAccordionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if chatAccordionExpanded {
                chatSettingsView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var chatSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Enable Stream toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Stream")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    
                    Text("Enable real-time chat streaming")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                Toggle("", isOn: $communicationSettings.chatEnableStream)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .scaleEffect(0.8)
                    .onChange(of: communicationSettings.chatEnableStream) { _ in
                        communicationSettings.saveSettings()
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // URL Message field
            chatUrlField(
                title: "Message URL",
                placeholder: "Enter URL for chat messages",
                value: $communicationSettings.chatMessageURL
            )
            
            // URL Collection field
            chatUrlField(
                title: "Collection URL", 
                placeholder: "Enter URL for chat collections",
                value: $communicationSettings.chatCollectionURL
            )
        }
    }
    
    // MARK: - Notifications Accordion
    
    private var notificationsAccordion: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    notificationsAccordionExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "bell")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Text("Notifications")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: notificationsAccordionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if notificationsAccordionExpanded {
                notificationsSettingsView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var notificationsSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Refresh interval setting
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("Auto Refresh Interval")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("\(communicationSettings.notificationsRefreshInterval) min")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 8) {
                    // 5 min button
                    Button("5 min") {
                        communicationSettings.notificationsRefreshInterval = 5
                        communicationSettings.saveSettings()
                    }
                    .buttonStyle(RefreshIntervalButtonStyle(isSelected: communicationSettings.notificationsRefreshInterval == 5))
                    
                    // 10 min button  
                    Button("10 min") {
                        communicationSettings.notificationsRefreshInterval = 10
                        communicationSettings.saveSettings()
                    }
                    .buttonStyle(RefreshIntervalButtonStyle(isSelected: communicationSettings.notificationsRefreshInterval == 10))
                    
                    // 15 min button
                    Button("15 min") {
                        communicationSettings.notificationsRefreshInterval = 15
                        communicationSettings.saveSettings()
                    }
                    .buttonStyle(RefreshIntervalButtonStyle(isSelected: communicationSettings.notificationsRefreshInterval == 15))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Notifications Fetch URL
            chatUrlField(
                title: "Fetch URL",
                placeholder: "Enter URL to fetch notifications",
                value: $communicationSettings.notificationsFetchURL
            )
            
            // Notification Status URL
            chatUrlField(
                title: "Status URL",
                placeholder: "Enter URL to update notification status",
                value: $communicationSettings.notificationStatusURL
            )
        }
    }
    
    // MARK: - Actions Accordion
    
    private var actionsAccordion: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    actionsAccordionExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "bolt")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Text("Actions")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: actionsAccordionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if actionsAccordionExpanded {
                actionsSettingsView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var actionsSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Actions Fetch URL
            chatUrlField(
                title: "Actions Fetch URL",
                placeholder: "Enter URL to fetch actions",
                value: $communicationSettings.actionsFetchURL
            )
        }
    }
    
    // MARK: - Appearance Accordion
    
    private var appearanceAccordion: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appearanceAccordionExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Text("Appearance")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: appearanceAccordionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if appearanceAccordionExpanded {
                appearanceSettings
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            gradientThemeSection
            transparencySection
            windowSizeSection
            compactBarModeSection
        }
    }
    
    private var gradientThemeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gradient Theme")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(GradientSettings.GradientType.allCases) { gradientType in
                    Button(action: {
                        gradientSettings.setGradient(gradientType)
                    }) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(gradientType.gradient)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(gradientSettings.selectedGradient == gradientType ? .white : .clear, lineWidth: 2)
                            )
                            .overlay(
                                Text(gradientType.name)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .fontWeight(.medium)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var transparencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expanded View Transparency")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Transparency:")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(gradientSettings.expandedOpacity * 100))%")
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                }
                
                Slider(value: Binding(
                    get: { gradientSettings.expandedOpacity },
                    set: { newValue in
                        gradientSettings.setExpandedOpacity(newValue)
                    }
                ), in: 0.3...1.0, step: 0.05)
                .accentColor(.white)
                
                HStack {
                    Text("30%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("95%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var compactBarModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compact Bar Display")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(GradientSettings.CompactBarMode.allCases) { mode in
                    Button(action: {
                        gradientSettings.setCompactBarMode(mode)
                    }) {
                        HStack {
                            Image(systemName: gradientSettings.compactBarMode == mode ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(.white)
                            Text(mode.rawValue)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var windowSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Window Size")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(GradientSettings.WindowSize.allCases) { size in
                    Button(action: {
                        gradientSettings.setWindowSize(size)
                    }) {
                        HStack {
                            Image(systemName: gradientSettings.windowSize == size ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(.white)
                            Text(size.rawValue)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(size.width))px")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Tasks Accordion
    
    private var tasksAccordion: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    tasksAccordionExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Text("Tasks")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: tasksAccordionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if tasksAccordionExpanded {
                tasksSettingsView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var tasksSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            chatUrlField(
                title: "Fetch URL",
                placeholder: "Enter URL to fetch tasks",
                value: $communicationSettings.tasksFetchURL
            )
            
            chatUrlField(
                title: "Update URL", 
                placeholder: "Enter URL to update task status",
                value: $communicationSettings.taskUpdateURL
            )
            
            chatUrlField(
                title: "Create URL",
                placeholder: "Enter URL to create new tasks",
                value: $communicationSettings.taskCreateURL
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func chatUrlField(title: String, placeholder: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            TextField(placeholder, text: value)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focusable(true)
                .onSubmit {
                    communicationSettings.saveSettings()
                }
                .onChange(of: value.wrappedValue) { _ in
                    communicationSettings.saveSettings()
                }
        }
    }
    
    private func urlConfigurationField(title: String, placeholder: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            TextField(placeholder, text: value)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
                .focusable(true)
                .onSubmit {
                    communicationSettings.saveSettings()
                }
                .onChange(of: value.wrappedValue) { _ in
                    communicationSettings.saveSettings()
                }
        }
    }
}

// MARK: - Button Styles

struct RefreshIntervalButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}