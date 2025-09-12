import Foundation
import Combine

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
        if tasks.isEmpty {
            setupMockTasks()
        }
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
        setupMockTasks()
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
    
    // MARK: - Private Methods
    private func setupMockTasks() {
        tasks = [
            Task(title: "Email triage"),
            Task(title: "Spec doc review"),
            Task(title: "Prototype create"),
            Task(title: "Break")
        ]
        currentTaskIndex = 0
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