import AppKit
import Common

struct WorkspaceBackAndForthCommand: Command {
    let args: WorkspaceBackAndForthCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        activatePreviousWorkspace(on: focus.workspace.workspaceMonitor)
    }
}

@MainActor
func activatePreviousWorkspace(on monitor: Monitor) -> Bool {
    guard let previousId = winMuxWorkspaceState.monitorViewportsById[MonitorViewportId(monitor)]?.previousWorkspaceId,
          let workspace = winMuxWorkspaceState.workspaceById[previousId], !workspace.isArchived,
          workspace != monitor.activeWorkspace else { return false }
    return activateWorkspaceForUser(workspace, on: monitor)
}
