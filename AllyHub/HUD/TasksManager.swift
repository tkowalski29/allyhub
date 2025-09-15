import SwiftUI
import Foundation

@MainActor
class TasksManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var tasksCount: Int = 0
    @Published var expandedTaskId: String?
    @Published var statusOrder: [String] = ["todo", "inprogress"] // Default order, updated from API
    
    private let communicationSettings: CommunicationSettings
    private let cacheManager = CacheManager.shared
    
    init(communicationSettings: CommunicationSettings) {
        self.communicationSettings = communicationSettings
        setupBackgroundRefresh()
        loadCachedTasks()
    }
    
    private func setupBackgroundRefresh() {
        NotificationCenter.default.addObserver(
            forName: .refreshTasksInBackground,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await self.fetchTasksInBackground()
            }
        }
    }
    
    private func loadCachedTasks() {
        if let cachedTasks = cacheManager.getCachedTasks() {
            let taskItems = cachedTasks.map { task in
                TaskItem(
                    title: task.title,
                    description: task.description,
                    status: TaskStatus(rawValue: task.status) ?? .todo,
                    priority: TaskPriority(rawValue: task.priority) ?? .medium,
                    isCompleted: task.isCompleted,
                    dueDate: task.dueDate,
                    createdAt: task.createdAt,
                    apiId: task.id
                )
            }
            self.tasks = taskItems
            self.tasksCount = taskItems.count
            print("📱 [TasksManager] Loaded \(taskItems.count) tasks from cache")
        }
    }
    
    // MARK: - Public Methods
    
    func fetchTasksInBackground() async {
        print("🔄 [TasksManager] Background refresh triggered")
        fetchTasks()
    }
    
    func fetchTasks() {
        print("🔄 [TasksManager] Starting fetchTasks()")
        
        guard !communicationSettings.tasksFetchURL.isEmpty else {
            print("❌ [TasksManager] Tasks fetch URL is empty")
            createFallbackTasks()
            return
        }
        
        print("🌐 [TasksManager] Fetch URL: \(communicationSettings.tasksFetchURL)")
        
        guard let url = URL(string: communicationSettings.tasksFetchURL) else {
            print("❌ [TasksManager] Invalid tasks fetch URL: \(communicationSettings.tasksFetchURL)")
            createFallbackTasks()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "userId": "default_user",
            "limit": 50
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to serialize tasks request: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Tasks fetch error: \(error)")
                DispatchQueue.main.async {
                    self?.createFallbackTasks()
                }
                return
            }
            
            guard let data = data else {
                print("No data received for tasks")
                DispatchQueue.main.async {
                    self?.createFallbackTasks()
                }
                return
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [TasksManager] Raw API response: \(responseString)")
            }
            
            do {
                // First try to decode as array containing structured response (your API format)
                if let arrayResponse = try? JSONDecoder().decode([TasksResponse].self, from: data),
                   let firstResponse = arrayResponse.first {
                    print("✅ [TasksManager] Decoded as array containing structured response")
                    DispatchQueue.main.async {
                        self?.processTasksResponse(firstResponse)
                    }
                } else if let response = try? JSONDecoder().decode(TasksResponse.self, from: data) {
                    // Fallback: try to decode as direct structured response
                    print("✅ [TasksManager] Decoded as direct structured response")
                    DispatchQueue.main.async {
                        self?.processTasksResponse(response)
                    }
                } else if let apiTasks = try? JSONDecoder().decode([APITask].self, from: data) {
                    // Final fallback: try to decode as direct array of tasks
                    print("✅ [TasksManager] Decoded as direct array of tasks")
                    DispatchQueue.main.async {
                        self?.processTasksArray(apiTasks)
                    }
                } else {
                    throw NSError(domain: "TasksManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode tasks response"])
                }
            } catch {
                print("Failed to decode tasks response: \(error)")
                DispatchQueue.main.async {
                    let fallbackTask = TaskItem(
                        title: "System",
                        description: "Failed to load tasks from server. Using fallback data.",
                        status: .todo,
                        priority: .medium,
                        isCompleted: false,
                        dueDate: Date(),
                        createdAt: Date()
                    )
                    self?.tasks = [fallbackTask]
                    self?.tasksCount = 1
                }
            }
        }.resume()
    }
    
    func updateTaskStatus(taskId: String, action: TaskAction) {
        print("🔄 [TasksManager] Updating task \(taskId) with action: \(action)")
        
        guard !communicationSettings.taskUpdateURL.isEmpty else {
            print("❌ [TasksManager] Task update URL is empty")
            return
        }
        
        guard let url = URL(string: communicationSettings.taskUpdateURL) else {
            print("❌ [TasksManager] Invalid task update URL: \(communicationSettings.taskUpdateURL)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "id": taskId,
            "action": action.rawValue,
            "date": ISO8601DateFormatter().string(from: Date()),
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to serialize task update request: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Task update error: \(error)")
                return
            }
            
            print("✅ [TasksManager] Task \(taskId) updated successfully")
            
            // Refresh tasks after update
            DispatchQueue.main.async {
                self.fetchTasks()
            }
        }.resume()
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        guard let apiId = task.apiId else {
            print("❌ Task has no API ID, cannot update")
            return
        }
        
        let action: TaskAction = task.isCompleted ? .start : .close
        updateTaskStatus(taskId: apiId, action: action)
    }
    
    func startTask(_ task: TaskItem) {
        guard let apiId = task.apiId else {
            print("❌ Task has no API ID, cannot start")
            return
        }
        
        updateTaskStatus(taskId: apiId, action: .start)
    }
    
    func stopTask(_ task: TaskItem) {
        guard let apiId = task.apiId else {
            print("❌ Task has no API ID, cannot stop")
            return
        }
        
        updateTaskStatus(taskId: apiId, action: .stop)
    }
    
    // MARK: - Private Methods
    
    private func normalizeTaskStatus(_ status: String?) -> TaskStatus {
        guard let status = status else { 
            print("⚠️ [TasksManager] Status is nil, defaulting to .todo")
            return .todo 
        }
        
        print("🔍 [TasksManager] Normalizing status: '\(status)' -> lowercased: '\(status.lowercased())'")
        
        switch status.lowercased() {
        case "todo", "to do":
            print("✅ [TasksManager] Status mapped to .todo")
            return .todo
        case "inprogress", "in progress", "in-progress":
            print("✅ [TasksManager] Status mapped to .inprogress")
            return .inprogress
        default:
            print("⚠️ [TasksManager] Unknown status '\(status)', defaulting to .todo")
            return .todo
        }
    }
    
    private func processTasksArray(_ apiTasks: [APITask]) {
        var newTasks: [TaskItem] = []
        
        let dateFormatter = ISO8601DateFormatter()
        print("📋 [TasksManager] Processing \(apiTasks.count) tasks from API array")
        
        for apiTask in apiTasks {
            var createdDate: Date?
            var dueDate: Date?
            
            if let createdAtString = apiTask.created_at {
                createdDate = dateFormatter.date(from: createdAtString)
            }
            
            if let dueDateString = apiTask.due_date, !dueDateString.isEmpty {
                print("🗓️ [TasksManager] Raw due_date string: '\(dueDateString)'")
                dueDate = dateFormatter.date(from: dueDateString)
                if dueDate == nil {
                    print("❌ [TasksManager] Failed to parse due_date with ISO8601DateFormatter")
                    // Try alternative date formatter
                    let altFormatter = DateFormatter()
                    altFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    altFormatter.timeZone = TimeZone(identifier: "UTC")
                    dueDate = altFormatter.date(from: dueDateString)
                    if dueDate != nil {
                        print("✅ [TasksManager] Successfully parsed due_date with alternative formatter")
                    } else {
                        print("❌ [TasksManager] Failed to parse due_date with alternative formatter too")
                    }
                } else {
                    print("✅ [TasksManager] Successfully parsed due_date with ISO8601DateFormatter")
                }
            } else {
                print("⚠️ [TasksManager] No due_date provided or empty string")
            }
            
            print("📋 [TasksManager] Processing task: '\(apiTask.title ?? "No Title")' with dueDate: \(apiTask.due_date ?? "nil")")
            print("📋 [TasksManager] Task due date parsed as: \(dueDate?.description ?? "nil")")
            
            let task = TaskItem(
                title: apiTask.title ?? "No Title",
                description: apiTask.description ?? "No Description",
                status: normalizeTaskStatus(apiTask.status),
                priority: TaskPriority(rawValue: apiTask.priority?.lowercased() ?? "medium") ?? .medium,
                isCompleted: apiTask.is_completed ?? false,
                dueDate: dueDate,
                createdAt: createdDate,
                url: apiTask.url,
                apiId: apiTask.id,
                tags: apiTask.tags ?? []
            )
            
            print("✅ [TasksManager] Created TaskItem with dueDate: \(task.dueDate?.description ?? "nil")")
            newTasks.append(task)
        }
        
        tasks = newTasks
        tasksCount = newTasks.count
        
        // Cache the tasks
        let tasksForCache = newTasks.map { taskItem in
            CacheManager.CachedTask(
                id: taskItem.id,
                title: taskItem.title,
                description: taskItem.description,
                status: taskItem.status.rawValue,
                priority: taskItem.priority.rawValue,
                assignedTo: nil, // TaskItem doesn't have assignedTo
                dueDate: taskItem.dueDate,
                createdAt: taskItem.createdAt,
                updatedAt: nil, // TaskItem doesn't have updatedAt
                isCompleted: taskItem.isCompleted
            )
        }
        cacheManager.cacheTasks(tasksForCache)
        
        print("Successfully fetched \(newTasks.count) tasks (direct array)")
    }
    
    private func processTasksResponse(_ response: TasksResponse) {
        var newTasks: [TaskItem] = []
        
        let dateFormatter = ISO8601DateFormatter()
        
        for apiTask in response.collection {
            var createdDate: Date?
            var dueDate: Date?
            
            if let createdAtString = apiTask.created_at {
                createdDate = dateFormatter.date(from: createdAtString)
            }
            
            if let dueDateString = apiTask.due_date, !dueDateString.isEmpty {
                print("🗓️ [TasksManager] Raw due_date string: '\(dueDateString)'")
                dueDate = dateFormatter.date(from: dueDateString)
                if dueDate == nil {
                    print("❌ [TasksManager] Failed to parse due_date with ISO8601DateFormatter")
                    // Try alternative date formatter
                    let altFormatter = DateFormatter()
                    altFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    altFormatter.timeZone = TimeZone(identifier: "UTC")
                    dueDate = altFormatter.date(from: dueDateString)
                    if dueDate != nil {
                        print("✅ [TasksManager] Successfully parsed due_date with alternative formatter")
                    } else {
                        print("❌ [TasksManager] Failed to parse due_date with alternative formatter too")
                    }
                } else {
                    print("✅ [TasksManager] Successfully parsed due_date with ISO8601DateFormatter")
                }
            } else {
                print("⚠️ [TasksManager] No due_date provided or empty string")
            }
            
            let task = TaskItem(
                title: apiTask.title ?? "No Title",
                description: apiTask.description ?? "No Description",
                status: normalizeTaskStatus(apiTask.status),
                priority: TaskPriority(rawValue: apiTask.priority?.lowercased() ?? "medium") ?? .medium,
                isCompleted: apiTask.is_completed ?? false,
                dueDate: dueDate,
                createdAt: createdDate,
                url: apiTask.url,
                apiId: apiTask.id,
                tags: apiTask.tags ?? []
            )
            
            newTasks.append(task)
        }
        
        tasks = newTasks
        tasksCount = response.count
        
        // Cache the tasks
        let tasksForCache = newTasks.map { taskItem in
            CacheManager.CachedTask(
                id: taskItem.id,
                title: taskItem.title,
                description: taskItem.description,
                status: taskItem.status.rawValue,
                priority: taskItem.priority.rawValue,
                assignedTo: nil, // TaskItem doesn't have assignedTo
                dueDate: taskItem.dueDate,
                createdAt: taskItem.createdAt,
                updatedAt: nil, // TaskItem doesn't have updatedAt
                isCompleted: taskItem.isCompleted
            )
        }
        cacheManager.cacheTasks(tasksForCache)
        
        // Update status order from API if provided
        if let apiStatusOrder = response.priority_status {
            // Convert API status strings to our internal format
            statusOrder = apiStatusOrder.map { status in
                switch status.lowercased() {
                case "todo", "to do":
                    return "todo"
                case "in progress", "inprogress":
                    return "inprogress"
                default:
                    return status.lowercased()
                }
            }
            print("✅ Updated status order from API: \(statusOrder)")
        }
        
        print("✅ Successfully fetched \(newTasks.count) tasks, total count: \(response.count)")
    }
    
    private func createFallbackTasks() {
        let fallbackTasks = [
            TaskItem(
                title: "Welcome to AllyHub",
                description: "Get familiar with your new task management companion. Explore features and settings.",
                status: .todo,
                priority: .high,
                isCompleted: false,
                dueDate: Date().addingTimeInterval(86400), // Tomorrow
                createdAt: Date().addingTimeInterval(-3600),
                url: nil,
                apiId: nil,
                tags: ["welcome", "setup"]
            ),
            TaskItem(
                title: "Complete Current Project",
                description: "Finish the remaining tasks for the current project milestone. Review deliverables and prepare for presentation.",
                status: .inprogress,
                priority: .high,
                isCompleted: false,
                dueDate: Date().addingTimeInterval(172800), // 2 days
                createdAt: Date().addingTimeInterval(-1800),
                url: nil,
                apiId: nil,
                tags: ["project", "urgent"]
            ),
            TaskItem(
                title: "Team Meeting Preparation",
                description: "Prepare agenda and materials for the upcoming team meeting. Gather progress reports from all team members.",
                status: .todo,
                priority: .medium,
                isCompleted: false,
                dueDate: Date().addingTimeInterval(259200), // 3 days
                createdAt: Date().addingTimeInterval(-900),
                url: nil,
                apiId: nil,
                tags: ["meeting", "team"]
            ),
            TaskItem(
                title: "Code Review",
                description: "Review and approve pending pull requests. Provide constructive feedback to team members.",
                status: .todo,
                priority: .low,
                isCompleted: true,
                dueDate: Date().addingTimeInterval(-86400), // Yesterday (completed)
                createdAt: Date().addingTimeInterval(-7200),
                url: nil,
                apiId: nil,
                tags: ["development", "review"]
            )
        ]
        
        tasks = fallbackTasks
        tasksCount = fallbackTasks.count
        print("Using fallback tasks")
    }
}

// MARK: - API Response Models

struct TasksResponse: Codable {
    let collection: [APITask]
    let count: Int
    let priority_status: [String]?
}

struct APITask: Codable {
    let id: String?
    let url: String?
    let title: String?
    let description: String?
    let is_completed: Bool?
    let priority: String?
    let status: String?
    let tags: [String]?
    let due_date: String?
    let created_at: String?
    let updated_at: String?
}

// MARK: - Task Action Enum

enum TaskAction: String, CaseIterable {
    case close = "close"
    case start = "start"
    case stop = "stop"
}