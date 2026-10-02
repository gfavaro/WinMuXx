import AppBundle
import SparkleSupport
import SwiftUI

// This file is shared between SPM and xcode project

@main
struct WinMuxApp: App {
    @StateObject var viewModel = TrayMenuModel.shared
    @StateObject var messageModel = MessageModel.shared
    @StateObject var shortcutSettingsModel = ShortcutSettingsModel.shared
    @Environment(\.openWindow) var openWindow: OpenWindowAction

    init() {
        #if !DEBUG
            AutomaticUpdates.start()
        #endif
        initAppBundle()
        #if DEBUG
        installNativeMenuBar()
        #else
        installNativeMenuBar(checkForUpdates: { AutomaticUpdates.checkForUpdates() })
        #endif
    }

    var body: some Scene {
        getShortcutSettingsWindow(model: shortcutSettingsModel)
            .onChange(of: shortcutSettingsModel.openRequestId) { _ in
                openShortcutSettingsWindow(openWindow)
            }
        getMessageWindow(messageModel: messageModel)
            .onChange(of: messageModel.message) { message in
                if message != nil {
                    openWindow(id: messageWindowId)
                }
            }
    }
}
