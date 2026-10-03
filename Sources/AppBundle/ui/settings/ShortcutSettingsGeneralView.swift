import AppKit
import Common
import MASShortcut
import SwiftUI

struct ShortcutGeneralView: View {
    @ObservedObject var model: ShortcutSettingsModel
    @State private var displayStyle = ExperimentalUISettings().displayStyle
    @State private var menuBarIndicator = ExperimentalUISettings().indicator
    @State private var iconAppearance = ExperimentalUISettings().iconAppearance
    @State private var sidebarPosition = config.workspaceSidebar.position
    @State private var sidebarHeightMode = config.workspaceSidebar.heightMode ?? .standard
    @State private var projectDeletionAction = config.workspaceSidebar.projectDeletionAction

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GeneralSection(title: "Management") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Deleting projects")
                                Text("Close windows keeps app confirmation dialogs visible and aborts deletion if a window stays open.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Picker("", selection: $projectDeletionAction) {
                                ForEach(WorkspaceProjectDeletionAction.allCases) { action in
                                    Text(action.settingsTitle).tag(action)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 210)
                            .onChange(of: projectDeletionAction) { newValue in
                                setProjectDeletionAction(newValue)
                            }
                        }
                    }
                }

                GeneralSection(title: "Appearance") {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Menu bar style")
                            Spacer()
                            Picker("", selection: $displayStyle) {
                                ForEach(MenuBarStyle.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 180)
                            .onChange(of: displayStyle) { newValue in
                                var settings = ExperimentalUISettings()
                                settings.displayStyle = newValue
                                TrayMenuModel.shared.experimentalUISettings = settings
                                updateTrayText()
                            }
                        }

                        Picker("Menu bar indicator", selection: $menuBarIndicator) {
                            ForEach(MenuBarIndicator.allCases) { indicator in
                                Text(indicator.title).tag(indicator)
                            }
                        }
                        .onChange(of: menuBarIndicator) { value in
                            var settings = ExperimentalUISettings()
                            settings.indicator = value
                            TrayMenuModel.shared.experimentalUISettings = settings
                            updateTrayText()
                        }
                        Text("Workspace shows the label initial, or its number when unlabeled, on the focused display.")
                            .font(.caption).foregroundStyle(.secondary)
                        if menuBarIndicator == .icon {
                            HStack {
                                Text("Menu bar icon")
                                Spacer()
                                Picker("", selection: $iconAppearance) {
                                    ForEach(MenuBarIconAppearance.allCases) { appearance in
                                        Text(appearance.title).tag(appearance)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                                .onChange(of: iconAppearance) { newValue in
                                    var settings = ExperimentalUISettings()
                                    settings.iconAppearance = newValue
                                    TrayMenuModel.shared.experimentalUISettings = settings
                                }
                            }
                        }
                        Picker("Sidebar position", selection: $sidebarPosition) {
                            Text("Left").tag(WorkspaceSidebarPosition.left)
                            Text("Right").tag(WorkspaceSidebarPosition.right)
                        }
                        .onChange(of: sidebarPosition) { value in setSidebarGeometry(key: "position", value: value.rawValue) }
                        Picker("Sidebar height", selection: $sidebarHeightMode) {
                            Text("Standard").tag(WorkspaceSidebarHeightMode.standard)
                            Text("Centered").tag(WorkspaceSidebarHeightMode.centered)
                            Text("Full").tag(WorkspaceSidebarHeightMode.full)
                        }
                        .onChange(of: sidebarHeightMode) { value in setSidebarGeometry(key: "height-mode", value: value.rawValue) }
                        Text("The menu bar always stays clear. Centered fits content up to 90% of the safe display height.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                GeneralSection(title: "Configuration") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button("Open Config File") { openConfigAction() }
                            Button("Reload Config") { reloadConfigAction() }
                        }
                        
                        Text("Shortcuts are edited here. Advanced configuration remains in `winmux.toml`.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(24)
        }
    }

    private func setSidebarGeometry(key: String, value: String) {
        Task { @MainActor in
            do {
                let targetUrl = try persistWorkspaceSidebarGeometry(key: key, value: value)
                _ = try await reloadConfig(forceConfigUrl: targetUrl)
                WorkspaceSidebarPanel.refreshAll()
            } catch {
                model.errorMessage = error.localizedDescription
            }
        }
    }

    private func setProjectDeletionAction(_ action: WorkspaceProjectDeletionAction) {
        Task { @MainActor in
            do {
                let targetUrl = try persistWorkspaceSidebarProjectDeletionAction(action)
                _ = try await reloadConfig(forceConfigUrl: targetUrl)
                projectDeletionAction = config.workspaceSidebar.projectDeletionAction
            } catch {
                model.errorMessage = error.localizedDescription
            }
        }
    }

    private func openConfigAction() {
        switch findCustomConfigUrl() {
            case .file(let url):
                NSWorkspace.shared.open(url)
            case .noCustomConfigExists:
                let createdUrl = try? ensureBootstrapConfigExistsIfNeeded()
                NSWorkspace.shared.open(createdUrl ?? preferredEditableConfigUrl())
            case .ambiguousConfigError:
                NSWorkspace.shared.open(preferredEditableConfigUrl())
        }
    }

    private func reloadConfigAction() {
        Task {
            if let token: RunSessionGuard = .isServerEnabled {
                try await runLightSession(.menuBarButton, token) {
                    let isOk = try await reloadConfig()
                    if isOk {
                        sidebarPosition = config.workspaceSidebar.position
                        sidebarHeightMode = config.workspaceSidebar.heightMode ?? .standard
                        projectDeletionAction = config.workspaceSidebar.projectDeletionAction
                        model.reload()
                    }
                }
            }
        }
    }
}

private extension WorkspaceProjectDeletionAction {
    var settingsTitle: String {
        switch self {
            case .closeWindows:
                "Close project windows"
            case .moveWindowsToFallback:
                "Move windows elsewhere"
        }
    }
}

struct GeneralSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            VStack(spacing: 0) {
                content
                    .padding(14)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
            )
        }
    }
}
