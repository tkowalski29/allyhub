import SwiftUI

struct TasksView: View {
    @ObservedObject var tasksManager: TasksManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if tasksManager.tasks.isEmpty {
                    emptyStateView
                } else {
                    ForEach(tasksManager.tasks) { task in
                        TaskItemView(
                            task: task,
                            isExpanded: tasksManager.expandedTaskId == task.id,
                            onToggleExpanded: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    tasksManager.expandedTaskId = tasksManager.expandedTaskId == task.id ? nil : task.id
                                }
                            },
                            onToggleCompletion: {
                                tasksManager.toggleTaskCompletion(task)
                            },
                            onStartTask: {
                                tasksManager.startTask(task)
                            },
                            onStopTask: {
                                tasksManager.stopTask(task)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
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
}

struct TaskItemView: View {
    let task: TaskItem
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    let onToggleCompletion: () -> Void
    let onStartTask: () -> Void
    let onStopTask: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main task row
            Button(action: onToggleExpanded) {
                HStack(spacing: 12) {
                    // Completion status
                    Button(action: onToggleCompletion) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(task.isCompleted ? .green : .white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    // Task content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(task.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .strikethrough(task.isCompleted)
                            
                            Spacer()
                            
                            // Priority indicator
                            priorityBadge
                            
                            // Status indicator
                            statusBadge
                        }
                        
                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(isExpanded ? nil : 2)
                        }
                        
                        // Tags and due date row
                        HStack {
                            // Tags
                            if !task.tags.isEmpty {
                                ForEach(task.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.3))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Spacer()
                            
                            // Due date
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
                    }
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            
            // Expanded actions
            if isExpanded {
                actionButtonsView
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
    }
    
    private var priorityBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark")
                .font(.caption2)
            Text(task.priority.rawValue.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(priorityColor.opacity(0.3))
        .foregroundStyle(priorityColor)
        .clipShape(Capsule())
    }
    
    private var statusBadge: some View {
        Text(task.status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.3))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Start/Stop button
            if !task.isCompleted {
                Button(action: task.status == .inprogress ? onStopTask : onStartTask) {
                    HStack(spacing: 6) {
                        Image(systemName: task.status == .inprogress ? "pause.circle" : "play.circle")
                            .font(.caption)
                        Text(task.status == .inprogress ? "Stop" : "Start")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.6))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // Mark as complete/incomplete button
            Button(action: onToggleCompletion) {
                HStack(spacing: 6) {
                    Image(systemName: task.isCompleted ? "arrow.counterclockwise" : "checkmark.circle")
                        .font(.caption)
                    Text(task.isCompleted ? "Reopen" : "Complete")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(task.isCompleted ? Color.orange.opacity(0.6) : Color.green.opacity(0.6))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // URL button if available
            if let urlString = task.url, let url = URL(string: urlString) {
                Button(action: {
                    NSWorkspace.shared.open(url)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("Open")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.6))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
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

// MARK: - Task Data Models

struct TaskItem: Identifiable, Equatable {
    let id = UUID()
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
    
    init(title: String, description: String, status: TaskStatus, priority: TaskPriority, isCompleted: Bool, dueDate: Date? = nil, createdAt: Date? = nil, url: String? = nil, apiId: String? = nil, tags: [String] = []) {
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
    }
    
    static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.status == rhs.status &&
               lhs.priority == rhs.priority
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