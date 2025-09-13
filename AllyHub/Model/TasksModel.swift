import Foundation
import Combine
import SwiftUI

@MainActor
final class TasksModel: ObservableObject {
    // MARK: - Task Model
    struct Task: Identifiable, Equatable, Codable {
        let id = UUID()
        let title: String
        var isCompleted: Bool = false
        let createdAt = Date()
        
        init(title: String) {
            self.title = title
        }
    }
    
    // MARK: - Published Properties
    @Published var tasks: [Task] = []
    @Published var currentTaskIndex: Int = 0
    
    // MARK: - Private Properties
    private let tasksKey = "AllyHub_Tasks"
    private let currentTaskIndexKey = "AllyHub_CurrentTaskIndex"
    
    // MARK: - Computed Properties
    var currentTask: Task? {
        guard !tasks.isEmpty, currentTaskIndex < tasks.count else { return nil }
        return tasks[currentTaskIndex]
    }
    
    var currentTaskTitle: String {
        return currentTask?.title ?? "No tasks available"
    }
    
    var hasNextTask: Bool {
        return currentTaskIndex < tasks.count - 1
    }
    
    var hasPreviousTask: Bool {
        return currentTaskIndex > 0
    }
    
    var completedTasksCount: Int {
        return tasks.filter { $0.isCompleted }.count
    }
    
    var progress: Double {
        guard !tasks.isEmpty else { return 0.0 }
        return Double(completedTasksCount) / Double(tasks.count)
    }
    
    // MARK: - Initialization
    init() {
        loadTasks()
    }
    
    // MARK: - Public Methods
    func nextTask() {
        guard hasNextTask else { return }
        currentTaskIndex += 1
        saveTasks()
    }
    
    func previousTask() {
        guard hasPreviousTask else { return }
        currentTaskIndex -= 1
        saveTasks()
    }
    
    func markCurrentTaskCompleted() {
        guard let currentTask = currentTask else { return }
        
        if let index = tasks.firstIndex(where: { $0.id == currentTask.id }) {
            tasks[index].isCompleted = true
            saveTasks()
            
            // Automatically move to next task if available
            if hasNextTask {
                nextTask()
            }
        }
    }
    
    func markCurrentTaskIncomplete() {
        guard let currentTask = currentTask else { return }
        
        if let index = tasks.firstIndex(where: { $0.id == currentTask.id }) {
            tasks[index].isCompleted = false
            saveTasks()
        }
    }
    
    func toggleCurrentTaskCompletion() {
        guard let currentTask = currentTask else { return }
        
        if currentTask.isCompleted {
            markCurrentTaskIncomplete()
        } else {
            markCurrentTaskCompleted()
        }
    }
    
    func addTask(_ title: String) {
        let newTask = Task(title: title)
        tasks.append(newTask)
        saveTasks()
    }
    
    func removeTask(at index: Int) {
        guard index < tasks.count else { return }
        
        tasks.remove(at: index)
        
        // Adjust current task index if necessary
        if currentTaskIndex >= tasks.count {
            currentTaskIndex = max(0, tasks.count - 1)
        }
        
        saveTasks()
    }
    
    func resetTasks() {
        currentTaskIndex = 0
        saveTasks()
    }
    
    func goToTask(at index: Int) {
        guard index >= 0, index < tasks.count else { return }
        currentTaskIndex = index
        saveTasks()
    }
    
    func saveTasks() {
        let userDefaults = UserDefaults.standard
        
        // Save tasks
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
        
        // Save current task index
        userDefaults.set(currentTaskIndex, forKey: currentTaskIndexKey)
    }
    
    private func loadTasks() {
        let userDefaults = UserDefaults.standard
        
        // Load tasks
        if let data = userDefaults.data(forKey: tasksKey),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decodedTasks
        }
        
        // Load current task index
        let savedIndex = userDefaults.integer(forKey: currentTaskIndexKey)
        currentTaskIndex = min(max(0, savedIndex), tasks.count - 1)
    }
}

// MARK: - Convenience Extensions
extension TasksModel {
    var allTaskTitles: [String] {
        return tasks.map { $0.title }
    }
    
    var completedTaskTitles: [String] {
        return tasks.filter { $0.isCompleted }.map { $0.title }
    }
    
    var incompleteTaskTitles: [String] {
        return tasks.filter { !$0.isCompleted }.map { $0.title }
    }
}

// MARK: - API Task Models

struct TaskItem: Identifiable, Equatable {
    var id: String { apiId ?? title }
    var title: String
    var description: String
    var status: TaskStatus
    var priority: TaskPriority
    var isCompleted: Bool
    var dueDate: Date?
    var createdAt: Date?
    var url: String?
    var apiId: String?
    var tags: [String]
    var creationType: TaskCreationType
    var audioUrl: String?
    var transcription: String?
    
    init(title: String, description: String, status: TaskStatus, priority: TaskPriority, isCompleted: Bool, dueDate: Date? = nil, createdAt: Date? = nil, url: String? = nil, apiId: String? = nil, tags: [String] = [], creationType: TaskCreationType = .form, audioUrl: String? = nil, transcription: String? = nil) {
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.url = url
        self.apiId = apiId
        self.tags = tags
        self.creationType = creationType
        self.audioUrl = audioUrl
        self.transcription = transcription
    }
    
    static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.status == rhs.status &&
               lhs.priority == rhs.priority &&
               lhs.creationType == rhs.creationType
    }
}

enum TaskStatus: String, CaseIterable {
    case todo = "todo"
    case inprogress = "inprogress"
    
    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .inprogress: return "In Progress"
        }
    }
}

enum TaskPriority: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

enum TaskCreationType: String, CaseIterable, Identifiable {
    case form = "form"
    case microphone = "microphone"
    case screen = "screen"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .form: return "Form"
        case .microphone: return "Voice Recording"
        case .screen: return "Screen Recording"
        }
    }
    
    var iconName: String {
        switch self {
        case .form: return "doc.text"
        case .microphone: return "mic"
        case .screen: return "display"
        }
    }
    
    var color: Color {
        switch self {
        case .form: return .blue
        case .microphone: return .green
        case .screen: return .purple
        }
    }
}