import SwiftUI

struct TasksView: View {
    @ObservedObject var tasksManager: TasksManager
    @ObservedObject var tasksModel: TasksModel
    @ObservedObject var timerModel: TimerModel
    @ObservedObject var actionsManager: ActionsManager
    @ObservedObject var communicationSettings: CommunicationSettings
    @ObservedObject var taskCreationSettings: TaskCreationSettings
    @Binding var showingTaskCreationOptions: Bool
    @AppStorage("activeTaskId") private var activeTaskId: String?
    @State private var expandedStatusSections: Set<String> = ["todo", "inprogress"] // Default expanded
    @State private var showingTaskFormView = false
    @State private var showingAudioRecorderView = false
    @State private var showingScreenRecorderView = false
    @State private var showingInlineTaskForm = false
    @State private var inlineTaskTitle = ""
    @State private var inlineTaskDescription = ""
    @State private var inlineTaskIsSubmitting = false
    @State private var inlineTaskErrorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Task creation options (shown when + is clicked)
            if showingTaskCreationOptions {
                HStack(spacing: 16) {
                    // Form button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingTaskCreationOptions = false
                            showingInlineTaskForm = true
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.green)
                                .clipShape(Circle())
                            Text("Form")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Microphone button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingTaskCreationOptions = false
                            showingAudioRecorderView = true
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.orange)
                                .clipShape(Circle())
                            Text("Audio")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Screen recording button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingTaskCreationOptions = false
                            showingScreenRecorderView = true
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "record.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.purple)
                                .clipShape(Circle())
                            Text("Screen")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if tasksManager.tasks.isEmpty {
                            emptyStateView
                        } else {
                            // Active task section at top (if any)
                            if let activeTask = tasksManager.tasks.first(where: { $0.id == activeTaskId }) {
                                activeTaskSection(activeTask)
                            } else {
                                // Clear activeTaskId if the task no longer exists
                                if activeTaskId != nil {
                                    let _ = { activeTaskId = nil }()
                                }
                            }
                            
                            // Task sections grouped by status
                            ForEach(groupedTaskStatuses, id: \.self) { status in
                                taskStatusSection(status: status)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, showingInlineTaskForm ? 120 : 0) // Add bottom padding when form is shown
                }
                
