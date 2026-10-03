@testable import AppBundle
import AppKit
import Combine
import SwiftUI
import XCTest

@MainActor
final class WorkspaceSidebarAppearanceTest: XCTestCase {
    func testCompactControlsFitEverySupportedRailWidth() {
        for width in [28, 36, 44, 50, 56, 120] {
            let metrics = WorkspaceSidebarCompactMetrics(width: CGFloat(width))
            XCTAssertLessThanOrEqual(metrics.badgeSize + 2 * metrics.innerInset, metrics.sectionWidth)
            XCTAssertLessThanOrEqual(metrics.sectionWidth + 2 * workspaceSidebarCompactRailHorizontalInset, CGFloat(width))
            XCTAssertGreaterThan(metrics.badgeSize, 0)
        }
    }

    func testCompactPresetsScaleControlsAndKeepMediumAtExistingSize() {
        let small = WorkspaceSidebarCompactMetrics(width: 36)
        let medium = WorkspaceSidebarCompactMetrics(width: 44)
        let large = WorkspaceSidebarCompactMetrics(width: 56)
        XCTAssertEqual(medium.fontSize, 18)
        XCTAssertEqual(medium.badgeSize, workspaceSidebarBadgeWidth)
        XCTAssertEqual(medium.headerHeight, workspaceSidebarWorkspaceSectionHeaderHeight)
        XCTAssertLessThan(small.fontSize, medium.fontSize)
        XCTAssertLessThan(medium.fontSize, large.fontSize)
        XCTAssertLessThan(small.headerHeight, medium.headerHeight)
        XCTAssertLessThan(medium.headerHeight, large.headerHeight)
    }

    func testConfigurationChangePublishesWithoutWorkspaceChanges() {
        let model = TrayMenuModel()
        var updates = 0
        let subscription = model.objectWillChange.sink { updates += 1 }
        var updated = WorkspaceSidebarConfiguration.empty
        updated.appearance = .custom
        updated.chromeStyle = .solid
        model.setIfChanged(\.workspaceSidebarConfiguration, updated)
        XCTAssertEqual(updates, 1)
        XCTAssertEqual(workspaceSidebarSnapshot(from: model).configuration, updated)
        model.setIfChanged(\.workspaceSidebarConfiguration, updated)
        XCTAssertEqual(updates, 1)
        XCTAssertTrue(model.workspaceSidebarWorkspaces.isEmpty)
        withExtendedLifetime(subscription) {}
    }

    func testSystemAppearanceIsDefaultAndDoesNotChangeSharedChrome() {
        let (parsed, errors) = parseConfig("[workspace-sidebar]\nchrome-style = 'solid'\n")
        XCTAssertEqual(errors, [])
        XCTAssertEqual(parsed.workspaceSidebar.appearance, .system)
        XCTAssertEqual(parsed.workspaceSidebar.chromeStyle, .solid)
        XCTAssertEqual(WorkspaceSidebarConfiguration.empty.appearance, .system)
    }

    func testBothAppearanceOptionsParseAndPreserveChromeSettings() {
        for appearance in WorkspaceSidebarAppearance.allCases {
            let (parsed, errors) = parseConfig("""
                [workspace-sidebar]
                appearance = '\(appearance.rawValue)'
                chrome-style = 'solid'
                solid-chrome-color = 'green'
                """)
            XCTAssertEqual(errors, [])
            XCTAssertEqual(parsed.workspaceSidebar.appearance, appearance)
            XCTAssertEqual(parsed.workspaceSidebar.chromeStyle, .solid)
            XCTAssertEqual(parsed.workspaceSidebar.solidChromeColor, .green)
        }
    }

    func testInvalidAppearanceIsRejected() {
        for value in ["'native'", "true", "3"] {
            let (_, errors) = parseConfig("[workspace-sidebar]\nappearance = \(value)\n")
            XCTAssertFalse(errors.isEmpty)
        }
    }

    func testCustomChromeSupportsLegacyLiquidGlassKey() {
        let (parsed, errors) = parseConfig("""
            [workspace-sidebar]
            appearance = 'custom'
            use-liquid-glass = false
            """)
        XCTAssertEqual(errors, [])
        XCTAssertEqual(parsed.workspaceSidebar.appearance, .custom)
        XCTAssertEqual(parsed.workspaceSidebar.chromeStyle, .solid)
    }

    func testSnapshotReflectsAppearanceChangeWithoutChangingSharedChrome() {
        let previous = config
        defer { config = previous }
        config.workspaceSidebar.chromeStyle = .solid
        config.workspaceSidebar.appearance = .custom
        let before = workspaceSidebarConfiguration()
        config.workspaceSidebar.appearance = .system
        let after = workspaceSidebarConfiguration()
        XCTAssertNotEqual(before, after)
        XCTAssertEqual(after.appearance, .system)
        XCTAssertEqual(after.chromeStyle, before.chromeStyle)
        XCTAssertEqual(after.collapsedWidth, before.collapsedWidth)
        XCTAssertEqual(after.expandedWidth, before.expandedWidth)
    }

