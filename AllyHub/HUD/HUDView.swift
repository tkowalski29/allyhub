import SwiftUI
import AVFoundation

struct HUDView: View {
    // MARK: - Properties
    @ObservedObject var timerModel: TimerModel
    @ObservedObject var tasksModel: TasksModel
    @ObservedObject var gradientSettings: GradientSettings
    @ObservedObject var communicationSettings: CommunicationSettings
    @ObservedObject var keyboardShortcutsSettings: KeyboardShortcutsSettings
    @ObservedObject var taskCreationSettings: TaskCreationSettings
    
    let isExpanded: Bool
    let isOnLeftSide: Bool
    let onExpand: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    @State private var isRightSectionHovering = false
    @State private var isChatInputFocused = false
    @State private var selectedTab: ExpandedTab = .tasks
    @State private var showingTaskCreationOptions = false
    @State private var showingChatCreationOptions = false
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var notificationsManager: NotificationsManager
    @StateObject private var tasksManager: TasksManager
    @StateObject private var actionsManager: ActionsManager
    @AppStorage("activeTaskId") private var activeTaskId: String?
    @AppStorage("activeConversationId") private var activeConversationId: String?
    @State private var isRefreshing = false
    @State private var isRefreshButtonAnimating = false
    @State private var notificationsRefreshTimer: Timer?
    @State private var showingQuickAudioRecorder = false
    @State private var showingQuickScreenRecorder = false
    @State private var chatMessage: String = ""
    @State private var isSendingChatMessage = false
    @State private var lastChatResponse: String?
    @State private var showingTaskList = false
    
    // Inline recording state
    @State private var showingInlineAudioRecorder = false
    @StateObject private var inlineAudioManager = AudioRecorderManager()
    @StateObject private var inlineUploadService = FileUploadService()
    @State private var inlineTaskTitle: String = ""
    @State private var inlineTaskDescription: String = ""
    @State private var inlineAudioTaskSubmitted = false
    
    // Inline screen recording state
    @State private var showingInlineScreenRecorder = false
    @StateObject private var inlineScreenUploadService = FileUploadService()
    @State private var inlineScreenTaskSubmitted = false
    @State private var inlineScreenManager: ScreenRecorderManager?
    
    
    // MARK: - Initializer
    
