import XCTest
@testable import NotchTodoCore

final class TaskDisplayModelTests: XCTestCase {
    func testFocusedTaskIsFirstIncompleteTaskInSourceOrder() {
        let tasks = [
            TaskItem(lineIndex: 1, text: "done first", isCompleted: true),
            TaskItem(lineIndex: 2, text: "next", isCompleted: false),
            TaskItem(lineIndex: 3, text: "later", isCompleted: false),
            TaskItem(lineIndex: 4, text: "done second", isCompleted: true),
        ]

        let model = TaskDisplayModel(tasks: tasks)

        XCTAssertEqual(model.completedCount, 2)
        XCTAssertEqual(model.totalCount, 4)
        XCTAssertEqual(model.incompleteCount, 2)
        XCTAssertEqual(model.focusedTask?.text, "next")
        XCTAssertEqual(model.remainingTasks.map(\.text), ["later"])
        XCTAssertEqual(model.completedTasks.map(\.text), ["done first", "done second"])
        XCTAssertFalse(model.isAllComplete)
    }

    func testAllCompleteHasNoFocusedOrRemainingTasks() {
        let tasks = [
            TaskItem(lineIndex: 1, text: "done first", isCompleted: true),
            TaskItem(lineIndex: 2, text: "done second", isCompleted: true),
        ]

        let model = TaskDisplayModel(tasks: tasks)

        XCTAssertNil(model.focusedTask)
        XCTAssertTrue(model.remainingTasks.isEmpty)
        XCTAssertEqual(model.completedTasks.map(\.text), ["done first", "done second"])
        XCTAssertTrue(model.isAllComplete)
    }

    func testEmptyTasksAreNotAllComplete() {
        let model = TaskDisplayModel(tasks: [])

        XCTAssertEqual(model.completedCount, 0)
        XCTAssertEqual(model.totalCount, 0)
        XCTAssertEqual(model.incompleteCount, 0)
        XCTAssertNil(model.focusedTask)
        XCTAssertTrue(model.remainingTasks.isEmpty)
        XCTAssertTrue(model.completedTasks.isEmpty)
        XCTAssertFalse(model.isAllComplete)
    }
}
