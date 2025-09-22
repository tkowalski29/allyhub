import SwiftUI

struct SettingsView: View {
    @ObservedObject var communicationSettings: CommunicationSettings
    @ObservedObject var gradientSettings: GradientSettings
    @ObservedObject var keyboardShortcutsSettings: KeyboardShortcutsSettings
    @ObservedObject var taskCreationSettings: TaskCreationSettings
    
    @State private var chatAccordionExpanded = false
    @State private var tasksAccordionExpanded = false
    @State private var notificationsAccordionExpanded = false
    @State private var actionsAccordionExpanded = false
    @State private var appearanceAccordionExpanded = true
    @State private var keyboardShortcutsAccordionExpanded = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                chatAccordion
                tasksAccordion
                notificationsAccordion
                actionsAccordion
                keyboardShortcutsAccordion
                appearanceAccordion
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.never)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if keyboardShortcutsAccordionExpanded {
                keyboardShortcutsSettingsView
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var keyboardShortcutsSettingsView: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            // Text Selection Shortcut
            keyboardShortcutField(
                title: "Capture Text Selection",
                description: "Copy selected text and paste to chat input",
                shortcut: keyboardShortcutsSettings.textSelectionShortcut,
                onUpdate: { key, modifiers in
                    keyboardShortcutsSettings.setTextSelectionShortcut(key: key, modifiers: modifiers)
                }
            )
        }
    }
    
    @State private var showingAccessibilityAlert = false
    
    private var accessibilityPermissionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14))
                
                Text("Global Shortcuts Permissions")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            
            Text("Accessibility permissions required for global shortcuts.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            
            Button("Open System Preferences") {
                showAccessibilityPreferences()
            }
            .foregroundStyle(.white)
            .font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Color.blue.opacity(0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            HStack(spacing: 8) {
                // Current shortcut display
                Text(shortcut.displayName)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                // Change button with app gradient styling
                Menu("Change") {
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
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Color.blue.opacity(0.6)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if chatAccordionExpanded {
                chatSettingsView
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
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
            
            // URL Collection field (Lista konwersacji)
            chatUrlField(
                title: "Collection URL", 
                placeholder: "Enter URL for chat collections",
                value: $communicationSettings.chatHistoryURL
            )
            
            // URL Get Conversation field (Wiadomości w konwersacji)
            chatUrlField(
                title: "Get Conversation URL",
                placeholder: "Enter URL to get conversation messages",
                value: $communicationSettings.chatGetConversationURL
            )
            
            // URL Create Conversation field (Nowa konwersacja)
            chatUrlField(
                title: "Create Conversation URL",
                placeholder: "Enter URL to create new conversation",
                value: $communicationSettings.chatCreateConversationURL
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if notificationsAccordionExpanded {
                notificationsSettingsView
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
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
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("5 min")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("10 min")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .fontWeight(.medium)
                        Spacer()
                        Text("15 min")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(communicationSettings.notificationsRefreshInterval) },
                            set: { newValue in
                                let roundedValue = Int(round(newValue / 5) * 5) // Round to nearest 5
                                let clampedValue = max(5, min(15, roundedValue)) // Clamp between 5-15
                                communicationSettings.notificationsRefreshInterval = clampedValue
                                communicationSettings.saveSettings()
                            }
                        ),
                        in: 5...15,
                        step: 5
                    )
                    .accentColor(.white)
                }
                .padding(.horizontal, 4)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if actionsAccordionExpanded {
                actionsSettingsView
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if appearanceAccordionExpanded {
                appearanceSettings
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            gradientThemeSection
            transparencySection
            windowSizeSection
            compactBarModeSection
        }
    }
    
    private var gradientThemeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gradient Theme")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(GradientSettings.GradientType.allCases) { gradientType in
                    Button(action: {
                        gradientSettings.setGradient(gradientType)
                    }) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(gradientType.gradient)
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(gradientSettings.selectedGradient == gradientType ? .white : .clear, lineWidth: 2)
                            )
                            .overlay(
                                Text(gradientType.name)
                                    .font(.caption2)
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
            compactBarModeHeader
            compactBarModeDescription
            compactBarModeOptions
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
    
    private var compactBarModeHeader: some View {
        HStack {
            Image(systemName: "menubar.dock.rectangle")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("Compact Bar Display")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
    
    private var compactBarModeDescription: some View {
        Text("Choose what appears when the floating panel is minimized")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var compactBarModeOptions: some View {
        HStack(spacing: 16) {
            ForEach(GradientSettings.CompactBarMode.allCases) { mode in
                compactBarModeButton(mode: mode)
            }
            Spacer()
        }
    }
    
    private func compactBarModeButton(mode: GradientSettings.CompactBarMode) -> some View {
        let isSelected = gradientSettings.compactBarMode == mode
        
        return Button(action: {
            gradientSettings.setCompactBarMode(mode)
        }) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                
                Image(systemName: mode.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                Text(mode.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? 
                         Color.blue.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(gradientSettings.compactBarMode == mode ? 
                                   Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var windowSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.resize")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text("Window Size")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(gradientSettings.windowSize.rawValue) (\(Int(gradientSettings.windowSize.width))px)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Small")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("Medium")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                    Spacer()
                    Text("Large")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Slider(
                    value: Binding(
                        get: { 
                            switch gradientSettings.windowSize {
                            case .small: return 0
                            case .medium: return 1
                            case .large: return 2
                            }
                        },
                        set: { newValue in
                            let roundedValue = Int(round(newValue))
                            let size: GradientSettings.WindowSize
                            switch roundedValue {
                            case 0: size = .small
                            case 2: size = .large
                            default: size = .medium
                            }
                            gradientSettings.setWindowSize(size)
                        }
                    ),
                    in: 0...2,
                    step: 1
                )
                .accentColor(.white)
            }
            .padding(.horizontal, 4)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if tasksAccordionExpanded {
                tasksSettingsView
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var tasksSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            tasksUrlFields
            tasksRefreshIntervalSection
            floatingPanelActionSection
        }
    }
    
    private var tasksUrlFields: some View {
        Group {
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
    
    private var tasksRefreshIntervalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text("Auto Refresh Interval")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(communicationSettings.tasksRefreshInterval) min")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("5 min")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("10 min")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                    Spacer()
                    Text("15 min")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Slider(
                    value: Binding(
                        get: { Double(communicationSettings.tasksRefreshInterval) },
                        set: { newValue in
                            let roundedValue = Int(round(newValue / 5) * 5)
                            let clampedValue = max(5, min(15, roundedValue))
                            communicationSettings.tasksRefreshInterval = clampedValue
                            communicationSettings.saveSettings()
                        }
                    ),
                    in: 5...15,
                    step: 5
                )
                .accentColor(.white)
            }
            .padding(.horizontal, 4)
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
    
    private var floatingPanelActionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            floatingPanelHeader
            floatingPanelDescription
            floatingPanelOptions
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
    
    private var floatingPanelHeader: some View {
        HStack {
            Image(systemName: "plus.rectangle.on.rectangle")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("Floating Panel + Button")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
    
    private var floatingPanelDescription: some View {
        Text("Choose what happens when you click the + button in the floating panel")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var floatingPanelOptions: some View {
        HStack(spacing: 16) {
            ForEach(TaskCreationSettings.FloatingPanelAction.allCases, id: \.self) { action in
                floatingPanelActionButton(action: action)
            }
            Spacer()
        }
    }
    
    private func floatingPanelActionButton(action: TaskCreationSettings.FloatingPanelAction) -> some View {
        let isSelected = taskCreationSettings.floatingPanelDefaultAction == action
        
        return Button(action: {
            taskCreationSettings.setFloatingPanelAction(action)
        }) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                
                Image(systemName: action.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                Text(action.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? 
                         Color.blue.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(taskCreationSettings.floatingPanelDefaultAction == action ? 
                                   Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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