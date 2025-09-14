import SwiftUI

struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss
    let onTaskCreated: (TaskItem) -> Void
    let communicationSettings: CommunicationSettings
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(86400) // Tomorrow
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Create New Task")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Fill in the task details")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Form
            VStack(spacing: 16) {
                // Title field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    TextField("Enter task title", text: $title)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(.white)
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    TextField("Enter task description", text: $description, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(.white)
                }
                
                // Priority picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Priority")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        ForEach(TaskPriority.allCases, id: \.self) { priorityOption in
                            Button(action: {
                                priority = priorityOption
                            }) {
                                Text(priorityOption.rawValue.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(priority == priorityOption ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(priority == priorityOption ? .white : .white.opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                    }
                }
                
                // Due date toggle and picker
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Due Date")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Toggle("", isOn: $hasDueDate)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .labelsHidden()
                    }
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.1))
                )
                
                Button(action: {
                    createTask()
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isSubmitting ? "Creating..." : "Create Task")
                    }
                }
                .foregroundStyle(.white)
                .fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSubmitting ? .gray : .blue)
                )
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
        }
        .frame(width: 400, height: 500)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func createTask() {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            await submitTaskToAPI()
        }
    }
    
    private func submitTaskToAPI() async {
        let taskData = FormTaskData(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority.rawValue,
            creationType: "form",
            dueDate: hasDueDate ? dueDate.ISO8601Format() : nil
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
                isSubmitting = false
                
                if result.success {
                    createLocalTask()
                } else {
                    errorMessage = result.error
                }
            }
            
        } catch {
            await MainActor.run {
                isSubmitting = false
                errorMessage = "Failed to prepare task data: \(error.localizedDescription)"
            }
        }
    }
    
    private func createLocalTask() {
        let task = TaskItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            status: .todo,
            priority: priority,
            isCompleted: false,
            dueDate: hasDueDate ? dueDate : nil,
            createdAt: Date(),
            creationType: .form
        )
        
        onTaskCreated(task)
        dismiss()
    }
    
    private func sendTaskToServer(taskData: Data) async -> TaskSubmissionResult {
        guard let url = URL(string: communicationSettings.taskCreateURL) else {
            return TaskSubmissionResult(success: false, error: "Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = taskData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return TaskSubmissionResult(success: false, error: "Invalid response")
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                return TaskSubmissionResult(success: true)
            } else {
                let errorMessage = "Server returned status code: \(httpResponse.statusCode)"
                return TaskSubmissionResult(success: false, error: errorMessage)
            }
            
        } catch {
            return TaskSubmissionResult(success: false, error: "Network error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

struct FormTaskData: Codable {
    let title: String
    let description: String
    let priority: String
    let creationType: String
    let dueDate: String?
    let tags: [String]?
    let userId: String?
    
    init(title: String, description: String, priority: String, creationType: String, dueDate: String? = nil, tags: [String]? = nil, userId: String? = nil) {
        self.title = title
        self.description = description
        self.priority = priority
        self.creationType = creationType
        self.dueDate = dueDate
        self.tags = tags
        self.userId = userId
    }
}

struct TaskSubmissionResult {
    let success: Bool
    let error: String?
    
    init(success: Bool, error: String? = nil) {
        self.success = success
        self.error = error
    }
}

#Preview {
    TaskFormView(onTaskCreated: { task in
        print("Created task: \(task.title)")
    }, communicationSettings: CommunicationSettings())
    .preferredColorScheme(.dark)
}