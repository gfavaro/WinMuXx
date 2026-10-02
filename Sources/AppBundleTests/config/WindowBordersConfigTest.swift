@testable import AppBundle
import XCTest

@MainActor
final class WindowBordersConfigTest: XCTestCase {
    func testDinkyConfigurationSupportsFractionalWidthAlphaAndExclusions() {
        let (config, errors) = parseConfig("""
        [borders]
        enabled = true
        width = 4.5
        active-color = '#e1e3e480'
        inactive-color = '#494d64'
        order = 'above'
        exclude-apps = ['com.apple.finder', 'com.mitchellh.ghostty']
        """)
        XCTAssertTrue(errors.isEmpty, "\(errors)")
        XCTAssertEqual(config.windowBorders.width, 4.5)
        XCTAssertEqual(config.windowBorders.activeColor, "#E1E3E480")
        XCTAssertEqual(config.windowBorders.order, .above)
        XCTAssertEqual(config.windowBorders.excludeApps, ["com.apple.finder", "com.mitchellh.ghostty"])
    }

    func testDefaultsMatchDinkyAndZeroWidthIsAccepted() {
        let (config, errors) = parseConfig("[borders]\nwidth = 0")
        XCTAssertTrue(errors.isEmpty)
        XCTAssertEqual(config.windowBorders.width, 0)
        XCTAssertEqual(config.windowBorders.activeColor, "#E1E3E4")
        XCTAssertEqual(config.windowBorders.inactiveColor, "#494D64")
        XCTAssertEqual(config.windowBorders.order, .below)
        XCTAssertTrue(config.windowBorders.enabled)
    }

    func testInvalidBorderSettingsAreRejected() {
        for setting in ["width = -1", "width = nan", "order = 'front'", "active-color = '#xyzxyz'", "inactive-color = '#12345'", "exclude-apps = [42]"] {
            let (_, errors) = parseConfig("[borders]\n\(setting)")
            XCTAssertFalse(errors.isEmpty, setting)
        }
    }
}
