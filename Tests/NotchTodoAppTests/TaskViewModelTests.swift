import Foundation
import XCTest
@testable import NotchTodoApp
@testable import NotchTodoCore

@MainActor
final class TaskViewModelTests: XCTestCase {
    func testLoadCalculatesProgress() {
        let store = MockTaskFileStore()
        store.loadResult = .success([
            TaskItem(lineIndex: 1, text: "One", isCompleted: true),
            TaskItem(lineIndex: 2, text: "Two", isCompleted: false),
            TaskItem(lineIndex: 3, text: "Three", isCompleted: true),
        ])
        let viewModel = TaskViewModel()

        viewModel.use(store: store)

        XCTAssertEqual(viewModel.completedCount, 2)
        XCTAssertEqual(viewModel.totalCount, 3)
        XCTAssertEqual(viewModel.compactLabel, "🌙 2/3")
    }

    func testAllCompleteUsesCompletionEmoji() {
        let store = MockTaskFileStore()
        store.loadResult = .success([
            TaskItem(lineIndex: 1, text: "Done", isCompleted: true),
        ])
        let viewModel = TaskViewModel()

        viewModel.use(store: store)

        XCTAssertEqual(viewModel.compactLabel, "✨ 1/1")
    }

    func testSuccessfulToggleKeepsTaskInOriginalPosition() {
        let original = TaskItem(lineIndex: 1, text: "One", isCompleted: false)
        let completed = TaskItem(lineIndex: 1, text: "One", isCompleted: true)
        let second = TaskItem(lineIndex: 2, text: "Two", isCompleted: false)
        let store = MockTaskFileStore()
        store.loadResult = .success([original, second])
        store.toggleResult = .success([completed, second])
        let viewModel = TaskViewModel()
        viewModel.use(store: store)

        viewModel.toggle(original)

        XCTAssertEqual(viewModel.tasks.map(\.text), ["One", "Two"])
        XCTAssertEqual(viewModel.tasks.map(\.isCompleted), [true, false])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFailedToggleRollsBackOptimisticState() {
        let original = TaskItem(lineIndex: 1, text: "One", isCompleted: false)
        let store = MockTaskFileStore()
        store.loadResult = .success([original])
        store.toggleResult = .failure(TestError.writeFailed)
        let viewModel = TaskViewModel()
        viewModel.use(store: store)

        viewModel.toggle(original)

        XCTAssertEqual(viewModel.tasks, [original])
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testExternalChangeReplacesTasks() async {
        let original = TaskItem(lineIndex: 1, text: "One", isCompleted: false)
        let changed = TaskItem(lineIndex: 1, text: "Changed", isCompleted: true)
        let store = MockTaskFileStore()
        store.loadResult = .success([original])
        let viewModel = TaskViewModel()
        viewModel.use(store: store)

        store.emit(.success([changed]))
        await Task.yield()

        XCTAssertEqual(viewModel.tasks, [changed])
    }
}

private enum TestError: Swift.Error {
    case writeFailed
}

private final class MockTaskFileStore: TaskFileStoring, @unchecked Sendable {
    let url = URL(fileURLWithPath: "/tmp/tomorrow.md")
    var loadResult: Result<[TaskItem], Swift.Error> = .success([])
    var toggleResult: Result<[TaskItem], Swift.Error> = .success([])
    private var onChange: (@Sendable (Result<[TaskItem], Swift.Error>) -> Void)?

    func load() throws -> [TaskItem] {
        try loadResult.get()
    }

    func toggle(_ task: TaskItem) throws -> [TaskItem] {
        try toggleResult.get()
    }

    func startMonitoring(
        onChange: @escaping @Sendable (Result<[TaskItem], Swift.Error>) -> Void
    ) throws {
        self.onChange = onChange
    }

    func stopMonitoring() {
        onChange = nil
    }

    func emit(_ result: Result<[TaskItem], Swift.Error>) {
        onChange?(result)
    }
}
