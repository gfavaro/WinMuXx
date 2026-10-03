@testable import AppBundle
import SwiftUI
import XCTest

@MainActor
final class WorkspaceSidebarOverrideTest: XCTestCase {
    func testCompactAndExpandedClicksRequireExplicitOverride() {
        let workspace = WorkspaceSidebarWorkspaceViewModel(
            name: "remote", projectId: workspaceProjectDefaultId, displayName: "Remote",
            sidebarLabel: "Remote", isGeneratedName: false,
            monitorScopeId: "monitor:1920.0,0.0", monitorName: "External Display",
            isFocused: false, isVisible: true, items: [])
        for progress: CGFloat in [0, 1] {
            var pending: String?
            var actions: [WorkspaceSidebarAction] = []
            let section = WorkspaceSidebarWorkspaceSection(
                workspace: workspace, dragPreview: nil, expansionProgress: progress,
                layout: .empty, emitsDropTarget: false, isFromOtherDisplay: false,
                isInUseOnOtherDisplay: true, isOnFocusedMonitor: false,
                allowsWorkspaceActivation: true, isPinnedActiveWorkspace: false,
                isActiveOnTargetMonitor: false, projectContextLabel: nil, projectContextColor: nil,
                renamingWorkspaceName: .constant(nil), renamingWorkspaceText: .constant(""),
                onBeginRenameWorkspace: {}, onCommitRenameWorkspace: {}, onCancelRenameWorkspace: {},
                selectedSearchTarget: nil, isSearchFiltering: false,
                activeInUseOverrideWorkspaceName: Binding(get: { pending }, set: { pending = $0 }),
                actions: WorkspaceSidebarActions(send: { actions.append($0) }))
            section.handleSectionClick()
            XCTAssertEqual(pending, workspace.name)
            XCTAssertTrue(actions.isEmpty, "A click must request confirmation before activating or swapping")
            XCTAssertEqual(section.inUseOverrideText, "In use on External Display")
        }
    }
}
