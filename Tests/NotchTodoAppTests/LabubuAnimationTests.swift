import XCTest
@testable import NotchTodoApp

final class LabubuAnimationTests: XCTestCase {
    func testAnimationUsesLowFrequencyFourFrameCycle() {
        XCTAssertEqual(
            LabubuAnimation.frames,
            [.idle, .blink, .earDip, .recover]
        )
        XCTAssertEqual(LabubuAnimation.idleDuration, .milliseconds(4_600))
        XCTAssertEqual(LabubuAnimation.frameDuration, .milliseconds(120))
    }
}
