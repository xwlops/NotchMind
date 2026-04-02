import XCTest
@testable import NotchMind

final class NotchGeometryTests: XCTestCase {

    func testGetNotchHeight() {
        let height = NotchGeometry.getNotchHeight()
        XCTAssertGreaterThanOrEqual(height, 0, "Notch height should be non-negative")

        // On macOS 12+, we expect a positive height if running on a device with notch
        print("Detected notch height: \(height)")
    }

    func testGetNotchRect() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let notchRect = NotchGeometry.getNotchRect(for: screen)

        if notchRect != CGRect.zero {
            XCTAssertTrue(notchRect.width > 0 && notchRect.height > 0, "Notch rect should have positive dimensions when present")
            XCTAssertTrue(screen.frame.contains(notchRect), "Notch rect should be within screen bounds")
        }
    }

    func testIsPointInNotch() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let notchRect = NotchGeometry.getNotchRect(for: screen)

        if !notchRect.equalTo(CGRect.zero) {
            let centerPoint = CGPoint(x: notchRect.midX, y: notchRect.midY)
            XCTAssertTrue(NotchGeometry.isPointInNotch(centerPoint, screen: screen), "Center of notch should be in notch")

            let outsidePoint = CGPoint(x: 0, y: 0)
            XCTAssertFalse(NotchGeometry.isPointInNotch(outsidePoint, screen: screen), "Point at origin should not be in notch")
        }
    }

    func testGetSafeAreaRect() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let testFrame = CGRect(x: 0, y: 0, width: 400, height: 300)
        let safeArea = NotchGeometry.getSafeAreaRect(for: testFrame, screen: screen)

        XCTAssertTrue(testFrame.width == safeArea.width || safeArea.height < testFrame.height,
                      "Safe area should have same width but possibly reduced height if overlapping notch")
    }
}