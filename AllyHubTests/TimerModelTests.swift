import XCTest
@testable import AllyHub

@MainActor
final class TimerModelTests: XCTestCase {
    var timerModel: TimerModel!
    
    override func setUp() {
        super.setUp()
        timerModel = TimerModel()
    }
    
    override func tearDown() {
        timerModel = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testInitialization() {
        XCTAssertEqual(timerModel.remainingTime, 60 * 60, "Timer should initialize with 60 minutes")
        XCTAssertFalse(timerModel.isRunning, "Timer should not be running initially")
        XCTAssertFalse(timerModel.isPaused, "Timer should not be paused initially")
        XCTAssertFalse(timerModel.isCompleted, "Timer should not be completed initially")
    }
    
    // MARK: - Formatted Time Tests
    func testFormattedTime() {
        timerModel.remainingTime = 3661 // 1 hour, 1 minute, 1 second
        XCTAssertEqual(timerModel.formattedTime, "01:01:01")
        
        timerModel.remainingTime = 3600 // 1 hour exactly
        XCTAssertEqual(timerModel.formattedTime, "01:00:00")
        
        timerModel.remainingTime = 61 // 1 minute, 1 second
        XCTAssertEqual(timerModel.formattedTime, "00:01:01")
        
        timerModel.remainingTime = 0 // Zero time
        XCTAssertEqual(timerModel.formattedTime, "00:00:00")
    }
    
    // MARK: - Progress Tests
    func testProgress() {
        // Full time remaining
        timerModel.remainingTime = 60 * 60
        XCTAssertEqual(timerModel.progress, 0.0, accuracy: 0.001)
        
        // Half time remaining
        timerModel.remainingTime = 30 * 60
        XCTAssertEqual(timerModel.progress, 0.5, accuracy: 0.001)
        
        // No time remaining
        timerModel.remainingTime = 0
        XCTAssertEqual(timerModel.progress, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Timer State Tests
    func testStartTimer() {
        timerModel.start()
        
        XCTAssertTrue(timerModel.isRunning)
        XCTAssertFalse(timerModel.isPaused)
    }
    
    func testPauseTimer() {
        timerModel.start()
        timerModel.pause()
        
        XCTAssertFalse(timerModel.isRunning)
        XCTAssertTrue(timerModel.isPaused)
    }
    
    func testStopTimer() {
        timerModel.start()
        timerModel.stop()
        
        XCTAssertFalse(timerModel.isRunning)
        XCTAssertFalse(timerModel.isPaused)
    }
    
    func testResetTimer() {
        timerModel.remainingTime = 30 * 60
        timerModel.start()
        timerModel.reset()
        
        XCTAssertEqual(timerModel.remainingTime, 60 * 60)
        XCTAssertFalse(timerModel.isRunning)
        XCTAssertFalse(timerModel.isPaused)
    }
    
    func testToggleTimer() {
        // Test toggle from stopped to running
        timerModel.toggle()
        XCTAssertTrue(timerModel.isRunning)
        
        // Test toggle from running to paused
        timerModel.toggle()
        XCTAssertFalse(timerModel.isRunning)
        XCTAssertTrue(timerModel.isPaused)
    }
    
    // MARK: - Completion Tests
    func testTimerCompletion() {
        timerModel.remainingTime = 0
        XCTAssertTrue(timerModel.isCompleted)
        
        timerModel.remainingTime = 1
        XCTAssertFalse(timerModel.isCompleted)
    }
    
    func testStartCompletedTimer() {
        timerModel.remainingTime = 0
        timerModel.start()
        
        // Should not start if completed
        XCTAssertFalse(timerModel.isRunning)
    }
    
    // MARK: - Edge Cases
    func testNegativeTimeHandling() {
        timerModel.remainingTime = -10
        XCTAssertEqual(timerModel.progress, 1.0, "Progress should be clamped to 1.0 for negative time")
        XCTAssertTrue(timerModel.isCompleted, "Timer should be completed for negative time")
    }
    
    func testExcessiveTimeHandling() {
        let excessiveTime: TimeInterval = 2 * 60 * 60 // 2 hours
        timerModel.remainingTime = excessiveTime
        XCTAssertEqual(timerModel.progress, 0.0, "Progress should handle excessive time gracefully")
    }
}

// MARK: - Async Timer Tests
extension TimerModelTests {
    func testTimerTicking() async {
        let expectation = XCTestExpectation(description: "Timer should tick down")
        
        let initialTime = timerModel.remainingTime
        timerModel.start()
        
        // Wait for a few ticks
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            XCTAssertLessThan(self.timerModel.remainingTime, initialTime, "Timer should have counted down")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        timerModel.stop()
    }
}