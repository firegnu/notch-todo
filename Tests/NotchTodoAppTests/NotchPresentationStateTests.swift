import XCTest
@testable import NotchTodoApp

@MainActor
final class NotchPresentationStateTests: XCTestCase {
    func testShowSettingsLocksPanel() {
        let state = NotchPresentationState()

        state.showSettings()

        XCTAssertTrue(state.isShowingSettings)
        XCTAssertTrue(state.isLocked)
    }

    func testResetForCollapseReturnsToTasksAndUnlocksPanel() {
        let state = NotchPresentationState()
        state.showSettings()

        state.resetForCollapse()

        XCTAssertFalse(state.isShowingSettings)
        XCTAssertFalse(state.isLocked)
    }
}
