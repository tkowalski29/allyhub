import SwiftUI

struct HUDView: View {
    // MARK: - Properties
    @ObservedObject var timerModel: TimerModel
    @ObservedObject var tasksModel: TasksModel
    @ObservedObject var gradientSettings: GradientSettings
    @ObservedObject var communicationSettings: CommunicationSettings
    
    let isExpanded: Bool
    let isOnLeftSide: Bool
    let onExpand: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    @State private var selectedTab: ExpandedTab = .tasks
    @State private var appearanceAccordionExpanded = true
    @State private var communicationAccordionExpanded = false
    @State private var chatAccordionExpanded = true
    @State private var conversationsAccordionExpanded = false
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
    @State private var notifications: [NotificationItem] = [
        NotificationItem(title: "Timer Completed", message: "Your 25-minute focus session is complete!", type: .info, isRead: false),
        NotificationItem(title: "New Task Available", message: "A new task has been assigned to you: 'Review API documentation'", type: .success, isRead: true),
        NotificationItem(title: "Break Reminder", message: "Time for a 5-minute break to recharge!", type: .warning, isRead: false),
        NotificationItem(title: "Daily Summary", message: "You completed 3 out of 5 tasks today. Great progress!", type: .success, isRead: true),
        NotificationItem(title: "System Update", message: "AllyHub has been updated to version 2.1.0", type: .info, isRead: false)
    ]
    
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
    
    struct NotificationItem: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
        let type: NotificationType
        var isRead: Bool
        let timestamp = Date()
        