                // Inline task form at bottom
                if showingInlineTaskForm {
                    inlineTaskFormView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showingTaskFormView) {
            TaskFormView(onTaskCreated: { task in
                addTaskToSystem(task)
            }, communicationSettings: communicationSettings)
        }
        .sheet(isPresented: $showingAudioRecorderView) {
            AudioRecorderView(onTaskCreated: { task in
                addTaskToSystem(task)
            }, communicationSettings: communicationSettings)
        }
        .sheet(isPresented: $showingScreenRecorderView) {
            if #available(macOS 12.3, *) {
                ScreenRecorderView(onTaskCreated: { task in
                    addTaskToSystem(task)
                }, communicationSettings: communicationSettings)
            } else {
                ScreenRecorderFallbackView()
            }
        }
    }
    
    // Group tasks by status using API-provided order
    private var groupedTaskStatuses: [String] {
        let existingStatuses = Set(tasksManager.tasks.map { $0.status.rawValue })
        
        // Use API-provided order, but only include statuses that actually have tasks
        return tasksManager.statusOrder.filter { existingStatuses.contains($0) }
    }
    
    private func tasksForStatus(_ status: String) -> [TaskItem] {
        return tasksManager.tasks
            .filter { $0.status.rawValue == status && $0.id != activeTaskId }
            .sorted { task1, task2 in
                // Sort by priority: high > medium > low
                let priority1 = prioritySortOrder(task1.priority)
                let priority2 = prioritySortOrder(task2.priority)
                if priority1 != priority2 {
                    return priority1 < priority2
                }
                // If same priority, sort by creation date (newest first)
                let date1 = task1.createdAt ?? Date.distantPast
                let date2 = task2.createdAt ?? Date.distantPast
                return date1 > date2
            }
    }
    
    private func prioritySortOrder(_ priority: TaskPriority) -> Int {
        switch priority {
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
    
    private func activeTaskSection(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Task")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.7))
                .textCase(.uppercase)
            
            ActiveTaskItemView(
                task: task,
                isTimerRunning: timerModel.isRunning,
                elapsedTime: timerModel.formattedTime,
                onStartTimer: { 
                    timerModel.start()
                    sendTimerAction(action: "start", for: task)
                },
                onStopTimer: { 
                    timerModel.pause()
                    sendTimerAction(action: "stop", for: task)
                },
                onCompleteTask: {
                    // Stop timer if running
                    if timerModel.isRunning {
                        timerModel.pause()
                        sendTimerAction(action: "stop", for: task)
                    }
                    // Mark task as completed and clear active task
                    tasksManager.toggleTaskCompletion(task)
                    activeTaskId = nil
                    sendTimerAction(action: "close", for: task)
                }
            )
        }
    }
    
    private func taskStatusSection(status: String) -> some View {
        let tasks = tasksForStatus(status)
        let statusDisplay = TaskStatus(rawValue: status)?.displayName ?? status.capitalized
        let isExpanded = expandedStatusSections.contains(status)
        
        return VStack(alignment: .leading, spacing: 8) {
            if !tasks.isEmpty {
                // Status header with accordion toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedStatusSections.contains(status) {
                            expandedStatusSections.remove(status)
                        } else {
                            expandedStatusSections.insert(status)
                        }
                    }
                }) {
                    HStack {
                        Text(statusDisplay)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        
                        Text("(\(tasks.count))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Tasks list (collapsed/expanded)
                if isExpanded {
                    LazyVStack(spacing: 8) {
                        ForEach(tasks) { task in
                            TaskItemView(
                                task: task,
                                isActive: task.id == activeTaskId,
                                isExpanded: tasksManager.expandedTaskId == task.id,
                                onToggleExpanded: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        tasksManager.expandedTaskId = tasksManager.expandedTaskId == task.id ? nil : task.id
                                    }
                                },
                                onToggleActive: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if activeTaskId == task.id {
                                            // Deactivate - remove from active
                                            activeTaskId = nil
                                        } else {
                                            // If timer is running, pause it before switching tasks
                                            if timerModel.isRunning {
                                                timerModel.pause()
                                            }
                                            
                                            // Reset timer when switching to new active task
                                            timerModel.reset()
                                            
                                            // Activate - set as current task in TasksModel
                                            activeTaskId = task.id
                                            setTaskAsCurrentInTasksModel(task)
                                        }
                                    }
                                },
                                onToggleCompletion: {
                                    tasksManager.toggleTaskCompletion(task)
                                }
                            )
                        }
                    }
                    .transition(.slide.combined(with: .opacity))
                }
            }
        }
    }
    
    private var inlineTaskFormView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Create Task")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingInlineTaskForm = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            // Form fields
            VStack(spacing: 8) {
                // Title field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                    
                    TextField("Enter task title", text: $inlineTaskTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                    
                    TextEditor(text: $inlineTaskDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                        .frame(minHeight: 60, maxHeight: 80)
                }
                
            }
            
            // Submit button
            Button(action: submitInlineTask) {
                HStack(spacing: 8) {
                    if inlineTaskIsSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                        Text("Create Task")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(canSubmitInlineTask ? Color.blue.opacity(0.7) : Color.gray.opacity(0.3))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmitInlineTask || inlineTaskIsSubmitting)
            
            // Error message
            if let errorMessage = inlineTaskErrorMessage {
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.4))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("No Tasks")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            Text("When you have tasks, they'll appear here.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private func setTaskAsCurrentInTasksModel(_ task: TaskItem) {
        // Create a TasksModel.Task from the API task
        let localTask = TasksModel.Task(title: task.title)
        
        // Add to TasksModel if not already there
        if !tasksModel.tasks.contains(where: { $0.title == task.title }) {
            tasksModel.tasks.append(localTask)
        }
        
        // Set as current task
        if let index = tasksModel.tasks.firstIndex(where: { $0.title == task.title }) {
            tasksModel.currentTaskIndex = index
        }
    }
    
    private func sendTimerAction(action: String, for task: TaskItem) {
        print("📤 TasksView sendTimerAction() called with action: \(action)")
        print("📤 taskUpdateURL: \(communicationSettings.taskUpdateURL)")
        print("📤 task: \(task.title)")
        
        // Get current date for start action, elapsed time for stop action
        let currentDate = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let timestampValue: String
        
        if action == "start" {
            // For start: use current timestamp
            timestampValue = dateFormatter.string(from: currentDate)
        } else {
            // For stop: timestamp should reflect elapsed time
            let elapsedSeconds = timerModel.elapsedTime
            let elapsedDate = Date(timeIntervalSince1970: elapsedSeconds)
            timestampValue = dateFormatter.string(from: elapsedDate)
        }
        
        // Create timer action with all required fields
        let timerAction = ActionItem(
            id: "timer_\(action)_\(UUID().uuidString)",
            title: "Timer \(action.capitalized)",
            message: "Timer action: \(action) for task: \(task.title)",
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
            "id": .string(task.apiId ?? task.id),
            "action": .string(action),
            "task_name": .string(task.title),
            "data": .string(timerModel.formattedTime),
            "timestamp": .string(timestampValue)
        ]
        
        print("📤 About to execute action: \(timerAction.title)")
        print("📤 Parameters: id=\(task.apiId ?? task.id), action=\(action), data=\(timerModel.formattedTime), timestamp=\(timestampValue)")
        actionsManager.executeAction(timerAction, parameters: parameters)
        print("📤 Action executed")
    }
    
    
    private func addTaskToSystem(_ task: TaskItem) {
        print("✅ Adding task to system: \(task.title)")
        
        // Add to TasksManager
        tasksManager.tasks.append(task)
        
        // Optionally set as active task
        if tasksManager.tasks.count == 1 {
            activeTaskId = task.id
        }
        
        print("📊 Total tasks: \(tasksManager.tasks.count)")
    }
    
    // MARK: - Inline Task Form Helpers
    
    private var canSubmitInlineTask: Bool {
        !inlineTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitInlineTask() {
        guard canSubmitInlineTask else { return }
        
        inlineTaskIsSubmitting = true
        inlineTaskErrorMessage = nil
        
        Task {
            await submitTaskToAPI()
        }
    }
    
    private func submitTaskToAPI() async {
        let taskData = InlineTaskData(
            type: "form",
            title: inlineTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: inlineTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            due_date: nil
        )
        
        do {
            let jsonData = try JSONEncoder().encode(taskData)
            
            guard !communicationSettings.taskCreateURL.isEmpty else {
                await MainActor.run {
                    createLocalTask()
                }
                return
            }
            
            let result = await sendTaskToServer(taskData: jsonData)
            
            await MainActor.run {
                inlineTaskIsSubmitting = false
                
                if result.success {
                    // Reset form on success
                    inlineTaskTitle = ""
                    inlineTaskDescription = ""
                    inlineTaskErrorMessage = nil
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingInlineTaskForm = false
                    }
                } else {
                    // Show error message
                    inlineTaskErrorMessage = result.error ?? "Failed to create task"
                }
            }
            
            // Wait 2 seconds after successful creation, then fetch tasks
            if result.success {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    tasksManager.fetchTasks()
                }
            }
        } catch {
            await MainActor.run {
                inlineTaskIsSubmitting = false
                inlineTaskErrorMessage = "Failed to encode task data"
            }
        }
    }
    
    private func sendTaskToServer(taskData: Data) async -> InlineTaskSubmissionResult {
        guard let url = URL(string: communicationSettings.taskCreateURL) else {
            return InlineTaskSubmissionResult(success: false, error: "Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = taskData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return InlineTaskSubmissionResult(success: false, error: "Invalid response")
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // Try to parse JSON response
                do {
                    let apiResponse = try JSONDecoder().decode(TaskCreateResponse.self, from: data)
                    
                    if apiResponse.success {
                        return InlineTaskSubmissionResult(success: true, taskData: apiResponse.data)
                    } else {
                        return InlineTaskSubmissionResult(success: false, error: apiResponse.message)
                    }
                } catch {
                    // Fallback: if JSON parsing fails but HTTP status is success, assume success
                    return InlineTaskSubmissionResult(success: true)
                }
            } else {
                // Try to parse error response
                do {
                    let apiResponse = try JSONDecoder().decode(TaskCreateResponse.self, from: data)
                    return InlineTaskSubmissionResult(success: false, error: apiResponse.message)
                } catch {
                    let errorMessage = "Server returned status code: \(httpResponse.statusCode)"
                    return InlineTaskSubmissionResult(success: false, error: errorMessage)
                }
            }
        } catch {
            return InlineTaskSubmissionResult(success: false, error: "Network error: \(error.localizedDescription)")
        }
    }
    
    private func createLocalTask() {
        let task = TaskItem(
            title: inlineTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: inlineTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            status: .todo,
            priority: .medium,
            isCompleted: false,
            dueDate: nil,
            createdAt: Date(),
            url: nil,
            apiId: UUID().uuidString,
            tags: [],
            creationType: .form,
            audioUrl: nil,
            transcription: nil
        )
        
        addTaskToSystem(task)
        
        // Reset form
        inlineTaskTitle = ""
        inlineTaskDescription = ""
        inlineTaskErrorMessage = nil
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showingInlineTaskForm = false
        }
    }
}

