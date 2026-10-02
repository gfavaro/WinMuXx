import AppKit
import Common
import ServiceManagement

@MainActor
func syncStartAtLogin() {
    // This fork must never remove the original application's launch agents.
    let service = SMAppService.mainApp
    if config.startAtLogin {
        if isDebug {
            print("'start-at-login = true' has no effect in debug builds")
        } else {
            _ = try? service.register()
        }
    } else {
        _ = try? service.unregister()
    }
}
