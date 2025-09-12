import XCTest
@testable import AllyHub

@MainActor
final class TasksModelTests: XCTestCase {
    var tasksModel: TasksModel!
    
    override func setUp() {
        super.setUp()
        tasksModel = TasksModel()
        // Reset to default mock tasks for consistent testing
        tasksModel.resetTasks()
    }
    
    override func tearDown() {
        tasksModel = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testInitialization() {
        XCTAssertFalse(tasksModel.tasks.isEmpty, "Tasks should be initialized with mock data")
        XCTAssertEqual(tasksModel.currentTaskIndex, 0, "Should start with first task")
        XCTAssertEqual(tasksModel.tasks.count, 4, "Should have 4 mock tasks")
    }
    
    func testMockTasksContent() {
        let expectedTasks = ["Email triage", "Spec doc review", "Prototype create", "Break"]
        let actualTasks = tasksModel.allTaskTitles
        
        XCTAssertEqual(actualTasks, expectedTasks, "Mock tasks should match expected content")
    }
    
    // MARK: - Current Task Tests
    func testCurrentTask() {
        XCTAssertNotNil(tasksModel.currentTask, "Should have a current task")
        XCTAssertEqual(tasksModel.currentTask?.title, "Email triage", "First task should be Email triage")
        XCTAssertEqual(tasksModel.currentTaskTitle, "Email triage", "Current task title should match")
    }
    
    // MARK: - Navigation Tests
    func testNextTask() {
        let initialIndex = tasksModel.currentTaskIndex
        
        XCTAssertTrue(tasksModel.hasNextTask, "Should have next task initially")
        
        tasksModel.nextTask()
        XCTAssertEqual(tasksModel.currentTaskIndex, initialIndex + 1, "Should move to next task")
        XCTAssertEqual(tasksModel.currentTaskTitle, "Spec doc review", "Should be on second task")
    }
    
    func testPreviousTask() {
        // Move to second task first
        tasksModel.nextTask()
        
        XCTAssertTrue(tasksModel.hasPreviousTask, "Should have previous task")
        
        tasksModel.previousTask()
        XCTAssertEqual(tasksModel.currentTaskIndex, 0, "Should move back to first task")
        XCTAssertEqual(tasksModel.currentTaskTitle, "Email triage", "Should be back on first task")
    }
    
    func testNavigationBounds() {
        // Test at beginning
        XCTAssertFalse(tasksModel.hasPreviousTask, "Should not have previous task at beginning")
        
        // Move to end
        while tasksModel.hasNextTask {
            tasksModel.nextTask()
        }
        
        XCTAssertFalse(tasksModel.hasNextTask, "Should not have next task at end")
        XCTAssertEqual(tasksModel.currentTaskIndex, tasksModel.tasks.count - 1, "Should be at last task")
    }
    
    func testGoToTask() {
        tasksModel.goToTask(at: 2)
        XCTAssertEqual(tasksModel.currentTaskIndex, 2, "Should navigate to specific task")
        XCTAssertEqual(tasksModel.currentTaskTitle, "Prototype create", "Should be on correct task")
        
        // Test invalid indices
        tasksModel.goToTask(at: -1)
        XCTAssertEqual(tasksModel.currentTaskIndex, 2, "Should not change for negative index")
        
        tasksModel.goToTask(at: 100)
        XCTAssertEqual(tasksModel.currentTaskIndex, 2, "Should not change for excessive index")
    }
    
    // MARK: - Task Completion Tests
    func testMarkTaskCompleted() {
        XCTAssertFalse(tasksModel.currentTask?.isCompleted ?? true, "Task should not be completed initially")
        
        tasksModel.markCurrentTaskCompleted()
        XCTAssertTrue(tasksModel.currentTask?.isCompleted ?? false, "Task should be marked completed")
        
        // Should automatically move to next task if available
        XCTAssertEqual(tasksModel.currentTaskIndex, 1, "Should move to next task after completion")
    }
    
    func testMarkTaskIncomplete() {
        tasksModel.markCurrentTaskCompleted()
        XCTAssertTrue(tasksModel.currentTask?.isCompleted ?? false, "Task should be completed")
        
        tasksModel.markCurrentTaskIncomplete()
        XCTAssertFalse(tasksModel.currentTask?.isCompleted ?? true, "Task should be marked incomplete")
    }
    
    func testToggleTaskCompletion() {
        let initialCompletion = tasksModel.currentTask?.isCompleted ?? false
        
        tasksModel.toggleCurrentTaskCompletion()
        XCTAssertNotEqual(tasksModel.currentTask?.isCompleted, initialCompletion, "Task completion should toggle")
        
        tasksModel.toggleCurrentTaskCompletion()
        XCTAssertEqual(tasksModel.currentTask?.isCompleted, initialCompletion, "Task completion should toggle back")
    }
    
    // MARK: - Progress Tests
    func testProgress() {
        XCTAssertEqual(tasksModel.progress, 0.0, "Progress should be 0 initially")
        
        // Complete first task
        tasksModel.markCurrentTaskCompleted()
        XCTAssertEqual(tasksModel.progress, 0.25, accuracy: 0.001, "Progress should be 25% after one task")
        
        // Complete second task
        tasksModel.markCurrentTaskCompleted()
        XCTAssertEqual(tasksModel.progress, 0.5, accuracy: 0.001, "Progress should be 50% after two tasks")
    }
    
    func testCompletedTasksCount() {
        XCTAssertEqual(tasksModel.completedTasksCount, 0, "Should have no completed tasks initially")
        
        tasksModel.markCurrentTaskCompleted()
        XCTAssertEqual(tasksModel.completedTasksCount, 1, "Should have one completed task")
    }
    
    // MARK: - Task Management Tests
    func testAddTask() {
        let initialCount = tasksModel.tasks.count
        
        tasksModel.addTask("New Task")
        XCTAssertEqual(tasksModel.tasks.count, initialCount + 1, "Should have one more task")
        XCTAssertEqual(tasksModel.tasks.last?.title, "New Task", "New task should be added at end")
    }
    
    func testRemoveTask() {
        let initialCount = tasksModel.tasks.count
        
        tasksModel.removeTask(at: 0)
        XCTAssertEqual(tasksModel.tasks.count, initialCount - 1, "Should have one less task")
        XCTAssertNotEqual(tasksModel.tasks.first?.title, "Email triage", "First task should be removed")
    }
    
    func testRemoveTaskIndexAdjustment() {
        // Move to second task
        tasksModel.nextTask()
        let originalTitle = tasksModel.currentTaskTitle
        
        // Remove first task
        tasksModel.removeTask(at: 0)
        
        // Current task index should adjust
        XCTAssertEqual(tasksModel.currentTaskIndex, 0, "Index should adjust after removal")
        XCTAssertEqual(tasksModel.currentTaskTitle, originalTitle, "Should still be on same task content")
    }
    
    func testRemoveLastTask() {
        // Move to last task
        while tasksModel.hasNextTask {
            tasksModel.nextTask()
        }
        
        let lastIndex = tasksModel.currentTaskIndex
        tasksModel.removeTask(at: lastIndex)
        
        XCTAssertLessThan(tasksModel.currentTaskIndex, lastIndex, "Index should adjust when last task is removed")
    }
    
    // MARK: - Edge Cases Tests
    func testEmptyTasksList() {
        // Remove all tasks
        while !tasksModel.tasks.isEmpty {
            tasksModel.removeTask(at: 0)
        }
        
        XCTAssertNil(tasksModel.currentTask, "Should have no current task when empty")
        XCTAssertEqual(tasksModel.currentTaskTitle, "No tasks available", "Should show no tasks message")
        XCTAssertFalse(tasksModel.hasNextTask, "Should not have next task when empty")
        XCTAssertFalse(tasksModel.hasPreviousTask, "Should not have previous task when empty")
        XCTAssertEqual(tasksModel.progress, 0.0, "Progress should be 0 when empty")
    }
    
    func testResetTasks() {
        // Modify state
        tasksModel.nextTask()
        tasksModel.markCurrentTaskCompleted()
        tasksModel.addTask("Extra Task")
        
        // Reset
        tasksModel.resetTasks()
        
        XCTAssertEqual(tasksModel.currentTaskIndex, 0, "Should reset to first task")
        XCTAssertEqual(tasksModel.tasks.count, 4, "Should have original 4 tasks")
        XCTAssertEqual(tasksModel.currentTaskTitle, "Email triage", "Should be back to first task")
        XCTAssertFalse(tasksModel.tasks.contains { $0.isCompleted }, "No tasks should be completed after reset")
    }
    
    // MARK: - Convenience Extensions Tests
    func testTaskTitleArrays() {
        // Complete first task
        tasksModel.markCurrentTaskCompleted()
        
        XCTAssertEqual(tasksModel.allTaskTitles.count, 4, "Should return all task titles")
        XCTAssertEqual(tasksModel.completedTaskTitles.count, 1, "Should return completed task titles")
        XCTAssertEqual(tasksModel.incompleteTaskTitles.count, 3, "Should return incomplete task titles")
        
        XCTAssertEqual(tasksModel.completedTaskTitles.first, "Spec doc review", "Should return correct completed task")
    }
}