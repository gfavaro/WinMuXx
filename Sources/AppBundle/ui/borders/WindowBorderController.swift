import AppKit
import Common

/// Nonactivating, click-through panels ordered immediately beside each native window.
@MainActor
final class WindowBorderController {
    static let shared = WindowBorderController()
    private var panels: [UInt32: WindowBorderPanel] = [:]
    private var refreshScheduled = false

    func refresh() {
        guard !isUnitTest, !refreshScheduled else { return }
        refreshScheduled = true
        // Let native frame/focus updates settle; coalesce refreshes into one WindowServer query.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) { [weak self] in
            guard let self else { return }
            self.refreshScheduled = false
            self.updateBorders()
        }
    }

    private func updateBorders() {
        let settings = config.windowBorders
        guard !isUnitTest, TrayMenuModel.shared.isEnabled, settings.enabled, settings.width > 0,
              !shouldSuppressChromeForNativeFullscreenContent else {
            clear()
            return
        }
        // WindowServer provides actual positions, including floating windows, without AX requests.
        let nativeWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        var frames: [UInt32: CGRect] = [:]
        for entry in nativeWindows {
            guard let id = entry[kCGWindowNumber as String] as? NSNumber,
                  let bounds = entry[kCGWindowBounds as String] as? NSDictionary,
                  let frame = CGRect(dictionaryRepresentation: bounds) else { continue }
            frames[id.uint32Value] = frame
        }
        var visibleIds = Set<UInt32>()
        for workspace in Workspace.all where workspace.isVisible {
            for window in workspace.allLeafWindowsRecursive {
                if let bundleId = window.app.rawAppBundleId, settings.excludeApps.contains(bundleId) { continue }
                guard window.participatesInWorkspaceFocus, !window.isHiddenInCorner, !window.isFullscreen,
                      let nativeFrame = frames[window.windowId], nativeFrame.width > 0, nativeFrame.height > 0 else { continue }
                visibleIds.insert(window.windowId)
                let panel = panels[window.windowId] ?? WindowBorderPanel()
                panels[window.windowId] = panel
                let frame = CGRect(x: nativeFrame.minX, y: mainMonitor.height - nativeFrame.maxY,
                                   width: nativeFrame.width, height: nativeFrame.height)
                panel.update(frame: frame, windowId: window.windowId, active: focus.windowOrNil?.windowId == window.windowId, settings: settings)
            }
        }
        for id in Array(panels.keys) where !visibleIds.contains(id) {
            panels.removeValue(forKey: id)?.close()
        }
    }

    private func clear() {
        for panel in panels.values { panel.close() }
        panels.removeAll()
    }
}

@MainActor
private final class WindowBorderPanel: NSPanelHud {
    private let borderView = WindowBorderView()
    private var previousSize: CGSize?

    override init() {
        super.init()
        level = .normal
        hasShadow = false
        ignoresMouseEvents = true
        isFloatingPanel = false
        isExcludedFromWindowsMenu = true
        animationBehavior = .none
        collectionBehavior = [.stationary, .ignoresCycle, .fullScreenAuxiliary]
        contentView = borderView
        borderView.autoresizingMask = [.width, .height]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func update(frame: CGRect, windowId: UInt32, active: Bool, settings: WindowBordersConfig) {
        let width = CGFloat(settings.width)
        setFrame(frame.insetBy(dx: -width, dy: -width), display: false)
        if previousSize != frame.size || borderView.settings != settings || borderView.active != active {
            borderView.settings = settings
            borderView.active = active
            borderView.needsDisplay = true
            previousSize = frame.size
        }
        order(settings.order == .above ? .above : .below, relativeTo: Int(windowId))
    }
}

@MainActor
private final class WindowBorderView: NSView {
    var settings = WindowBordersConfig()
    var active = false

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        bounds.fill(using: .copy)
        let hex = active ? settings.activeColor : settings.inactiveColor
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0
        let rgb = hex.count == 9 ? value >> 8 : value
        let alpha = hex.count == 9 ? CGFloat(value & 255) / 255 : 1
        NSColor(srgbRed: CGFloat((rgb >> 16) & 255) / 255,
                green: CGFloat((rgb >> 8) & 255) / 255,
                blue: CGFloat(rgb & 255) / 255, alpha: alpha).setStroke()
        let width = CGFloat(settings.width)
        let radius = systemWindowCornerRadius() + width / 2
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: width / 2, dy: width / 2), xRadius: radius, yRadius: radius)
        path.lineWidth = width
        path.stroke()
    }
}
