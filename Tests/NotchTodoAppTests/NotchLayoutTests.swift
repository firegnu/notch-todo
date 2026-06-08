import AppKit
import XCTest
@testable import NotchTodoApp

final class NotchLayoutTests: XCTestCase {
    func testTaskRowCardsKeepSubtleVisualHierarchy() {
        XCTAssertEqual(TaskRowStyle.cornerRadius, 9)
        XCTAssertEqual(TaskRowStyle.fontSize, 12.5)
        XCTAssertEqual(TaskRowStyle.focusedFontSize, 13)
        XCTAssertEqual(TaskRowStyle.focusedCardPadding, 13)
        XCTAssertEqual(TaskRowStyle.focusedCardCornerRadius, 13)
        XCTAssertGreaterThan(TaskRowStyle.focusedFontSize, TaskRowStyle.fontSize)
        XCTAssertLessThan(TaskRowStyle.normalOpacity, TaskRowStyle.hoverOpacity)
        XCTAssertLessThan(TaskRowStyle.completedOpacity, TaskRowStyle.normalOpacity)
        XCTAssertLessThanOrEqual(TaskRowStyle.hoverOpacity, 0.08)
    }

    func testDailyUsePolishKeepsMotionAndStateCopyRestrained() {
        XCTAssertEqual(TaskInteractionStyle.toggleDuration, 0.16)
        XCTAssertEqual(TaskPanelStateContent.empty.title, "暂无任务")
        XCTAssertEqual(TaskPanelStateContent.complete.title, "今天的任务已完成")
        XCTAssertEqual(TaskPanelStateContent.error.title, "无法读取任务")
    }

    func testErrorPresentationKeepsSpecificCopyAndRestrainedActions() {
        XCTAssertEqual(TaskPanelError.fileMissing(message: "missing").stateContent.title, "任务文件不存在")
        XCTAssertEqual(TaskPanelError.noFileSelected(message: "select").stateContent.title, "请选择任务文件")
        XCTAssertEqual(TaskPanelError.permissionLost(message: "lost").stateContent.title, "需要重新授权")
        XCTAssertEqual(TaskPanelError.markdownFormat(message: "bad").stateContent.title, "Tasks 区域格式错误")
        XCTAssertEqual(TaskPanelError.writeConflict(message: "conflict").stateContent.title, "任务已被外部修改")
        XCTAssertEqual(TaskPanelError.generic(message: "other").stateContent.title, "无法读取任务")

        XCTAssertEqual(TaskPanelError.fileMissing(message: "missing").recoveryActionTitle, "重新选择文件")
        XCTAssertEqual(TaskPanelError.noFileSelected(message: "select").recoveryActionTitle, "选择文件")
        XCTAssertEqual(TaskPanelError.permissionLost(message: "lost").recoveryActionTitle, "重新选择文件")
        XCTAssertEqual(TaskPanelError.markdownFormat(message: "bad").recoveryActionTitle, "重新选择文件")
        XCTAssertEqual(TaskPanelError.writeConflict(message: "conflict").recoveryActionTitle, "重新加载")
    }

    func testSettingsActionCopyStaysExplicitAboutDefaultApp() {
        XCTAssertEqual(SettingsActionTitle.openTaskFile, "在默认 App 中打开")
        XCTAssertEqual(SettingsActionTitle.revealTaskFile, "在 Finder 中显示")
        XCTAssertEqual(SettingsActionTitle.reloadTasks, "重新加载任务")
    }

    func testSettingsViewScrollsWhenContentOverflows() {
        XCTAssertTrue(SettingsLayout.scrollsWhenContentOverflows)
    }

    func testRequiresBuiltInScreenWithTopSafeArea() {
        XCTAssertTrue(
            NotchLayout.isEligible(isBuiltIn: true, topSafeArea: 32)
        )
        XCTAssertFalse(
            NotchLayout.isEligible(isBuiltIn: false, topSafeArea: 32)
        )
        XCTAssertFalse(
            NotchLayout.isEligible(isBuiltIn: true, topSafeArea: 0)
        )
    }

    func testCompactFrameExpandsSymmetricallyAroundPhysicalNotch() {
        let frame = NotchLayout.compactFrame(
            screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            notchWidth: 180,
            notchHeight: 32
        )

        XCTAssertEqual(frame, CGRect(x: 612, y: 950, width: 288, height: 32))
        XCTAssertEqual(frame.midX, 756)
    }

    func testCompactSideWidthLeavesRoomForSmallSummary() {
        XCTAssertEqual(NotchLayout.compactSideWidth, 54)
        XCTAssertEqual(NotchLayout.compactSummaryFontSize, 11)
    }

    func testCompleteCompactStateStaysVisibleButQuieter() {
        XCTAssertEqual(CompactDisplayStyle.activeOpacity, 1)
        XCTAssertLessThan(CompactDisplayStyle.completeOpacity, CompactDisplayStyle.activeOpacity)
        XCTAssertGreaterThanOrEqual(CompactDisplayStyle.completeOpacity, 0.35)
    }

    func testTaskListScrollFadeStaysSubtle() {
        XCTAssertEqual(TaskListScrollFade.height, 18)
        XCTAssertGreaterThan(TaskListScrollFade.opacity, 0)
        XCTAssertLessThanOrEqual(TaskListScrollFade.opacity, 0.18)
    }

    func testNotchWidthUsesAuxiliaryAreaWidths() {
        XCTAssertEqual(
            NotchLayout.notchWidth(
                screenWidth: 1512,
                leftAuxiliaryWidth: 664,
                rightAuxiliaryWidth: 664
            ),
            188
        )
    }

    func testExpandedFrameGrowsDownFromScreenTop() {
        let frame = NotchLayout.expandedFrame(
            screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982)
        )

        XCTAssertEqual(frame, CGRect(x: 576, y: 562, width: 360, height: 420))
    }

    func testPanelFrameAlwaysUsesMaximumExpandedSize() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1512, height: 982)

        XCTAssertEqual(
            NotchLayout.panelFrame(screenFrame: screenFrame),
            NotchLayout.expandedFrame(screenFrame: screenFrame)
        )
    }

    func testWindowUsesSystemStatusBarLevel() {
        XCTAssertEqual(NotchLayout.windowLevel, .statusBar)
    }

    func testPanelDoesNotUseSystemWindowShadow() {
        XCTAssertFalse(NotchLayout.usesWindowShadow)
    }

    func testAnimationStagesContentAfterShape() {
        XCTAssertEqual(NotchAnimation.contentRevealDelay, .milliseconds(70))
        XCTAssertEqual(NotchAnimation.shapeCollapseDelay, .milliseconds(60))
        XCTAssertGreaterThan(NotchAnimation.shapeDampingFraction, 0.9)
    }
}
