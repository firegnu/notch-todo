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
