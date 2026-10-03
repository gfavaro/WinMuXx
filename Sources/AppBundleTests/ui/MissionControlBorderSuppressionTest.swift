@testable import AppBundle
import AppKit
import XCTest

final class MissionControlBorderSuppressionTest: XCTestCase {
    func testDisplaySizedWindowManagerLevelNineteenSuppressesBorders() {
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let entry: [String: Any] = [
            kCGWindowOwnerPID as String: NSNumber(value: 42),
            kCGWindowLayer as String: NSNumber(value: 19),
            kCGWindowBounds as String: frame.dictionaryRepresentation,
        ]

        XCTAssertTrue(isMissionControlVisible(
            [entry],
            screenSizes: [frame.size],
            bundleIdentifierForPID: { $0 == 42 ? "com.apple.WindowManager" : nil },
        ))
    }

    func testOrdinaryWindowManagerWindowDoesNotSuppressBorders() {
        let frame = CGRect(x: 0, y: 0, width: 800, height: 600)
        let entry: [String: Any] = [
            kCGWindowOwnerPID as String: NSNumber(value: 42),
            kCGWindowLayer as String: NSNumber(value: 0),
            kCGWindowBounds as String: frame.dictionaryRepresentation,
        ]

        XCTAssertFalse(isMissionControlVisible(
            [entry],
            screenSizes: [CGSize(width: 1440, height: 900)],
            bundleIdentifierForPID: { _ in "com.apple.WindowManager" },
        ))
    }
}
