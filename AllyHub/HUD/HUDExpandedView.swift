import SwiftUI

struct HUDExpandedView: View {
    // MARK: - Properties
    @ObservedObject var timerModel: TimerModel
    @ObservedObject var tasksModel: TasksModel
    
    @State private var selectedTab: ExpandedTab = .progress
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelector
                .padding(.horizontal, 20)
                .padding(.top, 12)
            
            // Tab content
            TabView(selection: $selectedTab) {
                progressView
                    .tag(ExpandedTab.progress)
                
                tasksView
                    .tag(ExpandedTab.tasks)
                
                controlsView
                    .tag(ExpandedTab.controls)
            }
            .animation(.easeInOut(duration: 0.25), value: selectedTab)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ExpandedTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
            
            Spacer()
        }
    }
    
    private func tabButton(for tab: ExpandedTab) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            Text(tab.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Group {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.regularMaterial)
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timer progress
            HStack {
                Text("Timer Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(timerModel.progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: timerModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: timerModel.isRunning ? .blue : .secondary))
                .scaleEffect(y: 0.8)
            
            // Task progress
            HStack {
                Text("Task Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(tasksModel.currentTaskIndex + 1)/\(tasksModel.tasks.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: Double(tasksModel.currentTaskIndex + 1) / Double(max(1, tasksModel.tasks.count)))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(y: 0.8)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Tasks View
    private var tasksView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(tasksModel.tasks.enumerated()), id: \.element.id) { index, task in
                HStack(spacing: 8) {
                    // Task indicator
                    Circle()
                        .fill(taskIndicatorColor(for: index))
                        .frame(width: 6, height: 6)
                    
                    // Task title
                    Text(task.title)
                        .font(.system(size: 11, weight: index == tasksModel.currentTaskIndex ? .medium : .regular))
                        .foregroundStyle(index == tasksModel.currentTaskIndex ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    // Completion indicator
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.green)
                    }
                }
                .onTapGesture {
                    tasksModel.goToTask(at: index)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Controls View
    private var controlsView: some View {
        VStack(spacing: 8) {
            // Timer controls
            HStack(spacing: 12) {
                ControlButton(
                    title: timerModel.isRunning ? "Pause" : "Start",
                    icon: timerModel.isRunning ? "pause.fill" : "play.fill",
                    color: .blue
                ) {
                    timerModel.toggle()
                }
                
                if timerModel.isRunning || timerModel.isPaused {
                    ControlButton(
                        title: "Stop",
                        icon: "stop.fill",
                        color: .red
                    ) {
                        timerModel.stop()
                    }
                }
                
                if timerModel.elapsedTime > 0 && !timerModel.isRunning {
                    ControlButton(
                        title: "Reset",
                        icon: "arrow.clockwise",
                        color: .orange
                    ) {
                        timerModel.reset()
                    }
                }
                
                Spacer()
            }
            
            // Task controls
            HStack(spacing: 12) {
                if tasksModel.hasPreviousTask {
                    ControlButton(
                        title: "Previous",
                        icon: "arrow.left",
                        color: .secondary
                    ) {
                        tasksModel.previousTask()
                    }
                }
                
                if tasksModel.hasNextTask {
                    ControlButton(
                        title: "Next",
                        icon: "arrow.right",
                        color: .secondary
                    ) {
                        tasksModel.nextTask()
                    }
                }
                
                ControlButton(
                    title: tasksModel.currentTask?.isCompleted == true ? "Undo" : "Complete",
                    icon: tasksModel.currentTask?.isCompleted == true ? "arrow.uturn.left" : "checkmark",
                    color: .green
                ) {
                    tasksModel.toggleCurrentTaskCompletion()
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Helper Methods
    private func taskIndicatorColor(for index: Int) -> Color {
        if index == tasksModel.currentTaskIndex {
            return .blue
        } else if tasksModel.tasks[index].isCompleted {
            return .green
        } else if index < tasksModel.currentTaskIndex {
            return .secondary
        } else {
            return .secondary.opacity(0.3)
        }
    }
}

// MARK: - Control Button
struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.regularMaterial)
                    .opacity(isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
    }
}

// MARK: - Expanded Tab
enum ExpandedTab: CaseIterable {
    case progress
    case tasks
    case controls
    
    var title: String {
        switch self {
        case .progress:
            return "Progress"
        case .tasks:
            return "Tasks"
        case .controls:
            return "Controls"
        }
    }
}

// MARK: - Preview
#if DEBUG
struct HUDExpandedView_Previews: PreviewProvider {
    @StateObject static private var timerModel = TimerModel()
    @StateObject static private var tasksModel = TasksModel()
    
    static var previews: some View {
        HUDExpandedView(
            timerModel: timerModel,
            tasksModel: tasksModel
        )
        .frame(width: 420, height: 100)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
#endif