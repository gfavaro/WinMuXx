import AppKit
import Common

@MainActor
func dwindleDirectionalFocusTarget(
    from current: Window,
    direction: CardinalDirection,
    excludingMoveNode: TreeNode? = nil,
) -> Window? {
    guard let workspace = current.nodeWorkspace,
          let currentRect = current.lastAppliedLayoutPhysicalRect
    else { return nil }

    let candidates = workspace.rootTilingContainer.allLeafWindowsRecursive.compactMap { window -> (Window, [CGFloat])? in
        guard window != current,
              window.moveNode != excludingMoveNode,
              window.participatesInWorkspaceFocus,
              let rect = window.lastAppliedLayoutPhysicalRect
        else { return nil }

        let deltaX = rect.center.x - currentRect.center.x
        let deltaY = rect.center.y - currentRect.center.y
        let primaryDelta = direction.orientation == .h ? deltaX : deltaY
        guard (direction.isPositive ? primaryDelta > 0 : primaryDelta < 0) else { return nil }

        let crossGap: CGFloat
        let primaryGap: CGFloat
        if direction.orientation == .h {
            crossGap = max(0, max(currentRect.minY - rect.maxY, rect.minY - currentRect.maxY))
            primaryGap = direction == .right
                ? max(0, rect.minX - currentRect.maxX)
                : max(0, currentRect.minX - rect.maxX)
        } else {
            crossGap = max(0, max(currentRect.minX - rect.maxX, rect.minX - currentRect.maxX))
            primaryGap = direction == .down
                ? max(0, rect.minY - currentRect.maxY)
                : max(0, currentRect.minY - rect.maxY)
        }
        let crossDelta = direction.orientation == .h ? rect.center.y - currentRect.center.y : deltaX
        // Prefer a window sharing an edge projection, then the nearest edge and center.
        return (window, [crossGap == 0 ? 0 : 1, crossGap, primaryGap, abs(crossDelta), abs(primaryDelta)])
    }

    return candidates.min { lhs, rhs in
        if lhs.1 != rhs.1 { return lhs.1.lexicographicallyPrecedes(rhs.1) }
        return lhs.0.windowId < rhs.0.windowId
    }?.0
}
