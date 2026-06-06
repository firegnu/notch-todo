import Foundation
import XCTest
@testable import NotchTodoCore

final class TaskFileStoreTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var fileURL: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        fileURL = temporaryDirectory.appendingPathComponent("tomorrow.md")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testLoadParsesTasksFromFile() throws {
        try write("## Tasks\n- [ ] One\n- [x] Two")
        let store = TaskFileStore(url: fileURL)

        let tasks = try store.load()

        XCTAssertEqual(tasks.map(\.text), ["One", "Two"])
        XCTAssertEqual(tasks.map(\.isCompleted), [false, true])
    }

    func testToggleWritesUpdatedMarkerAndReturnsLatestTasks() throws {
        try write("# Tomorrow\n\n## Tasks\n- [ ] One\n")
        let store = TaskFileStore(url: fileURL)
        let task = try XCTUnwrap(store.load().first)

        let tasks = try store.toggle(task)

        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "# Tomorrow\n\n## Tasks\n- [x] One\n")
        XCTAssertEqual(tasks.first?.isCompleted, true)
    }

    func testToggleDoesNotOverwriteConflictingExternalEdit() throws {
        try write("## Tasks\n- [ ] Original")
        let store = TaskFileStore(url: fileURL)
        let task = try XCTUnwrap(store.load().first)
        try write("## Tasks\n- [ ] Changed externally")

        XCTAssertThrowsError(try store.toggle(task))
        XCTAssertEqual(
            try String(contentsOf: fileURL, encoding: .utf8),
            "## Tasks\n- [ ] Changed externally"
        )
    }

    func testMonitorReloadsAfterExternalChange() throws {
        try write("## Tasks\n- [ ] Original")
        let store = TaskFileStore(url: fileURL)
        let changed = expectation(description: "file change observed")

        try store.startMonitoring { result in
            guard case let .success(tasks) = result,
                  tasks.first?.text == "Changed"
            else {
                return
            }
            changed.fulfill()
        }
        defer { store.stopMonitoring() }

        try write("## Tasks\n- [ ] Changed")

        wait(for: [changed], timeout: 2)
    }

    func testBookmarkRoundTripRestoresURL() throws {
        try write("## Tasks")

        let bookmark = try TaskFileStore.makeBookmark(for: fileURL)
        let restored = try TaskFileStore.resolveBookmark(bookmark)

        XCTAssertEqual(restored.standardizedFileURL, fileURL.standardizedFileURL)
    }

    private func write(_ value: String) throws {
        try value.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
