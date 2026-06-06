import Foundation
import XCTest
@testable import NotchTodoApp

@MainActor
final class AppSettingsStateTests: XCTestCase {
    func testSelectedFileExposesNameAndParentPath() {
        let state = AppSettingsState(launchAtLoginEnabled: false)
        let fileURL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Documents/tomorrow.md")

        state.setTaskFile(fileURL)

        XCTAssertEqual(state.taskFileName, "tomorrow.md")
        XCTAssertEqual(state.taskFileDirectory, "~/Documents")
    }

    func testMissingFileUsesEmptyStateLabels() {
        let state = AppSettingsState(launchAtLoginEnabled: true)

        XCTAssertEqual(state.taskFileName, "未选择任务文件")
        XCTAssertEqual(state.taskFileDirectory, "请选择一个 Markdown 文件")
        XCTAssertTrue(state.launchAtLoginEnabled)
    }
}
