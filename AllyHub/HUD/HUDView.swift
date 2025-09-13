import SwiftUI

struct HUDView: View {
    // MARK: - Properties
    @ObservedObject var timerModel: TimerModel
    @ObservedObject var tasksModel: TasksModel
    @ObservedObject var gradientSettings: GradientSettings
    @ObservedObject var communicationSettings: CommunicationSettings
    @ObservedObject var keyboardShortcutsSettings: KeyboardShortcutsSettings
    
    let isExpanded: Bool
    let isOnLeftSide: Bool
    let onExpand: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    @State private var isRightSectionHovering = false
    @State private var isChatInputFocused = false
    @State private var selectedTab: ExpandedTab = .tasks
    @State private var chatTabChatAccordionExpanded = true
    @State private var conversationsAccordionExpanded = false
    @State private var chatAccordionExpanded = true
    @State private var chatInputText = ""
    @State private var chatMessages: [ChatMessage] = [
        ChatMessage(content: "Hello! How can I help you today?", isUser: false),
        ChatMessage(content: "Hi! I need help with my tasks.", isUser: true),
        ChatMessage(content: "I'd be happy to help you manage your tasks. What would you like to know?", isUser: false)
    ]
    @State private var conversations: [Conversation] = [
        Conversation(title: "Task Management Help", lastMessage: "I'd be happy to help you manage your tasks. What would you like to know?"),
        Conversation(title: "Project Planning", lastMessage: "Let's plan your next project step by step."),
        Conversation(title: "Daily Standup", lastMessage: "What are you working on today?")
    ]
    @State private var currentConversationId: UUID?
    @StateObject private var notificationsManager: NotificationsManager
    @StateObject private var tasksManager: TasksManager
    @StateObject private var actionsManager: ActionsManager
    @State private var isRefreshing = false
    @State private var isRefreshButtonAnimating = false
    @State private var notificationsRefreshTimer: Timer?
    
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp = Date()
    }
    
    struct Conversation: Identifiable, Equatable {
        let id: UUID
        var title: String
        var lastMessage: String
        var lastUpdated = Date()
        
        init(title: String, lastMessage: String) {
            self.id = UUID()
            self.title = title
            self.lastMessage = lastMessage
        }
    }
    
    // MARK: - Initializer
    
    init(timerModel: TimerModel, 
         tasksModel: TasksModel, 
         gradientSettings: GradientSettings, 
         communicationSettings: CommunicationSettings,
         keyboardShortcutsSettings: KeyboardShortcutsSettings,
         isExpanded: Bool,
         isOnLeftSide: Bool,
         onExpand: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.timerModel = timerModel
        self.tasksModel = tasksModel
        self.gradientSettings = gradientSettings
        self.communicationSettings = communicationSettings
        self.keyboardShortcutsSettings = keyboardShortcutsSettings
        self.isExpanded = isExpanded
        self.isOnLeftSide = isOnLeftSide
        self.onExpand = onExpand
        self.onClose = onClose
        self._notificationsManager = StateObject(wrappedValue: NotificationsManager(communicationSettings: communicationSettings))
        self._tasksManager = StateObject(wrappedValue: TasksManager(communicationSettings: communicationSettings))
        self._actionsManager = StateObject(wrappedValue: ActionsManager(communicationSettings: communicationSettings))
    }
    
    enum ExpandedTab: String, CaseIterable {
        case chat = "Chat"
        case tasks = "Tasks"
        case notifications = "Notifications"
        case actions = "Actions"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .chat: return "message"
            case .tasks: return "checklist"
            case .notifications: return "bell"
            case .actions: return "bolt"
            case .settings: return "gearshape"
            }
        }
    }
    
    // MARK: - Initialization
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background with gradient or solid
            backgroundView
            
            // Main content
            if isExpanded {
                expandedView
            } else {
                compactView
            }
        }
        .frame(width: gradientSettings.windowSize.width, height: isExpanded ? nil : 44)
        .onAppear {
            startNotificationRefreshTimer()
            // Fetch notifications immediately when view appears
            refreshNotifications()
            // Fetch tasks when view appears
            tasksManager.fetchTasks()
            // Fetch actions when view appears
            actionsManager.fetchActions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextTabKeyboardShortcut)) { _ in
            nextTab()
        }
        .onDisappear {
            stopNotificationRefreshTimer()
        }
        .onChange(of: communicationSettings.notificationsRefreshInterval) { _ in
            restartNotificationRefreshTimer()
        }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                gradientSettings.selectedGradient.gradient
                    .opacity(backgroundOpacity)
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var backgroundOpacity: Double {
        if isExpanded {
            return isHovering ? 1.0 : gradientSettings.expandedOpacity  // 100% on hover, user setting normally
        } else {
            return isHovering ? 0.9 : 0.3  // 90% on hover, 30% normally for compact
        }
    }
    
    // MARK: - Compact View
    private var compactView: some View {
        HStack(spacing: 0) {
            // Left section (50%) - Always content, never covered by hover
            HStack {
                if gradientSettings.compactBarMode == .tasks {
                    // Show task and time in tasks mode
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tasksModel.currentTaskTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text(timerModel.formattedTime)
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }
                } else {
                    // Show chat input when in chat mode - full width of left section
                    TextField("Type a message...", text: $chatInputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .onTapGesture {
                            isChatInputFocused = true
                            isRightSectionHovering = false
                        }
                        .onSubmit {
                            if !chatInputText.isEmpty {
                                chatMessages.append(ChatMessage(content: chatInputText, isUser: true))
                                chatInputText = ""
                            }
                            isChatInputFocused = false
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            
            // Right section (50%) - Hover area + notification badge
            HStack {
                Spacer()
                
                if isRightSectionHovering && !isChatInputFocused {
                    // Hover controls (only expand and next task)
                    HStack(spacing: 8) {
                        // Expand button
                        Button(action: onExpand) {
                            Image(systemName: isExpanded ? "chevron.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        // Next Task button
                        Button(action: { tasksModel.nextTask() }) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Show notification badge when not hovering
                    if notificationsManager.unreadNotificationsCount > 0 {
                        Text("\(notificationsManager.unreadNotificationsCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 18, height: 18)
                            .background(Color.orange)
                            .clipShape(Circle())
                    } else {
                        // Invisible placeholder to maintain hover area when no notifications
                        Color.clear
                            .frame(width: 18, height: 18)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRightSectionHovering = hovering && !isChatInputFocused
                }
            }
        }
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isRightSectionHovering)
        .animation(.easeInOut(duration: 0.2), value: isChatInputFocused)
    }
    
    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(spacing: 16) {
            // New header layout: collapse | tab name | notification count | refresh | close
            HStack(spacing: 12) {
                // 1. Collapse button (left)
                Button(action: onExpand) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // 2. Tab name
                Text(selectedTab.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                // 3. Notification count (orange badge) - only on Notifications tab when there are unread notifications
                if selectedTab == .notifications && notificationsManager.unreadNotificationsCount > 0 {
                    Text("\(notificationsManager.unreadNotificationsCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
                
                // 4. Add Task button - for Tasks tab only
                if selectedTab == .tasks {
                    Button(action: {
                        // TODO: Add new task functionality
                        print("Add new task button pressed")
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // 5. Refresh button - for Notifications, Actions, and Tasks tabs
                if selectedTab == .notifications || selectedTab == .actions || selectedTab == .tasks {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isRefreshButtonAnimating = true
                        }
                        
                        if selectedTab == .notifications {
                            notificationsManager.fetchNotifications()
                        } else if selectedTab == .actions {
                            actionsManager.fetchActions()
                        } else if selectedTab == .tasks {
                            tasksManager.fetchTasks()
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRefreshButtonAnimating = false
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                            .rotationEffect(.degrees(isRefreshButtonAnimating ? 360 : 0))
                    }
                    .buttonStyle(.plain)
                }
                
                // 5. Close button - only on Settings tab
                if selectedTab == .settings {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Tab view content
            tabContentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom tab selector
            bottomTabSelector
        }
        .padding(16)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    
    
    private var tabContentView: some View {
        // Temporary replacement for TabView to test if TabView is blocking interactions
        Group {
            switch selectedTab {
            case .chat:
                chatTabView
            case .tasks:
                tasksTabView
            case .notifications:
                notificationsTabView
            case .actions:
                actionsTabView
            case .settings:
                SettingsView(
                    communicationSettings: communicationSettings,
                    gradientSettings: gradientSettings,
                    keyboardShortcutsSettings: keyboardShortcutsSettings
                )
            }
        }
    }
    
    private var chatTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Chat Accordion
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
                        chatInterface
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .transition(.slide.combined(with: .opacity))
                    }
                }
                
                // Conversations Accordion
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            conversationsAccordionExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                            
                            Text("Conversations")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Image(systemName: conversationsAccordionExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    if conversationsAccordionExpanded {
                        conversationsInterface
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .transition(.slide.combined(with: .opacity))
                    }
                }
            }
            .padding(12)
        }
    }
    
    // MARK: - Chat Interfaces
    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Chat messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chatMessages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    chatBubble(message: message, isUser: true)
                                } else {
                                    chatBubble(message: message, isUser: false)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: chatMessages.count) { _ in
                    if let lastMessage = chatMessages.last {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(height: 300)
            
            // Input area at bottom
            VStack(spacing: 0) {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                HStack(spacing: 12) {
                    TextField("Type your message...", text: $chatInputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .lineLimit(1...4)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                       Color.gray.opacity(0.3) : Color.blue.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
        }
    }
    
    private var conversationsInterface: some View {
        VStack(alignment: .leading, spacing: 12) {
            // New conversation button
            Button(action: startNewConversation) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                    Text("Start New Conversation")
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Conversations list
            LazyVStack(spacing: 8) {
                ForEach(conversations) { conversation in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conversation.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(conversation.lastMessage)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        Spacer()
                        
                        Button(action: {
                            loadConversation(conversation)
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func startNewConversation() {
        let newConversation = Conversation(title: "New Conversation", lastMessage: "")
        conversations.insert(newConversation, at: 0)
        currentConversationId = newConversation.id
        chatMessages.removeAll()
        chatMessages.append(ChatMessage(content: "Hello! How can I help you with your new conversation?", isUser: false))
        
        // Switch to chat accordion and close conversations
        chatAccordionExpanded = true
        conversationsAccordionExpanded = false
    }
    
    private func loadConversation(_ conversation: Conversation) {
        currentConversationId = conversation.id
        // In a real app, you would load the conversation messages from storage
        chatMessages.removeAll()
        chatMessages.append(ChatMessage(content: "Loading conversation: \(conversation.title)", isUser: false))
        
        // Switch to chat accordion
        chatAccordionExpanded = true
        conversationsAccordionExpanded = false
    }
    
    private func chatBubble(message: ChatMessage, isUser: Bool) -> some View {
        Text(message.content)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isUser ? Color.blue.opacity(0.7) : Color.white.opacity(0.2))
            .cornerRadius(16)
            .frame(maxWidth: 250, alignment: isUser ? .trailing : .leading)
    }
    
    private func sendMessage() {
        let messageText = chatInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        // Add user message
        chatMessages.append(ChatMessage(content: messageText, isUser: true))
        chatInputText = ""
        
        // Simulate AI response after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let responses = [
                "I understand. Let me help you with that.",
                "That's interesting! Can you tell me more?",
                "I'm here to assist you with your tasks and questions.",
                "Great question! Here's what I think..."
            ]
            if let randomResponse = responses.randomElement() {
                chatMessages.append(ChatMessage(content: randomResponse, isUser: false))
            }
        }
    }
    
    // MARK: - Tasks Tab View (broken into smaller components)
    private var tasksTabView: some View {
        VStack(spacing: 0) {
            // Timer and current task section at top
            VStack(spacing: 8) {
                Text(tasksModel.currentTaskTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(timerModel.formattedTime)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            
            // Tasks collection using new TasksView
            TasksView(tasksManager: tasksManager)
        }
    }
    
    private var notificationsTabView: some View {
        VStack(spacing: 0) {
            if notificationsManager.notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: communicationSettings.notificationsFetchURL.isEmpty ? "bell.slash" : "bell")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    VStack(spacing: 4) {
                        Text(communicationSettings.notificationsFetchURL.isEmpty ? "No notifications configured" : "No notifications")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text(communicationSettings.notificationsFetchURL.isEmpty ? "Configure notifications URL in Settings" : "Pull to refresh or wait for updates")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    if !communicationSettings.notificationsFetchURL.isEmpty {
                        Button("Refresh now") {
                            refreshNotifications()
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.blue.opacity(0.8))
                        .disabled(isRefreshing)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            } else {
                NotificationsView(
                    notifications: $notificationsManager.notifications,
                    unreadNotificationsCount: $notificationsManager.unreadNotificationsCount,
                    expandedNotificationId: $notificationsManager.expandedNotificationId,
                    communicationSettings: communicationSettings,
                    onRefresh: refreshNotifications
                )
            }
        }
    }
    
    private var actionsTabView: some View {
        VStack(spacing: 0) {
            if actionsManager.actions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: communicationSettings.actionsFetchURL.isEmpty ? "bolt.slash" : "bolt")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    VStack(spacing: 4) {
                        Text(communicationSettings.actionsFetchURL.isEmpty ? "No actions configured" : "No actions")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text(communicationSettings.actionsFetchURL.isEmpty ? "Configure actions URL in Settings" : "Pull to refresh or wait for updates")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    if !communicationSettings.actionsFetchURL.isEmpty {
                        Button("Refresh now") {
                            actionsManager.fetchActions()
                        }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.blue.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            } else {
                ActionsView(
                    actionsManager: actionsManager
                )
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    private var bottomTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ExpandedTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    ZStack {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.6))
                        
                        // Badge for notifications tab
                        if tab == .notifications && notificationsManager.unreadNotificationsCount > 0 {
                            Text("\(notificationsManager.unreadNotificationsCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .offset(x: 10, y: -8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 44)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Chat Input Bar
    private var chatInputBar: some View {
        HStack(spacing: 8) {
            TextField("Type message...", text: $chatInputText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
                .onSubmit {
                    if !chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Handle chat message send
                        print("Sending chat message: \(chatInputText)")
                        chatInputText = ""
                    }
                }
            
            Button(action: {
                if !chatInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("Sending chat message: \(chatInputText)")
                    chatInputText = ""
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Hover Controls
    private var hoverControls: some View {
        HStack(spacing: 8) {
            // Expand button
            Button(action: onExpand) {
                Image(systemName: isExpanded ? "chevron.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Next Task button
            Button(action: { tasksModel.nextTask() }) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Timer control button
            Button(action: { timerModel.toggle() }) {
                Image(systemName: timerModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Notifications Refresh Logic
    private func refreshNotifications() {
        isRefreshing = true
        notificationsManager.fetchNotifications()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
        }
    }
    
    private func refreshTasks() {
        isRefreshing = true
        tasksManager.fetchTasks()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
        }
    }
    
    
    
    private func startNotificationRefreshTimer() {
        stopNotificationRefreshTimer()
        
        let interval = TimeInterval(communicationSettings.notificationsRefreshInterval * 60) // Convert minutes to seconds
        
        notificationsRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                refreshNotifications()
            }
        }
    }
    
    private func stopNotificationRefreshTimer() {
        notificationsRefreshTimer?.invalidate()
        notificationsRefreshTimer = nil
    }
    
    private func restartNotificationRefreshTimer() {
        startNotificationRefreshTimer()
    }
    
    private func updateNotificationStatus(notificationId: String, isRead: Bool?, action: String? = nil) {
        guard !communicationSettings.notificationStatusURL.isEmpty else {
            print("Notification status URL not configured")
            return
        }
        
        guard let url = URL(string: communicationSettings.notificationStatusURL) else {
            print("Invalid notification status URL")
            return
        }
        
        // Create POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Create POST body according to documentation
        let actionValue: String
        if let customAction = action {
            actionValue = customAction
        } else if let isRead = isRead {
            // Direct logic: send the action that the hover icon represents
            actionValue = isRead ? "read" : "unread"
        } else {
            actionValue = "remove" // Default fallback
        }
        
        print("Sending API request: notification \(notificationId) action '\(actionValue)'")
        
        let requestBody: [String: Any] = [
            "id": notificationId,
            "action": actionValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to encode notification status request: \(error)")
            return
        }
        
        // Perform API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to update notification status: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Notification status updated successfully: \(actionValue)")
                    } else {
                        print("Failed to update notification status. Status code: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Keyboard Shortcuts
    
    private func nextTab() {
        guard isExpanded else { return }
        
        let allTabs = ExpandedTab.allCases
        if let currentIndex = allTabs.firstIndex(of: selectedTab) {
            let nextIndex = (currentIndex + 1) % allTabs.count
            selectedTab = allTabs[nextIndex]
        }
    }
}


