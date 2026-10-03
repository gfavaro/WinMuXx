import AppKit

/// All modes retain the menu-bar reveal area, including when macOS auto-hides it.
func workspaceSidebarPanelFrame(
    screen: CGRect,
    menuBarHeight: CGFloat,
    config: WorkspaceSidebarConfig,
    contentHeight: CGFloat
) -> CGRect {
    let reserve = min(max(0, menuBarHeight, config.heightMode == nil ? CGFloat(config.menuBarReserveHeight) : 0), max(0, screen.height - 1))
    let availableHeight = max(1, screen.height - reserve)
    let height = config.heightMode == .centered
        ? min(max(1, contentHeight), availableHeight * 0.9)
        : availableHeight
    let width = CGFloat(config.width) * 2
    return CGRect(
        x: config.position == .left ? screen.minX : screen.maxX - width,
        y: screen.minY + (availableHeight - height) / 2,
        width: width,
        height: height
    )
}

func workspaceSidebarVisibleFrame(panel: CGRect, width: CGFloat, position: WorkspaceSidebarPosition) -> CGRect {
    let width = max(0, min(width, panel.width))
    return CGRect(x: position == .left ? panel.minX : panel.maxX - width, y: panel.minY, width: width, height: panel.height)
}