// MARK: - Extensions

extension TaskPriority {
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

// MARK: - Data Models

struct InlineTaskData: Codable {
    let type: String
    let title: String
    let description: String
    let due_date: String?
}

struct InlineTaskSubmissionResult {
    let success: Bool
    let error: String?
    let taskData: TaskCreateResponseData?
    
    init(success: Bool, error: String? = nil, taskData: TaskCreateResponseData? = nil) {
        self.success = success
        self.error = error
        self.taskData = taskData
    }
}

struct TaskCreateResponse: Codable {
    let success: Bool
    let message: String
    let data: TaskCreateResponseData?
}

struct TaskCreateResponseData: Codable {
    let id: String
    let url: String
}

// Active task view - shown at top with play/pause controls
struct ActiveTaskItemView: View {
    let task: TaskItem
    let isTimerRunning: Bool
    let elapsedTime: String
    let onStartTimer: () -> Void
    let onStopTimer: () -> Void
    let onCompleteTask: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Active task indicator - filled circle
            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                // Timer display - show when running or when there's elapsed time
                if isTimerRunning || elapsedTime != "00:00:00" {
                    HStack(spacing: 4) {
                        Image(systemName: isTimerRunning ? "timer" : "clock")
                            .font(.caption2)
                        Text(elapsedTime)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(isTimerRunning ? .green : .white.opacity(0.8))
                }
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Play/Pause button - first
                Button(action: isTimerRunning ? onStopTimer : onStartTimer) {
                    Image(systemName: isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(isTimerRunning ? .orange : .green)
                }
                .buttonStyle(.plain)
                
                // Link button in circle - second (if URL available)
                if let urlString = task.url, let url = URL(string: urlString) {
                    Button(action: {
                        NSWorkspace.shared.open(url)
                    }) {
                        Image(systemName: "link")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.purple)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Complete/Close button - third, green checkmark in circle
                Button(action: onCompleteTask) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Regular task item view with new design
struct TaskItemView: View {
    let task: TaskItem
    let isActive: Bool
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    let onToggleActive: () -> Void
    let onToggleCompletion: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main task row
            HStack(spacing: 12) {
                // Active/Activate button
                Button(action: onToggleActive) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(isActive ? Color.blue.opacity(0.6) : Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // Task content - clickable area for expand
                Button(action: onToggleExpanded) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .strikethrough(task.isCompleted)
                            .lineLimit(1)
                        
                        // Due date if available
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(dueDateText(dueDate))
                                    .font(.caption2)
                            }
                            .foregroundStyle(dueDateColor(dueDate))
                        }
                    }
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.slide.combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(task.isCompleted ? 0.03 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(task.isCompleted ? 0.1 : 0.15), lineWidth: 1)
                )
        )
        .overlay(
            // Priority border on the left edge
            HStack {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(priorityColor)
                    .frame(width: 3)
                Spacer()
            }
        )
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            
            // Action buttons and tags
            HStack {
                // Tags (if any)
                if !task.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.3))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    // URL button if available
                    if let urlString = task.url, let url = URL(string: urlString) {
                        Button(action: {
                            NSWorkspace.shared.open(url)
                        }) {
                            Image(systemName: "link")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.purple.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Close/Complete button
                    Button(action: onToggleCompletion) {
                        Image(systemName: task.isCompleted ? "arrow.counterclockwise" : "checkmark")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background((task.isCompleted ? Color.orange : Color.green).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
    
    // Helper computed properties
    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .todo: return .gray
        case .inprogress: return .blue
        }
    }
    
    private func dueDateText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return .red // Overdue
        } else if timeInterval < 86400 { // Less than 1 day
            return .orange
        } else {
            return .white.opacity(0.7)
        }
    }
}