    init(timerModel: TimerModel, 
         tasksModel: TasksModel, 
         gradientSettings: GradientSettings, 
         communicationSettings: CommunicationSettings,
         keyboardShortcutsSettings: KeyboardShortcutsSettings,
         taskCreationSettings: TaskCreationSettings,
         isExpanded: Bool,
         isOnLeftSide: Bool,
         onExpand: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.timerModel = timerModel
        self.tasksModel = tasksModel
        self.gradientSettings = gradientSettings
        self.communicationSettings = communicationSettings
        self.keyboardShortcutsSettings = keyboardShortcutsSettings
        self.taskCreationSettings = taskCreationSettings
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
        ZStack(alignment: .topLeading) {
            // Main panel content with all inline interfaces
            VStack(spacing: 0) {
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
                
                // Inline recording interface (shown below compact view)
                if showingInlineAudioRecorder && !isExpanded {
                    inlineRecordingView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Inline screen recording interface (shown below compact view)
                if showingInlineScreenRecorder && !isExpanded {
                    if #available(macOS 12.3, *) {
                        inlineScreenRecordingView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        // Fallback for older macOS
                        Text("Screen recording requires macOS 12.3+")
                            .foregroundStyle(.orange)
                            .padding()
                    }
                }
            }
            
            // Chat response box positioned absolutely below the panel
            if !isExpanded && gradientSettings.compactBarMode == .chat && lastChatResponse != nil {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 44) // Height of compact view
                    chatResponseBox
                        .frame(width: gradientSettings.windowSize.width)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Task list positioned absolutely below the panel (for tasks mode)
            if !isExpanded && gradientSettings.compactBarMode == .tasks && showingTaskList {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 44) // Height of compact view
                    taskListBox
                        .frame(width: gradientSettings.windowSize.width)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            startNotificationRefreshTimer()
            // Fetch notifications immediately when view appears
            refreshNotifications()
            // Fetch tasks when view appears
            tasksManager.fetchTasks()
            // Fetch actions when view appears
            actionsManager.fetchActions()
        }
        .sheet(isPresented: $showingQuickAudioRecorder) {
            AudioRecorderView(onTaskCreated: { task in
                addQuickTaskToSystem(task)
            }, communicationSettings: communicationSettings)
        }
        .sheet(isPresented: $showingQuickScreenRecorder) {
            if #available(macOS 12.3, *) {
                ScreenRecorderView(onTaskCreated: { task in
                    addQuickTaskToSystem(task)
                }, communicationSettings: communicationSettings)
            } else {
                ScreenRecorderFallbackView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextTabKeyboardShortcut)) { _ in
            nextTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .textSelectionReceived)) { notification in
            if let userInfo = notification.userInfo,
               let text = userInfo["text"] as? String {
                handleTextSelectionReceived(text)
            }
        }
        .onDisappear {
            stopNotificationRefreshTimer()
        }
        .onChange(of: communicationSettings.notificationsRefreshInterval) { _ in
            restartNotificationRefreshTimer()
        }
        .onChange(of: selectedTab) { newTab in
            // Auto-load active conversation when switching to Chat tab
            if newTab == .chat && isExpanded {
                loadActiveConversationIfNeeded()
            }
        }
        .onChange(of: isExpanded) { expanded in
            // Auto-load active conversation when expanding to Chat tab
            if expanded && selectedTab == .chat {
                loadActiveConversationIfNeeded()
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
    
    // MARK: - Computed Properties
    private var activeTask: TaskItem? {
        guard let activeTaskId = activeTaskId else { return nil }
        return tasksManager.tasks.first { $0.id == activeTaskId }
    }
    
    // MARK: - Timer Actions
    private func handleQuickTaskCreation() {
        switch taskCreationSettings.floatingPanelDefaultAction {
        case .microphone:
            showingInlineAudioRecorder = true
            // Start recording immediately
            inlineAudioTaskSubmitted = false // Reset flag for new recording
            inlineAudioManager.startRecording()
        case .screen:
            // Initialize screen manager if needed (macOS 12.3+)
            if #available(macOS 12.3, *) {
                if inlineScreenManager == nil {
                    inlineScreenManager = ScreenRecorderManager()
                }
                showingInlineScreenRecorder = true
                // Start screen recording immediately
                inlineScreenTaskSubmitted = false // Reset flag for new recording
                inlineScreenManager?.startRecording()
            } else {
                // Fallback for older macOS - use sheet
                showingQuickScreenRecorder = true
            }
        }
    }
    
    private func addQuickTaskToSystem(_ task: TaskItem) {
        // Add task to tasks manager
        tasksManager.tasks.append(task)
        
        // Set as active task if it's the first one
        if tasksManager.tasks.count == 1 {
            activeTaskId = task.id
        }
        
        print("✅ Quick task created: \(task.title)")
    }
    
    private func startTimer() {
        print("🟢 startTimer() called")
        timerModel.start()
        sendTimerAction(action: "start")
    }
    
    private func stopTimer() {
        print("🔴 stopTimer() called")
        timerModel.pause()
        sendTimerAction(action: "stop")
    }
    
    private func sendTimerAction(action: String) {
        print("📤 sendTimerAction() called with action: \(action)")
        print("📤 taskUpdateURL: \(communicationSettings.taskUpdateURL)")
        print("📤 actionsManager available: true")
        print("📤 activeTask: \(activeTask?.title ?? "nil")")
        
        // Get current date for start action, elapsed time for stop action
        let currentDate = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let timestampValue: String
        
        if action == "start" {
            // For start: use current date and timestamp
            timestampValue = dateFormatter.string(from: currentDate)
        } else {
            // For stop: use current date but timestamp should reflect elapsed time
            let elapsedSeconds = timerModel.elapsedTime
            let elapsedDate = Date(timeIntervalSince1970: elapsedSeconds)
            timestampValue = dateFormatter.string(from: elapsedDate)
        }
        
        // Create timer action with all required fields
        let timerAction = ActionItem(
            id: "timer_\(action)_\(UUID().uuidString)",
            title: "Timer \(action.capitalized)",
            message: "Timer action: \(action) for task: \(activeTask?.title ?? "No active task")",
            url: communicationSettings.taskUpdateURL,
            method: "POST",
            parameters: [
                "id": ActionParameter(type: "string", placeholder: "Task ID"),
                "action": ActionParameter(type: "string", placeholder: "Timer action"),
                "task_name": ActionParameter(type: "string", placeholder: "Task name"),
                "data": ActionParameter(type: "string", placeholder: "Timer data"),
                "timestamp": ActionParameter(type: "string", placeholder: "Timestamp")
            ]
        )
        
        // Execute the action with all required parameters
        let parameters: [String: ActionParameterValue] = [
            "id": .string(activeTask?.apiId ?? activeTask?.id ?? "no_id"),
            "action": .string(action),
            "task_name": .string(activeTask?.title ?? "No active task"),
            "data": .string(timerModel.formattedTime),
            "timestamp": .string(timestampValue)
        ]
        
        print("📤 About to execute action: \(timerAction.title)")
        print("📤 Parameters: id=\(activeTask?.apiId ?? activeTask?.id ?? "no_id"), action=\(action), data=\(timerModel.formattedTime), timestamp=\(timestampValue)")
        actionsManager.executeAction(timerAction, parameters: parameters)
        print("📤 Action executed")
    }
    
    // MARK: - Compact View
    private var compactView: some View {
        HStack(spacing: 0) {
            // Left section (50%) - Always content, never covered by hover
            HStack {
                if gradientSettings.compactBarMode == .tasks {
                    // Show active task and time when timer is running
                    VStack(alignment: .leading, spacing: 1) {
                        Text(activeTask?.title ?? "No active task")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        if timerModel.isRunning {
                            Text(timerModel.formattedTime)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                        } else {
                            Text("Stopped")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                } else {
                    // Chat mode - show conversation status and messages
                    VStack(alignment: .leading, spacing: 2) {
                        if let activeConversationId = activeConversationId {
                            if isSendingChatMessage {
                                Text("Sending...")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                ZStack(alignment: .leading) {
                                    if chatMessage.isEmpty {
                                        Text("Type message...")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.9))
                                            .allowsHitTesting(false)
                                    }
                                    
                                    TextField("", text: $chatMessage)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .background(Color.clear)
                                        .onSubmit {
                                            sendChatMessage()
                                        }
                                }
                            }
                        } else {
                            Text("No active conversation")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            
                            TextField("Select conversation first", text: $chatMessage)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                                .disabled(true)
                                .onSubmit {
                                    showNoConversationError()
                                }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            
            // Right section (50%) - Hover area + notification badge
            HStack {
                Spacer()
                
                if isRightSectionHovering && !isChatInputFocused {
                    // Hover controls (expand, timer, and task creation)
                    HStack(spacing: 4) {
                        // Expand button
                        Button(action: onExpand) {
                            Image(systemName: isExpanded ? "chevron.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        // Start/Stop Timer button (hide in chat mode)
                        if gradientSettings.compactBarMode == .tasks {
                            Button(action: {
                                if timerModel.isRunning {
                                    stopTimer()
                                } else {
                                    startTimer()
                                }
                            }) {
                                Image(systemName: timerModel.isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            // Task list button (only in tasks mode)
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingTaskList.toggle()
                                }
                            }) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.blue.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Quick task creation button (configurable action)
                        Button(action: {
                            handleQuickTaskCreation()
                        }) {
                            Image(systemName: taskCreationSettings.floatingPanelDefaultAction.iconName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(taskCreationSettings.floatingPanelDefaultAction == .microphone ? Color.orange.opacity(0.6) : Color.purple.opacity(0.6))
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
            HStack(spacing: 8) {
                // 1. Collapse button (left)
                Button(action: onExpand) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.15))
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
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingTaskCreationOptions.toggle()
                        }
                    }) {
                        Image(systemName: showingTaskCreationOptions ? "xmark" : "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background((showingTaskCreationOptions ? Color.red : Color.blue).opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // 4. Add Conversation button - for Chat tab only
                if selectedTab == .chat {
                    Button(action: {
                        chatViewModel.triggerNewConversation()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // 5. Refresh button - for Chat, Notifications, Actions, and Tasks tabs
                if selectedTab == .chat || selectedTab == .notifications || selectedTab == .actions || selectedTab == .tasks {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isRefreshButtonAnimating = true
                        }
                        
                        if selectedTab == .chat {
                            chatViewModel.triggerRefresh()
                        } else if selectedTab == .notifications {
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
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                            .rotationEffect(.degrees(isRefreshButtonAnimating ? 360 : 0))
                    }
                    .buttonStyle(.plain)
                }
                
                // 5. Close button - only on Settings tab
                if selectedTab == .settings {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.15))
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
                    keyboardShortcutsSettings: keyboardShortcutsSettings,
                    taskCreationSettings: taskCreationSettings
                )
            }
        }
    }
    
    private var chatTabView: some View {
        ChatView(communicationSettings: communicationSettings, viewModel: chatViewModel)
    }
    
    // MARK: - Tasks Tab View (broken into smaller components)
    private var tasksTabView: some View {
        TasksView(tasksManager: tasksManager, tasksModel: tasksModel, timerModel: timerModel, actionsManager: actionsManager, communicationSettings: communicationSettings, taskCreationSettings: taskCreationSettings, showingTaskCreationOptions: $showingTaskCreationOptions)
    }
    
    private var notificationsTabView: some View {
        VStack(spacing: 0) {
            if notificationsManager.notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: communicationSettings.notificationFetchURL.isEmpty ? "bell.slash" : "bell")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    VStack(spacing: 4) {
                        Text(communicationSettings.notificationFetchURL.isEmpty ? "No notifications configured" : "No notifications")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text(communicationSettings.notificationFetchURL.isEmpty ? "Configure notifications URL in Settings" : "Pull to refresh or wait for updates")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
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
                    Image(systemName: communicationSettings.actionFetchURL.isEmpty ? "bolt.slash" : "bolt")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    VStack(spacing: 4) {
                        Text(communicationSettings.actionFetchURL.isEmpty ? "No actions configured" : "No actions")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text(communicationSettings.actionFetchURL.isEmpty ? "Configure actions URL in Settings" : "Pull to refresh or wait for updates")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
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
        guard !communicationSettings.notificationUpdateURL.isEmpty else {
            print("Notification status URL not configured")
            return
        }
        
        guard let url = URL(string: communicationSettings.notificationUpdateURL) else {
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
    
    // MARK: - Inline Recording View
    
    private var inlineRecordingView: some View {
        VStack(spacing: 12) {
            // Recording status and visualization
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Recording status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .opacity(inlineAudioManager.isRecording ? 1 : 0.3)
                            .scaleEffect(inlineAudioManager.isRecording ? 1.2 : 1.0)
                            .animation(
                                inlineAudioManager.isRecording ? 
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : 
                                .easeInOut(duration: 0.2), 
                                value: inlineAudioManager.isRecording
                            )
                        
                        Text(inlineAudioManager.isRecording ? "Recording..." : "Processing...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    // Timer display
                    Text(formatTime(inlineAudioManager.recordingTime))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    
                    // Stop recording button (only show stop when recording)
                    if inlineAudioManager.isRecording {
                        Button(action: {
                            inlineAudioManager.stopRecording()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Close button
                    Button(action: {
                        if inlineAudioManager.isRecording {
                            inlineAudioManager.stopRecording()
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingInlineAudioRecorder = false
                            inlineAudioTaskSubmitted = false // Reset flag
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                
                // Audio level visualization (only when recording)
                if inlineAudioManager.isRecording {
                    HStack(spacing: 2) {
                        ForEach(0..<15, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(inlineAudioManager.audioLevels > Float(index) / 15.0 ? .orange : .white.opacity(0.3))
                                .frame(width: 4, height: CGFloat(8 + index * 1))
                        }
                    }
                }
                
                // Transcription status
                if inlineAudioManager.isTranscribing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        
                        Text("Transcribing audio...")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else if !inlineAudioManager.transcription.isEmpty {
                    Text(inlineAudioManager.transcription)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                
                // Error message
                if let error = inlineAudioManager.errorMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: inlineAudioManager.isRecording)
        .onReceive(inlineAudioManager.$transcription) { transcription in
            // Auto-submit task when transcription is ready and not already submitted
            if !transcription.isEmpty && !inlineAudioTaskSubmitted && !inlineAudioManager.isTranscribing {
                Task {
                    await submitInlineAudioTask()
                }
            }
        }
    }
    
    // MARK: - Inline Audio Task Submission
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func submitInlineAudioTask() async {
        guard !inlineAudioTaskSubmitted,
              let audioURL = inlineAudioManager.recordingURL else {
            return
        }
        
        inlineAudioTaskSubmitted = true
        
        // Create task with transcription as title and description
        let taskTitle = inlineAudioManager.transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        let taskDescription = "Audio task recorded on \(Date().formatted(date: .abbreviated, time: .shortened))"
        
        // Create upload metadata using the same structure as AudioRecorderView
        let metadata = AudioUploadMetadata(
            title: taskTitle,
            description: taskDescription,
            transcription: inlineAudioManager.transcription.isEmpty ? nil : inlineAudioManager.transcription,
            duration: inlineAudioManager.recordingTime
        )
        
        // Get upload endpoint from CommunicationSettings
        let uploadEndpoint = communicationSettings.taskCreateURL
        
        // Use FileUploadService for consistent multipart/form-data upload
        let result = await inlineUploadService.uploadAudioRecording(
            from: audioURL,
            to: uploadEndpoint,
            withMetadata: metadata
        )
        
        await MainActor.run {
            if result.isSuccess {
                // Create local task for immediate UI update
                let task = TaskItem(
                    title: taskTitle,
                    description: taskDescription,
                    status: .todo,
                    priority: .medium,
                    isCompleted: false,
                    createdAt: Date(),
                    creationType: .microphone,
                    audioUrl: audioURL.path,
                    transcription: inlineAudioManager.transcription
                )
                
                // Add to tasks manager
                addQuickTaskToSystem(task)
                
                // Close inline recorder
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingInlineAudioRecorder = false
                }
                
                print("✅ Inline audio task submitted successfully via FileUploadService")
            } else {
                print("❌ Failed to submit inline audio task: \(result.error ?? "Unknown error")")
                inlineAudioManager.errorMessage = result.error
            }
        }
    }
    
    // MARK: - Inline Screen Recording View
    
    @available(macOS 12.3, *)
    private var inlineScreenRecordingView: some View {
        VStack(spacing: 12) {
            // Recording status and visualization
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Recording status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .opacity((inlineScreenManager?.isRecording ?? false) ? 1 : 0.3)
                            .scaleEffect((inlineScreenManager?.isRecording ?? false) ? 1.2 : 1.0)
                            .animation(
                                (inlineScreenManager?.isRecording ?? false) ? 
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : 
                                .easeInOut(duration: 0.2), 
                                value: inlineScreenManager?.isRecording ?? false
                            )
                        
                        Text((inlineScreenManager?.isRecording ?? false) ? "Recording screen..." : "Processing...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    // Timer display
                    Text(formatTime(inlineScreenManager?.recordingTime ?? 0))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    
                    // Stop recording button (only show stop when recording)
                    if inlineScreenManager?.isRecording ?? false {
                        Button(action: {
                            inlineScreenManager?.stopRecording()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Close button
                    Button(action: {
                        if inlineScreenManager?.isRecording ?? false {
                            inlineScreenManager?.stopRecording()
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingInlineScreenRecorder = false
                            inlineScreenTaskSubmitted = false // Reset flag
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                
                // Recording mode indicator
                HStack(spacing: 8) {
                    Image(systemName: "display")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    
                    Text(inlineScreenManager?.recordingMode.displayName ?? "Screen")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Spacer()
                    
                    // Recording quality indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        
                        Text("1080p")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }
                
                // Error message
                if let error = inlineScreenManager?.errorMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: inlineScreenManager?.isRecording ?? false)
        .onReceive(NotificationCenter.default.publisher(for: .screenRecordingFinished)) { _ in
            // Auto-submit task when screen recording finishes
            if !inlineScreenTaskSubmitted {
                Task {
                    await submitInlineScreenTask()
                }
            }
        }
    }
    
    // MARK: - Inline Screen Recording Task Submission
    
    @available(macOS 12.3, *)
    private func submitInlineScreenTask() async {
        guard !inlineScreenTaskSubmitted,
              let screenManager = inlineScreenManager,
              let videoURL = screenManager.recordingURL else {
            return
        }
        
        inlineScreenTaskSubmitted = true
        
        // Create task with screen recording info
        let taskTitle = "Screen recording \(Date().formatted(date: .abbreviated, time: .shortened))"
        let taskDescription = "Screen recording captured using \(screenManager.recordingMode.displayName) mode"
        
        // Create upload metadata using the same structure as ScreenRecorderView
        let metadata = ScreenUploadMetadata(
            title: taskTitle,
            description: taskDescription
        )
        
        // Get upload endpoint from CommunicationSettings
        let uploadEndpoint = communicationSettings.taskCreateURL
        
        // Use FileUploadService for consistent multipart/form-data upload
        let result = await inlineScreenUploadService.uploadScreenRecording(
            from: videoURL,
            to: uploadEndpoint,
            withMetadata: metadata
        )
        
        await MainActor.run {
            if result.isSuccess {
                // Create local task for immediate UI update
                let task = TaskItem(
                    title: taskTitle,
                    description: taskDescription,
                    status: .todo,
                    priority: .medium,
                    isCompleted: false,
                    createdAt: Date(),
                    creationType: .screen,
                    audioUrl: videoURL.path // Using audioUrl field for video path as well
                )
                
                // Add to tasks manager
                addQuickTaskToSystem(task)
                
                // Close inline recorder
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingInlineScreenRecorder = false
                }
                
                print("✅ Inline screen recording task submitted successfully via FileUploadService")
            } else {
                print("❌ Failed to submit inline screen recording task: \(result.error ?? "Unknown error")")
                inlineScreenManager?.errorMessage = result.error
            }
        }
    }
    
    // MARK: - Chat Functions
    private func sendChatMessage() {
        guard !chatMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let conversationId = activeConversationId else {
            showNoConversationError()
            return
        }
        
        let messageText = chatMessage
        chatMessage = ""
        isSendingChatMessage = true
        lastChatResponse = nil
        
        // Use ChatService to send message
        Task {
            let chatService = ChatService()
            let result = await chatService.sendMessage(
                to: communicationSettings.chatMessageURL,
                conversationId: conversationId,
                question: messageText
            )
            
            await MainActor.run {
                isSendingChatMessage = false
                switch result {
                case .success(let response):
                    lastChatResponse = response.data.answer.replacingOccurrences(of: "\\n", with: "\n")
                    print("✅ Chat message sent successfully from floating panel")
                    
                case .failure(let error):
                    print("❌ Failed to send chat message: \(error.localizedDescription)")
                    lastChatResponse = "Error sending message"
                }
            }
        }
    }
    
    private func showNoConversationError() {
        // Don't clear the message, just show error permanently until user closes
        lastChatResponse = "Please select a conversation first"
        print("⚠️ No conversation selected for chat message")
    }
    
    // MARK: - Chat Response Box
    private var chatResponseBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let response = lastChatResponse {
                HStack(alignment: .top, spacing: 8) {
                    Text(response)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            lastChatResponse = nil
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 16, height: 16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: gradientSettings.windowSize.width)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.2)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }
    
    // MARK: - Task List Box
    private var taskListBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(tasksManager.tasks, id: \.id) { task in
                        HStack(spacing: 8) {
                            // Active indicator
                            Circle()
                                .fill(task.id == activeTaskId ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                            
                            // Task title
                            Text(task.title)
                                .font(.system(size: 11))
                                .foregroundColor(task.id == activeTaskId ? .white : .white.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTaskId = task.id
                                showingTaskList = false
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showingTaskList = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 14, height: 14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: gradientSettings.windowSize.width)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.25),
                            Color.black.opacity(0.15)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    // MARK: - Chat Auto-Loading Helper
    private func loadActiveConversationIfNeeded() {
        // Trigger the chat view model to refresh and load active conversation
        chatViewModel.triggerRefresh()
    }

    // MARK: - Text Selection Handler
    private func handleTextSelectionReceived(_ text: String) {
        print("📋 [HUDView] Text selection received: \"\(text)\"")

        // Decide where to paste based on current mode and expanded state
        if !isExpanded && gradientSettings.compactBarMode == .chat {
            // Compact chat mode - paste to compact input field
            chatMessage = text
            print("📋 [HUDView] Text pasted to compact chat input")
        } else if isExpanded && selectedTab == .chat {
            // Expanded view on chat tab - text will be handled by ChatView
            print("📋 [HUDView] Text will be handled by ChatView")
        } else {
            // Switch to appropriate mode/tab for chat input
            if !isExpanded {
                // Switch compact mode to chat if not already
                gradientSettings.compactBarMode = .chat
                chatMessage = text
                print("📋 [HUDView] Switched to compact chat mode and pasted text")
            } else {
                // Switch to chat tab if expanded
                selectedTab = .chat
                print("📋 [HUDView] Switched to chat tab, text will be handled by ChatView")
            }
        }
    }

}
