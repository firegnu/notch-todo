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

    func testCompactTapExpandsWithoutLockingPanel() {
        let state = NotchPresentationState()

        state.expandFromCompactTap()

        XCTAssertTrue(state.isExpanded)
        XCTAssertFalse(state.isLocked)
    }

    func testCompactTapDoesNotUnlockPinnedPanel() {
        let state = NotchPresentationState()
        state.isLocked = true

        state.expandFromCompactTap()

        XCTAssertTrue(state.isExpanded)
        XCTAssertTrue(state.isLocked)
    }
}
