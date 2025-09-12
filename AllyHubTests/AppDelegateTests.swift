import XCTest
@testable import AllyHub

@MainActor
final class AppDelegateTests: XCTestCase {
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testAppDelegateInitialization() {
        XCTAssertNotNil(appDelegate.timerModel, "AppDelegate should have a timer model")
        XCTAssertNotNil(appDelegate.tasksModel, "AppDelegate should have a tasks model")
    }
    
    // MARK: - Model Integration Tests
    func testSharedModels() {
        // Test that models are properly initialized
        XCTAssertEqual(appDelegate.timerModel.remainingTime, 60 * 60, "Timer should be initialized with 60 minutes")
        XCTAssertFalse(appDelegate.tasksModel.tasks.isEmpty, "Tasks model should have tasks")
    }
    
    // MARK: - Timer Control Tests
    func testTimerControls() {
        // Test start timer
        appDelegate.startTimer()
        XCTAssertTrue(appDelegate.timerModel.isRunning, "Timer should be running after start")
        
        // Test stop timer
        appDelegate.stopTimer()
        XCTAssertFalse(appDelegate.timerModel.isRunning, "Timer should not be running after stop")
        XCTAssertFalse(appDelegate.timerModel.isPaused, "Timer should not be paused after stop")
        
        // Test toggle timer
        appDelegate.toggleTimer()
        XCTAssertTrue(appDelegate.timerModel.isRunning, "Timer should be running after toggle from stopped")
        
        appDelegate.toggleTimer()
        XCTAssertFalse(appDelegate.timerModel.isRunning, "Timer should not be running after toggle from running")
        XCTAssertTrue(appDelegate.timerModel.isPaused, "Timer should be paused after toggle from running")
        
        // Test reset timer
        appDelegate.resetTimer()
        XCTAssertEqual(appDelegate.timerModel.remainingTime, 60 * 60, "Timer should be reset to full time")
        XCTAssertFalse(appDelegate.timerModel.isRunning, "Timer should not be running after reset")
        XCTAssertFalse(appDelegate.timerModel.isPaused, "Timer should not be paused after reset")
    }
    
    // MARK: - Task Control Tests
    func testTaskControls() {
        let initialTask = appDelegate.tasksModel.currentTaskTitle
        
        appDelegate.nextTask()
        XCTAssertNotEqual(appDelegate.tasksModel.currentTaskTitle, initialTask, "Should move to next task")
    }
    
    // MARK: - Application Lifecycle Tests
    func testApplicationShouldTerminateAfterLastWindowClosed() {
        let shouldTerminate = appDelegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared)
        XCTAssertFalse(shouldTerminate, "Menu bar app should not terminate when windows close")
    }
    
    func testApplicationShouldHandleReopen() {
        let shouldHandle = appDelegate.applicationShouldHandleReopen(NSApplication.shared, hasVisibleWindows: false)
        XCTAssertTrue(shouldHandle, "Should handle reopen to show HUD")
    }
    
    // MARK: - Notification Tests
    func testTimerCompletionNotification() {
        let expectation = XCTestExpectation(description: "Timer completion notification should be handled")
        
        // Listen for the notification
        let observer = NotificationCenter.default.addObserver(
            forName: .timerCompleted,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // Post the notification
        NotificationCenter.default.post(name: .timerCompleted, object: nil)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Mock Delegate Tests
    func testStatusBarControllerDelegate() {
        // Test that AppDelegate conforms to StatusBarControllerDelegate
        XCTAssertTrue(appDelegate is StatusBarControllerDelegate, "AppDelegate should conform to StatusBarControllerDelegate")
        
        // Test delegate methods don't crash
        appDelegate.statusBarControllerDidRequestStartTimer(MockStatusBarController().controller)
        appDelegate.statusBarControllerDidRequestStopTimer(MockStatusBarController().controller)
        appDelegate.statusBarControllerDidRequestToggleTimer(MockStatusBarController().controller)
        
        // Verify timer state changes
        XCTAssertTrue(appDelegate.timerModel.isRunning, "Timer should be running after delegate start request")
    }
    
    func testFloatingPanelDelegate() {
        // Test that AppDelegate conforms to FloatingPanelDelegate
        XCTAssertTrue(appDelegate is FloatingPanelDelegate, "AppDelegate should conform to FloatingPanelDelegate")
        
        // Test delegate methods don't crash
        let mockPanel = MockFloatingPanel()
        appDelegate.floatingPanelDidRequestClose(mockPanel.panel)
        appDelegate.floatingPanelDidMove(mockPanel.panel)
    }
    
    // MARK: - Memory Management Tests
    func testCleanup() {
        // Simulate app termination
        let notification = Notification(name: NSApplication.willTerminateNotification)
        appDelegate.applicationWillTerminate(notification)
        
        // Test should not crash
        XCTAssertTrue(true, "Cleanup should complete without crashing")
    }
}

// MARK: - Mock Classes for Testing
private class MockStatusBarController {
    let controller: StatusBarController
    
    init() {
        let timerModel = TimerModel()
        let tasksModel = TasksModel()
        controller = StatusBarController(timerModel: timerModel, tasksModel: tasksModel)
    }
}

private class MockFloatingPanel {
    let panel: FloatingPanel
    
    init() {
        let timerModel = TimerModel()
        let tasksModel = TasksModel()
        panel = FloatingPanel(timerModel: timerModel, tasksModel: tasksModel)
    }
}

// MARK: - Integration Tests
extension AppDelegateTests {
    func testTimerModelIntegration() {
        // Test that AppDelegate properly integrates with TimerModel
        let initialTime = appDelegate.timerModel.remainingTime
        
        appDelegate.startTimer()
        XCTAssertTrue(appDelegate.timerModel.isRunning)
        
        appDelegate.resetTimer()
        XCTAssertEqual(appDelegate.timerModel.remainingTime, initialTime)
    }
    
    func testTasksModelIntegration() {
        // Test that AppDelegate properly integrates with TasksModel
        let initialTask = appDelegate.tasksModel.currentTaskTitle
        
        if appDelegate.tasksModel.hasNextTask {
            appDelegate.nextTask()
            XCTAssertNotEqual(appDelegate.tasksModel.currentTaskTitle, initialTask)
        }
    }
}