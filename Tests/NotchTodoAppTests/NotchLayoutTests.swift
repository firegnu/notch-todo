import AppKit
import XCTest
@testable import NotchTodoApp

final class NotchLayoutTests: XCTestCase {
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

    func testCompactFrameIsCenteredAtTopAndIncludesNotchWidth() {
        let frame = NotchLayout.compactFrame(
            screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            notchWidth: 180,
            notchHeight: 32
        )

        XCTAssertEqual(frame, CGRect(x: 608, y: 950, width: 296, height: 32))
    }

    func testExpandedFrameGrowsDownFromScreenTop() {
        let frame = NotchLayout.expandedFrame(
            screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982)
        )

        XCTAssertEqual(frame, CGRect(x: 576, y: 562, width: 360, height: 420))
    }
}
