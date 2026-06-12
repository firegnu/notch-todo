import Foundation
import XCTest
@testable import NotchTodoCore

final class WidgetSharedDataTests: XCTestCase {
    func testBookmarkStorePersistsBookmarkData() {
        let suiteName = "NotchTodoTests.WidgetSharedData.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = WidgetTaskFileBookmarkStore(defaults: defaults)
        let data = Data([1, 2, 3, 4])

        store.saveBookmark(data)

        XCTAssertEqual(store.loadBookmark(), data)
        store.clearBookmark()
        XCTAssertNil(store.loadBookmark())
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testSnapshotStoreRoundTripsTaskItems() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "NotchTodoWidgetSnapshot-\(UUID().uuidString)")
        let store = WidgetTaskSnapshotStore(directoryURL: directory)
        let tasks = [
            TaskItem(lineIndex: 10, text: "first", isCompleted: false),
            TaskItem(lineIndex: 11, text: "second", isCompleted: true),
        ]
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = WidgetTaskSnapshot(generatedAt: generatedAt, tasks: tasks)

        try store.saveSnapshot(snapshot)

        let loaded = try XCTUnwrap(store.loadSnapshot())
        XCTAssertEqual(loaded.generatedAt, generatedAt)
        XCTAssertEqual(loaded.taskItems, tasks)
        store.clearSnapshot()
        XCTAssertNil(store.loadSnapshot())
        try? FileManager.default.removeItem(at: directory)
    }
}
