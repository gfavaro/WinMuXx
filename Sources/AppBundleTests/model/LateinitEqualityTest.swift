import Common
import XCTest

final class LateinitEqualityTest: XCTestCase {
    func testInitializedValuesCompareTheirContents() {
        XCTAssertEqual(Lateinit.initialized(1), .initialized(1))
        XCTAssertNotEqual(Lateinit.initialized(1), .initialized(2))
    }

    func testInitializationStatesCompareWithoutReadingUninitializedValues() {
        XCTAssertEqual(Lateinit<Int>.uninitialized, .uninitialized)
        XCTAssertNotEqual(Lateinit<Int>.uninitialized, .initialized(1))
        XCTAssertNotEqual(Lateinit<Int>.initialized(1), .uninitialized)
    }
}
