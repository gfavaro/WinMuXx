import AppKit
import Common

/// A split divides its leading child from all children that follow it.
struct DwindleResizeTarget {
    let container: TilingContainer
    let splitIndex: Int
    let orientation: Orientation
    let availableLength: CGFloat
    let leadingLength: CGFloat
    let resizesLeadingChild: Bool
    let resizeEdge: CGFloat

    @MainActor
    func resize(_ units: ResizeCmdArgs.Units) -> Bool {
        guard availableLength > 0 else { return false }
        let currentLength = resizesLeadingChild ? leadingLength : availableLength - leadingLength
        let requestedLength: CGFloat = switch units {
            case .set(let value): CGFloat(value)
            case .add(let value): currentLength + CGFloat(value)
            case .subtract(let value): currentLength - CGFloat(value)
        }
        let ratio = ratio(forLength: requestedLength)
        guard ratio != container.dwindleSplitRatio(at: splitIndex) else { return false }
        if let rect = container.lastAppliedLayoutPhysicalRect, let workspace = container.nodeWorkspace {
            let gaps = ResolvedGaps(gaps: config.gaps, monitor: workspace.workspaceMonitor)
            let before = container.dwindleChildFrames(in: rect, gaps: gaps)
            let after = container.dwindleChildFrames(in: rect, gaps: gaps) {
                $0 == splitIndex ? ratio : container.dwindleSplitRatio(at: $0)
            }
            guard before != after else { return false }
        }
        container.setDwindleSplitRatio(ratio, at: splitIndex)
        return true
    }

    func ratio(forLength length: CGFloat) -> CGFloat {
        guard availableLength > 0 else { return 0.5 }
        let leading = resizesLeadingChild ? length : availableLength - length
        return min(max(leading / availableLength, 0.1), 0.9)
    }
}

extension TreeNode {
    @MainActor
    func dwindleResizeTargets(geometry: [ObjectIdentifier: Rect]? = nil) -> [DwindleResizeTarget] {
        guard let container = parent as? TilingContainer, container.layout == .dwindle,
              let ownIndex, let rect = geometry?[ObjectIdentifier(container)] ?? container.lastAppliedLayoutPhysicalRect,
              let workspace = nodeWorkspace else { return [] }
        let gaps = ResolvedGaps(gaps: config.gaps, monitor: workspace.workspaceMonitor)
        var width = rect.width
        var height = rect.height
        var targets: [DwindleResizeTarget] = []
        for index in 0..<min(ownIndex + 1, max(container.children.count - 1, 0)) {
            guard let childRect = geometry?[ObjectIdentifier(container.children[index])] ?? container.children[index].lastAppliedLayoutPhysicalRect else { return [] }
            let orientation: Orientation = container.dwindleAxis(width: width, height: height)
            let gap = CGFloat(gaps.inner.get(orientation).toDouble())
            let leadingLength = childRect.getDimension(orientation)
            targets.append(DwindleResizeTarget(
                container: container, splitIndex: index, orientation: orientation,
                availableLength: max((orientation == .h ? width : height) - gap, 0),
                leadingLength: leadingLength, resizesLeadingChild: index == ownIndex,
                resizeEdge: (orientation == .h ? childRect.maxX : childRect.maxY) + (index == ownIndex ? 0 : gap),
            ))
            if orientation == .h { width = max(width - leadingLength - gap, 0) }
            else { height = max(height - leadingLength - gap, 0) }
        }
        return targets.reversed()
    }
}

enum WindowResizeCommandTarget {
    case tiles(TreeNode, TilingContainer)
    case dwindle(DwindleResizeTarget)

    var orientation: Orientation {
        switch self {
            case .tiles(_, let parent): parent.orientation
            case .dwindle(let target): target.orientation
        }
    }
}
