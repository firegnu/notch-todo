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
        XCTAssertEqual(viewModel.compactLabel, "2/3")
    }

    func testAllCompleteUsesQuietCompactLabel() {
        let store = MockTaskFileStore()
        store.loadResult = .success([
            TaskItem(lineIndex: 1, text: "Done", isCompleted: true),
        ])
        let viewModel = TaskViewModel()

        viewModel.use(store: store)

        XCTAssertEqual(viewModel.compactLabel, "✓")
    }

    func testExternalChangeRestoresNormalCompactLabelWhenIncompleteTaskReturns() async {
        let completed = TaskItem(lineIndex: 1, text: "Done", isCompleted: true)
        let pending = TaskItem(lineIndex: 2, text: "Pending", isCompleted: false)
        let store = MockTaskFileStore()
        store.loadResult = .success([completed])
        let viewModel = TaskViewModel()
        viewModel.use(store: store)

        store.emit(.success([completed, pending]))
        await Task.yield()

        XCTAssertEqual(viewModel.compactLabel, "1/2")
    }

    func testDisplayGroupsFocusFirstIncompleteAndPreserveOrder() {
        let store = MockTaskFileStore()
        store.loadResult = .success([
            TaskItem(lineIndex: 1, text: "Done first", isCompleted: true),
            TaskItem(lineIndex: 2, text: "Focus", isCompleted: false),
            TaskItem(lineIndex: 3, text: "Later one", isCompleted: false),
            TaskItem(lineIndex: 4, text: "Done second", isCompleted: true),
            TaskItem(lineIndex: 5, text: "Later two", isCompleted: false),
        ])
        let viewModel = TaskViewModel()

        viewModel.use(store: store)

        XCTAssertEqual(viewModel.focusedTask?.text, "Focus")
        XCTAssertEqual(viewModel.remainingTasks.map(\.text), ["Later one", "Later two"])
        XCTAssertEqual(viewModel.completedTasks.map(\.text), ["Done first", "Done second"])
        XCTAssertEqual(viewModel.incompleteCount, 3)
    }

    func testAllCompleteHasNoFocusedOrRemainingTask() {
        let store = MockTaskFileStore()
        store.loadResult = .success([
            TaskItem(lineIndex: 1, text: "One", isCompleted: true),
            TaskItem(lineIndex: 2, text: "Two", isCompleted: true),
        ])
        let viewModel = TaskViewModel()

        viewModel.use(store: store)

        XCTAssertNil(viewModel.focusedTask)
        XCTAssertTrue(viewModel.remainingTasks.isEmpty)
        XCTAssertEqual(viewModel.completedTasks.map(\.text), ["One", "Two"])
        XCTAssertEqual(viewModel.incompleteCount, 0)
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

    func testLoadClassifiesMissingFileError() {
        let store = MockTaskFileStore()
        store.loadResult = .failure(CocoaError(.fileNoSuchFile))
        let viewModel = TaskViewModel()

        viewModel.use(store: store)

        XCTAssertEqual(viewModel.error?.kind, .fileMissing)
    }

    func testLoadClassifiesMarkdownFormatError() {
        let store = MockTaskFileStore()
        store.loadResult = .failure(MarkdownTaskParser.Error.missingTasksSection)
        let viewModel = TaskViewModel()

        viewModel.use(store: store)

        XCTAssertEqual(viewModel.error?.kind, .markdownFormat)
    }

    func testLoadClassifiesStaleBookmarkAsPermissionLost() {
        let store = MockTaskFileStore()
        store.loadResult = .failure(TaskFileStore.Error.staleBookmark)
        let viewModel = TaskViewModel()

        viewModel.use(store: store)

        XCTAssertEqual(viewModel.error?.kind, .permissionLost)
        XCTAssertEqual(viewModel.error?.recoveryActionTitle, "重新选择文件")
    }

    func testToggleClassifiesWriteConflictError() {
        let original = TaskItem(lineIndex: 1, text: "One", isCompleted: false)
        let store = MockTaskFileStore()
        store.loadResult = .success([original])
        store.toggleResult = .failure(MarkdownTaskParser.Error.taskConflict)
        let viewModel = TaskViewModel()
        viewModel.use(store: store)

        viewModel.toggle(original)

        XCTAssertEqual(viewModel.error?.kind, .writeConflict)
    }

    func testReloadTasksReplacesTasksAndClearsWriteConflictError() {
        let original = TaskItem(lineIndex: 1, text: "One", isCompleted: false)
        let changed = TaskItem(lineIndex: 1, text: "Changed", isCompleted: false)
        let store = MockTaskFileStore()
        store.loadResult = .success([original])
        store.toggleResult = .failure(MarkdownTaskParser.Error.taskConflict)
        let viewModel = TaskViewModel()
        viewModel.use(store: store)
        viewModel.toggle(original)

        store.loadResult = .success([changed])
        viewModel.reloadTasks()

        XCTAssertEqual(viewModel.tasks, [changed])
        XCTAssertNil(viewModel.error)
    }

    func testReloadTasksClassifiesReadFailure() {
        let original = TaskItem(lineIndex: 1, text: "One", isCompleted: false)
        let store = MockTaskFileStore()
        store.loadResult = .success([original])
        let viewModel = TaskViewModel()
        viewModel.use(store: store)

        store.loadResult = .failure(MarkdownTaskParser.Error.missingTasksSection)
        viewModel.reloadTasks()

        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertEqual(viewModel.error?.kind, .markdownFormat)
    }

    func testOpenTaskFileClassifiesMissingFileWithoutOpening() {
        let store = MockTaskFileStore()
        store.loadResult = .success([])
        let viewModel = TaskViewModel()
        viewModel.use(store: store)

        viewModel.openTaskFile()

        XCTAssertEqual(viewModel.error?.kind, .fileMissing)
    }

    func testRevealTaskFileClassifiesMissingFileWithoutRevealing() {
        let store = MockTaskFileStore()
        store.loadResult = .success([])
        let viewModel = TaskViewModel()
        viewModel.use(store: store)

        viewModel.revealTaskFile()

        XCTAssertEqual(viewModel.error?.kind, .fileMissing)
    }

    func testShowPermissionLostErrorUsesPermissionKind() {
        let viewModel = TaskViewModel()

        viewModel.showError(.permissionLost(message: "任务文件权限已失效，请重新选择文件"))

        XCTAssertEqual(viewModel.error?.kind, .permissionLost)
        XCTAssertEqual(viewModel.errorMessage, "任务文件权限已失效，请重新选择文件")
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

    func testStateChangeCallbackRunsAfterStoreLoad() {
        let viewModel = TaskViewModel()
        let store = MockTaskFileStore()
        store.loadResult = .success([
            TaskItem(lineIndex: 1, text: "first", isCompleted: false),
        ])
        var callbackCount = 0
        viewModel.onStateChanged = {
            callbackCount += 1
        }

        viewModel.use(store: store)

        XCTAssertEqual(callbackCount, 1)
    }

    func testStateChangeCallbackRunsAfterToggle() {
        let viewModel = TaskViewModel()
        let original = TaskItem(lineIndex: 1, text: "first", isCompleted: false)
        let completed = TaskItem(lineIndex: 1, text: "first", isCompleted: true)
        let store = MockTaskFileStore()
        store.loadResult = .success([original])
        store.toggleResult = .success([completed])
        var callbackCount = 0
        viewModel.onStateChanged = {
            callbackCount += 1
        }
        viewModel.use(store: store)

        viewModel.toggle(original)

        XCTAssertEqual(callbackCount, 2)
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
