@testable import AppBundle
import Common
import XCTest

final class ForkIdentityTest: XCTestCase {
    func testForkIdentityDoesNotUseUpstreamSocketOrState() {
        XCTAssertEqual(stableWinMuxAppId, "com.gfavaro.winmux")
        XCTAssertTrue(winMuxAppId.hasPrefix(stableWinMuxAppId))
        XCTAssertTrue(winMuxAppName.hasPrefix("WinMuXx"))
        XCTAssertTrue(socketPath.contains(winMuxAppId))
        XCTAssertFalse(socketPath.contains("com.zimengxiong"))
        XCTAssertEqual(forkRepositoryURL, "https://github.com/gfavaro/WinMuXx")
    }

    func testForkConfigurationHasAnIndependentOwnedDirectory() {
        XCTAssertEqual(generatedConfigDirectoryName, "winmux-gf")
        XCTAssertEqual(generatedConfigFileName, "winmux.toml")
        XCTAssertEqual(generatedConfigUrl().deletingLastPathComponent().lastPathComponent, "winmux-gf")
        XCTAssertTrue(legacyConfigCandidateUrls().contains { $0.path.hasSuffix("/winmux/winmux.toml") })
    }
}
