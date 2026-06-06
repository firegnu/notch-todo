import AppKit
import CoreGraphics

enum NotchLayout {
    static let compactSideWidth: CGFloat = 54
    static let compactSummaryFontSize: CGFloat = 11
    static let windowLevel = NSWindow.Level.statusBar
    static let usesWindowShadow = false

    static func isEligible(isBuiltIn: Bool, topSafeArea: CGFloat) -> Bool {
        isBuiltIn && topSafeArea > 0
    }

    static func compactFrame(
        screenFrame: CGRect,
        notchWidth: CGFloat,
        notchHeight: CGFloat
    ) -> CGRect {
        let width = notchWidth + compactSideWidth * 2
        let height = notchHeight
        return CGRect(
            x: screenFrame.midX - width / 2,
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
    }

    static func notchWidth(
        screenWidth: CGFloat,
        leftAuxiliaryWidth: CGFloat,
        rightAuxiliaryWidth: CGFloat
    ) -> CGFloat {
        max(0, screenWidth - leftAuxiliaryWidth - rightAuxiliaryWidth + 4)
    }

    static func expandedFrame(screenFrame: CGRect) -> CGRect {
        let width: CGFloat = 360
        let height = min(420, screenFrame.height - 40)
        return CGRect(
            x: screenFrame.midX - width / 2,
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
    }

    static func panelFrame(screenFrame: CGRect) -> CGRect {
        expandedFrame(screenFrame: screenFrame)
    }
}

struct BuiltInNotchScreen {
    let screen: NSScreen
    let notchWidth: CGFloat
    let notchHeight: CGFloat

    static func current() -> BuiltInNotchScreen? {
        NSScreen.screens.compactMap(make).first
    }

    private static func make(screen: NSScreen) -> BuiltInNotchScreen? {
        guard let number = screen.deviceDescription[.init("NSScreenNumber")] as? NSNumber else {
            return nil
        }

        let isBuiltIn = CGDisplayIsBuiltin(CGDirectDisplayID(number.uint32Value)) != 0
        let topSafeArea = screen.safeAreaInsets.top
        guard NotchLayout.isEligible(isBuiltIn: isBuiltIn, topSafeArea: topSafeArea) else {
            return nil
        }

        let notchWidth: CGFloat
        if let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            notchWidth = NotchLayout.notchWidth(
                screenWidth: screen.frame.width,
                leftAuxiliaryWidth: left.width,
                rightAuxiliaryWidth: right.width
            )
        } else {
            notchWidth = 180
        }

        return BuiltInNotchScreen(
            screen: screen,
            notchWidth: notchWidth,
            notchHeight: topSafeArea
        )
    }
}