    func testNativeMaterialAndInactivePanelBehavior() {
        let view = NSVisualEffectView()
        WorkspaceSidebarVisualEffect().configure(view)
        XCTAssertEqual(view.material, .sidebar)
        XCTAssertEqual(view.blendingMode, .behindWindow)
        XCTAssertEqual(view.state, .active)
        XCTAssertFalse(view.isEmphasized)
        XCTAssertNil(view.appearance)
    }

    func testBackgroundDefaultsAndAllOptionsParse() {
        let (defaults, defaultErrors) = parseConfig("[workspace-sidebar]\n")
        XCTAssertEqual(defaultErrors, [])
        XCTAssertEqual(defaults.workspaceSidebar.background, .sidebar)
        XCTAssertEqual(WorkspaceSidebarConfiguration.empty.background, .sidebar)
        for background in WorkspaceSidebarBackground.allCases {
            let (parsed, errors) = parseConfig("[workspace-sidebar]\nbackground = '\(background.rawValue)'\n")
            XCTAssertEqual(errors, [])
            XCTAssertEqual(parsed.workspaceSidebar.background, background)
            XCTAssertEqual(parsed.workspaceSidebar.appearance, .system)
        }
        for value in ["'glass'", "true", "3"] {
            let (_, errors) = parseConfig("[workspace-sidebar]\nbackground = \(value)\n")
            XCTAssertFalse(errors.isEmpty)
        }
    }

    func testBackgroundSnapshotTriggersReloadWithoutChangingChrome() {
        let previous = config
        defer { config = previous }
        config.workspaceSidebar.background = .sidebar
        let before = workspaceSidebarConfiguration()
        config.workspaceSidebar.background = .transparent
        let after = workspaceSidebarConfiguration()
        XCTAssertNotEqual(before, after)
        XCTAssertEqual(after.background, .transparent)
        XCTAssertEqual(after.chromeStyle, before.chromeStyle)
        XCTAssertEqual(after.appearance, before.appearance)
    }

    func testMenuBarApproximationUsesNativeHeaderMaterial() {
        let view = NSVisualEffectView()
        WorkspaceSidebarVisualEffect(background: .menuBar).configure(view)
        XCTAssertEqual(view.material, .headerView)
        XCTAssertEqual(view.blendingMode, .behindWindow)
        XCTAssertEqual(view.state, .active)
        WorkspaceSidebarVisualEffect(background: .sidebar).configure(view)
        XCTAssertEqual(view.material, .sidebar)
    }

    func testExpandedTransparentSurfaceRetainsBlurAndReducedOpacity() {
        let view = NSVisualEffectView()
        WorkspaceSidebarVisualEffect(frosted: true).configure(view)
        XCTAssertEqual(view.material, .hudWindow)
        XCTAssertEqual(view.blendingMode, .behindWindow)
        XCTAssertEqual(view.state, .active)
        XCTAssertEqual(view.alphaValue, 0.93, accuracy: 0.001)
        WorkspaceSidebarVisualEffect().configure(view)
        XCTAssertEqual(view.alphaValue, 1)
        XCTAssertEqual(view.material, .sidebar)
    }

    func testBackgroundEditPreservesCustomAppearanceAndBindings() {
        let updated = updateSettingsScalarConfig(
            in: "[workspace-sidebar]\nappearance = 'custom'\n[mode.main.binding]\nalt-h = 'focus left'\n",
            section: "workspace-sidebar", key: "background", renderedValue: "'menu-bar'"
        )
        let (parsed, errors) = parseConfig(updated)
        XCTAssertEqual(errors, [])
        XCTAssertEqual(parsed.workspaceSidebar.background, .menuBar)
        XCTAssertEqual(parsed.workspaceSidebar.appearance, .custom)
        XCTAssertTrue(updated.contains("alt-h = 'focus left'"))
    }

    func testAppearanceEditPreservesOtherSettingsAndBindings() {
        let updated = updateSettingsScalarConfig(
            in: """
                [workspace-sidebar]
                chrome-style = 'solid'
                width = 300
                [mode.main.binding]
                alt-h = 'focus left'
                """,
            section: "workspace-sidebar",
            key: "appearance",
            renderedValue: "'custom'"
        )
        let (parsed, errors) = parseConfig(updated)
        XCTAssertEqual(errors, [])
        XCTAssertEqual(parsed.workspaceSidebar.appearance, .custom)
        XCTAssertEqual(parsed.workspaceSidebar.chromeStyle, .solid)
        XCTAssertEqual(parsed.workspaceSidebar.width, 300)
        XCTAssertTrue(updated.contains("alt-h = 'focus left'"))
    }

    func testSemanticTextAndCustomPalette() {
        let system = WorkspaceSidebarPalette(appearance: .system)
        XCTAssertEqual(system.foreground, .primary)
        XCTAssertEqual(system.text(opacity: 0.9), .primary)
        XCTAssertEqual(system.text(opacity: 0.4), .secondary)
        XCTAssertEqual(system.text(opacity: 0), .clear)
        let highContrast = WorkspaceSidebarPalette(appearance: .system, increasedContrast: true)
        XCTAssertEqual(highContrast.text(opacity: 0.4), .primary)
        let custom = WorkspaceSidebarPalette(appearance: .custom)
        XCTAssertEqual(custom.foreground, .white)
        XCTAssertEqual(custom.text(opacity: 0.4), .white.opacity(0.4))
    }
}