        init(title: String, message: String, type: NotificationType, isRead: Bool) {
            self.title = title
            self.message = message
            self.type = type
            self.isRead = isRead
        }
    }
    
    enum NotificationType: String, CaseIterable {
        case info = "info"
        case success = "success"
        case warning = "warning"
        case error = "error"
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .success: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
    
    enum ExpandedTab: String, CaseIterable {
        case chat = "Chat"
        case tasks = "Tasks"
        case notifications = "Notifications"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .chat: return "message"
            case .tasks: return "checklist"
            case .notifications: return "bell"
            case .settings: return "gearshape"
            }
        }
    }
    
    // MARK: - Initialization
    init(
        timerModel: TimerModel,
        tasksModel: TasksModel,
        gradientSettings: GradientSettings,
        communicationSettings: CommunicationSettings,
        isExpanded: Bool = false,
        isOnLeftSide: Bool = false,
        onExpand: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.timerModel = timerModel
        self.tasksModel = tasksModel
        self.gradientSettings = gradientSettings
        self.communicationSettings = communicationSettings
        self.isExpanded = isExpanded
        self.isOnLeftSide = isOnLeftSide
        self.onExpand = onExpand
        self.onClose = onClose
    }
    
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
        .frame(width: 300, height: isExpanded ? nil : 44)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
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
        HStack(spacing: 12) {
            if isHovering {
                // Show icons when hovering
                hoverControls
                    .transition(.scale.combined(with: .opacity))
            } else {
                // Show different content based on compact bar mode
                if gradientSettings.compactBarMode == .tasks {
                    // Show task and time when not hovering
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
                    .transition(.scale.combined(with: .opacity))
                    
                    Spacer(minLength: 0)
                } else {
                    // Show chat input when in chat mode
                    chatInputBar
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
    
    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(spacing: 16) {
            // Control buttons positioned based on panel side
            HStack {
                if isOnLeftSide {
                    // Left side: buttons on left
                    Group {
                        // Collapse button
                        Button(action: onExpand) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        // Close button
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
                    
                    Spacer()
                } else {
                    // Right side: buttons on right
                    Spacer()
                    
                    Group {
                        // Collapse button
                        Button(action: onExpand) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        // Close button
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
            }
            
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
    
    
    private var timerTaskSection: some View {
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
        .padding(.vertical, 8)
    }
    
    private var tabContentView: some View {
        TabView(selection: $selectedTab) {
            chatTabView
                .tag(ExpandedTab.chat)
            
            tasksTabView
                .tag(ExpandedTab.tasks)
            
            notificationsTabView
                .tag(ExpandedTab.notifications)
            
            settingsTabView
                .tag(ExpandedTab.settings)
        }
        .tabViewStyle(.automatic)
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
        VStack(alignment: .leading, spacing: 16) {
            timerTaskSection
            allTasksList
            Spacer()
        }
        .padding(12)
    }
    
    private var allTasksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Tasks")
                .font(.headline)
                .foregroundStyle(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(tasksModel.tasks.enumerated()), id: \.offset) { index, task in
                    taskRow(task: task, index: index)
                }
            }
        }
    }
    
    private func taskRow(task: TasksModel.Task, index: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Current task indicator
                    if index == tasksModel.currentTaskIndex {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                // Status
                Text(index == tasksModel.currentTaskIndex ? "Active" : (task.isCompleted ? "Completed" : "Pending"))
                    .font(.system(size: 12))
                    .foregroundStyle(index == tasksModel.currentTaskIndex ? .blue : 
                                   (task.isCompleted ? .green : .white.opacity(0.7)))
            }
            
            Spacer()
            
            // Action buttons
            taskActionButtons(task: task, index: index)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(index == tasksModel.currentTaskIndex ? 
                   Color.blue.opacity(0.1) : Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func taskActionButtons(task: TasksModel.Task, index: Int) -> some View {
        HStack(spacing: 8) {
            // Switch to active button
            if index != tasksModel.currentTaskIndex {
                Button(action: {
                    tasksModel.goToTask(at: index)
                }) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            
            // Toggle completion
            Button(action: {
                if index == tasksModel.currentTaskIndex {
                    tasksModel.toggleCurrentTaskCompletion()
                } else {
                    // Toggle completion for non-current tasks
                    tasksModel.tasks[index].isCompleted.toggle()
                    tasksModel.saveTasks()
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isCompleted ? .green : .white.opacity(0.7))
            }
            .buttonStyle(.plain)
            
            // Preview/Details button
            Button(action: {
                // TODO: Show task details
                print("Show details for: \(task.title)")
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var notificationsTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with unread count
                notificationsHeader
                
                // Notifications list
                notificationsList
                
                if notifications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.4))
                        Text("No notifications")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
    }
    
    private var notificationsHeader: some View {
        HStack {
            Text("Notifications")
                .font(.headline)
                .foregroundStyle(.white)
            
            Spacer()
            
            let unreadCount = notifications.filter { !$0.isRead }.count
            if unreadCount > 0 {
                Text("\(unreadCount) unread")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(12)
            }
        }
    }
    
    private var notificationsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(notifications.enumerated()), id: \.offset) { index, notification in
                notificationRow(notification: notification, index: index)
            }
        }
    }
    
    private func notificationRow(notification: NotificationItem, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Type icon
            Image(systemName: notification.type.icon)
                .font(.system(size: 16))
                .foregroundStyle(notification.type.color)
                .frame(width: 20)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(notification.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Action buttons
            notificationActions(notification: notification, index: index)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(notificationBackground(for: notification))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(notification.isRead ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func notificationActions(notification: NotificationItem, index: Int) -> some View {
        VStack(spacing: 4) {
            // Mark as read/unread button
            Button(action: {
                notifications[index].isRead.toggle()
            }) {
                Image(systemName: notification.isRead ? "envelope.open" : "envelope.badge")
                    .font(.system(size: 14))
                    .foregroundStyle(notification.isRead ? .white.opacity(0.7) : .blue)
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button(action: {
                deleteNotification(at: index)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }
    
    private func notificationBackground(for notification: NotificationItem) -> Color {
        notification.isRead ? Color.white.opacity(0.02) : Color.blue.opacity(0.1)
    }
    
    private func deleteNotification(at index: Int) {
        withAnimation(.easeOut(duration: 0.2)) {
            notifications.remove(at: index)
        }
    }
    
    // MARK: - Settings Tab View (broken into smaller components)
    private var settingsTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                appearanceAccordion
                communicationAccordion
            }
            .padding()
        }
    }
    
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
                    Text("100%")
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
    
    private var communicationAccordion: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    communicationAccordionExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "network")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Text("Communication")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: communicationAccordionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if communicationAccordionExpanded {
                communicationSettingsView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.slide.combined(with: .opacity))
            }
        }
    }
    
    private var communicationSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            urlConfigurationField(
                title: "Tasks Fetch URL",
                placeholder: "Enter URL to fetch tasks",
                value: $communicationSettings.tasksFetchURL
            )
            
            urlConfigurationField(
                title: "Task Update URL",
                placeholder: "Enter URL to update task status",
                value: $communicationSettings.taskUpdateURL
            )
            
            urlConfigurationField(
                title: "Chat History URL",
                placeholder: "Enter URL to fetch chat history",
                value: $communicationSettings.chatHistoryURL
            )
            
            urlConfigurationField(
                title: "Chat Stream URL",
                placeholder: "Enter URL for chat streaming",
                value: $communicationSettings.chatStreamURL
            )
            
            urlConfigurationField(
                title: "Notifications Fetch URL",
                placeholder: "Enter URL to fetch notifications",
                value: $communicationSettings.notificationsFetchURL
            )
            
            urlConfigurationField(
                title: "Notification Status URL",
                placeholder: "Enter URL to update notification status",
                value: $communicationSettings.notificationStatusURL
            )
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
                .onSubmit {
                    communicationSettings.saveSettings()
                }
        }
    }
    
    private var bottomTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ExpandedTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 60)
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
            
            // Close button
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
}