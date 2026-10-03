import SwiftUI

struct ShortcutGeneralSettingsView: View {
    @ObservedObject var model: ShortcutSettingsModel
    @State private var startAtLogin = config.startAtLogin
    @State private var autoReloadConfig = config.autoReloadConfig

    var body: some View {
        SettingsScrollView {
            if let error = model.errorMessage {
                SettingsSection("Could not save setting") {
                    Text(error).foregroundStyle(.red).textSelection(.enabled)
                }
            }
            SettingsSection("Startup") {
                SettingsToggle("Start at login", isOn: $startAtLogin, help: "Launch WinMuxX after you sign in.") {
                    persistRootBool("start-at-login", startAtLogin)
                }
                SettingsToggle("Reload config when it changes", isOn: $autoReloadConfig, help: "Apply valid edits saved from another editor automatically.") {
                    persistRootBool("auto-reload-config", autoReloadConfig)
                }
            }
        }
        .navigationTitle("General")
        .id(model.settingsRevision)
    }

    private func persistRootBool(_ key: String, _ value: Bool) {
        persistSettingsConfig(section: nil, key: key, renderedValue: value ? "true" : "false", model: model)
    }
}

struct ShortcutBehaviorSettingsView: View {
    @ObservedObject var model: ShortcutSettingsModel
    @State private var doubleSidedWindows = ExperimentalUISettings().doubleSidedWindows
    @State private var automaticallyTileNewWindows = config.automaticallyTileNewWindows
    @State private var autoAddNewWindowsToTabGroup = config.autoAddNewWindowsToTabGroup
    @State private var enableShakeToToggleTiling = config.enableShakeToToggleTiling
    @State private var automaticallyUnhideMacosHiddenApps = config.automaticallyUnhideMacosHiddenApps
    @State private var defaultLayout = config.defaultRootContainerLayout
    @State private var defaultOrientation = config.defaultRootContainerOrientation
    @State private var flattenContainers = config.enableNormalizationFlattenContainers
    @State private var normalizeNestedContainers = config.enableNormalizationOppositeOrientationForNestedContainers
    @State private var focusFollowsMouse = config.focusFollowsMouse
    @State private var focusFollowsMouseDwell = config.focusFollowsMouseDwell

    var body: some View {
        SettingsScrollView {
            if let error = model.errorMessage {
                SettingsSection("Could not save setting") {
                    Text(error).foregroundStyle(.red).textSelection(.enabled)
                }
            }
            SettingsSection("New windows") {
                SettingsToggle("Tile new windows automatically", isOn: $automaticallyTileNewWindows, help: "Place new windows in the current tiled layout.") { persistRootBool("automatically-tile-new-windows", automaticallyTileNewWindows) }
                SettingsToggle("Add new windows to the current tab group", isOn: $autoAddNewWindowsToTabGroup, help: "Keep new windows in the selected stack instead of creating a new tile.") { persistRootBool("auto-add-new-windows-to-tab-group", autoAddNewWindowsToTabGroup) }
                SettingsToggle("Unhide macOS-hidden apps", isOn: $automaticallyUnhideMacosHiddenApps, help: "Restore apps macOS has hidden when they receive focus.") { persistRootBool("automatically-unhide-macos-hidden-apps", automaticallyUnhideMacosHiddenApps) }
            }
            SettingsSection("Pointer focus") {
                SettingsToggle("Focus windows under the pointer", isOn: $focusFollowsMouse, help: "Focus the tiled window after the pointer rests over it.") {
                    persistRootBool("focus-follows-mouse", focusFollowsMouse)
                }
                SettingsStepper("Hover delay", value: $focusFollowsMouseDwell, range: 0...2000, help: "Time the pointer must remain still before focusing the window.", unit: "ms") {
                    persistRootInt("focus-follows-mouse-dwell", focusFollowsMouseDwell)
                }
                .disabled(!focusFollowsMouse)
                Text("A delay of 0 focuses immediately. Mouse clicks and window manipulation always take priority.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            SettingsSection("Window pairs") {
                SettingsToggle("Double-sided windows", isOn: $doubleSidedWindows, help: "Replace two-window tab strips with two sides. Option-click anywhere in the window or press Option-Tab to flip.") {
                    var settings = ExperimentalUISettings()
                    settings.doubleSidedWindows = doubleSidedWindows
                    if doubleSidedWindows { requestScreenRecordingPermissionsIfNeeded() }
                    scheduleRefreshSession(.menuBarButton)
                }
                Text("Option-click anywhere in the window or press Option-Tab to flip between two windows. Three or more windows use tabs. Window tabs must be enabled. Rotation uses Screen Recording access and respects Reduce Motion.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
            }
            SettingsSection("Advanced layout") {
                SettingsToggle("Shake to toggle tiling", isOn: $enableShakeToToggleTiling, help: "Shake a window by its title bar to switch between floating and tiled.") { persistRootBool("enable-shake-to-toggle-tiling", enableShakeToToggleTiling) }
                DisclosureGroup("Container normalization") {
                SettingsToggle("Flatten matching containers", isOn: $flattenContainers, help: "Simplify adjacent containers with the same layout orientation.") { persistRootBool("enable-normalization-flatten-containers", flattenContainers) }
                SettingsToggle("Normalize nested orientations", isOn: $normalizeNestedContainers, help: "Avoid nested tiled containers with the same orientation.") { persistRootBool("enable-normalization-opposite-orientation-for-nested-containers", normalizeNestedContainers) }
                }
            }
            SettingsSection("Default layout") {
                SettingsPicker("Root layout", selection: $defaultLayout, help: "Used for new workspaces. Selecting Dwindle also updates existing tiled workspaces.") {
                    Text("Dwindle").tag(Layout.dwindle)
                    Text("Tiles").tag(Layout.tiles)
                    Text("Tab group").tag(Layout.tabGroup)
                } onChange: { persistRootString("default-root-container-layout", defaultLayout.rawValue) }
                Text("Defaults apply to new workspaces. Selecting Dwindle also updates existing tiled workspaces.")
                    .font(.caption).foregroundStyle(.secondary)
                SettingsPicker("Root orientation", selection: $defaultOrientation, help: "Controls how new tiled containers split.") {
                    Text("Automatic").tag(DefaultContainerOrientation.auto)
                    Text("Horizontal").tag(DefaultContainerOrientation.horizontal)
                    Text("Vertical").tag(DefaultContainerOrientation.vertical)
                } onChange: { persistRootString("default-root-container-orientation", defaultOrientation.rawValue) }
                .pickerStyle(.segmented)

            }
        }
        .navigationTitle("Windows")
        .id(model.settingsRevision)
    }

    private func persistRootBool(_ key: String, _ value: Bool) {
        persistConfig(section: nil, key: key, value: value ? "true" : "false")
    }

    private func persistRootString(_ key: String, _ value: String) { persistConfig(section: nil, key: key, value: "'\(value)'") }
    private func persistRootInt(_ key: String, _ value: Int) { persistConfig(section: nil, key: key, value: "\(value)") }
    private func persistConfig(section: String?, key: String, value: String) {
        persistSettingsConfig(section: section, key: key, renderedValue: value, model: model)
    }
}

struct ShortcutAppearanceSettingsView: View {
    @ObservedObject var model: ShortcutSettingsModel
    @State private var sidebarEnabled = config.workspaceSidebar.enabled
    @State private var sidebarFocusEnabled = config.workspaceSidebar.enableFocus
    @State private var sidebarAutoHide = config.workspaceSidebar.autoHide
    @State private var sidebarAlwaysExpanded = config.workspaceSidebar.alwaysExpanded
    @State private var showStatusPills = config.workspaceSidebar.showStatusPills
    @State private var showClock = config.workspaceSidebar.showClock
    @State private var showSeconds = config.workspaceSidebar.showSeconds
    @State private var showDate = config.workspaceSidebar.showDate
    @State private var showWeekday = config.workspaceSidebar.showWeekday
    @State private var chromeStyle = config.workspaceSidebar.chromeStyle
    @State private var sidebarAppearance = config.workspaceSidebar.appearance
    @State private var sidebarBackground = config.workspaceSidebar.background
    @State private var sidebarFrostedTint = config.workspaceSidebar.frostedTint
    @State private var solidChromeColor = config.workspaceSidebar.solidChromeColor
    @State private var solidChromeCustomColor = config.workspaceSidebar.solidChromeCustomColor
    @State private var sidebarWidth = config.workspaceSidebar.width
    @State private var collapsedWidth = config.workspaceSidebar.collapsedWidth
    @State private var tabEnabled = config.windowTabs.enabled
    @State private var tabHeight = config.windowTabs.height
    @State private var tabPadding = config.tabGroupPadding
    @State private var menuBarReserveHeight = config.workspaceSidebar.menuBarReserveHeight
    @State private var innerHorizontalGap = settingsConstantValue(config.gaps.inner.horizontal)
    @State private var innerVerticalGap = settingsConstantValue(config.gaps.inner.vertical)
    @State private var outerLeftGap = settingsConstantValue(config.gaps.outer.left)
    @State private var outerRightGap = settingsConstantValue(config.gaps.outer.right)
    @State private var outerTopGap = settingsConstantValue(config.gaps.outer.top)
    @State private var outerBottomGap = settingsConstantValue(config.gaps.outer.bottom)
    @State private var bordersEnabled = config.windowBorders.enabled
    @State private var borderWidth = config.windowBorders.width
    @State private var activeBorderColor = config.windowBorders.activeColor
    @State private var inactiveBorderColor = config.windowBorders.inactiveColor
    @State private var borderOrder = config.windowBorders.order
    @State private var excludedBorderApps = config.windowBorders.excludeApps.joined(separator: ", ")

    var body: some View {
        SettingsScrollView {
            if let error = model.errorMessage {
                SettingsSection("Could not save setting") {
                    Text(error).foregroundStyle(.red).textSelection(.enabled)
                }
            }
            SettingsSection("Appearance") {
                Text("Style for tabs and the switcher. To use this style on the sidebar, select Custom below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SettingsPicker("Style", selection: $chromeStyle, help: "Style for tab groups, the switcher, and the sidebar when its appearance is Custom. Settings keep their own appearance.") {
                    Text("Liquid Glass").tag(ChromeStyle.liquidGlass)
                    Text("Solid color").tag(ChromeStyle.solid)
                } onChange: { persist("workspace-sidebar", "chrome-style", "'\(chromeStyle.rawValue)'") }
                SettingsSolidColorPalette(
                    selection: $solidChromeColor,
                    customColor: $solidChromeCustomColor,
                    isEnabled: chromeStyle == .solid,
                    onSelectionChange: { persist("workspace-sidebar", "solid-chrome-color", "'\(solidChromeColor.rawValue)'") },
                    onCustomColorChange: { persist("workspace-sidebar", "solid-chrome-custom-color", "'\(solidChromeCustomColor)'") },
                )
            }
            SettingsSection("Sidebar") {
                SettingsToggle("Show sidebar", isOn: $sidebarEnabled, help: "Show the workspace rail on configured displays.") { sidebarBool("enabled", sidebarEnabled) }
                Text("System follows macOS. Custom uses the appearance selected above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SettingsPicker("Sidebar appearance", selection: $sidebarAppearance, help: "System follows macOS with a native translucent surface. Custom keeps the configured Chrome style and dark controls.") {
                    Text("System").tag(WorkspaceSidebarAppearance.system)
                    Text("Custom").tag(WorkspaceSidebarAppearance.custom)
                } onChange: { persist("workspace-sidebar", "appearance", "'\(sidebarAppearance.rawValue)'") }
                .disabled(!sidebarEnabled)
                SettingsPicker("Sidebar background", selection: $sidebarBackground, help: "System appearance only. Transparent adapts the compact rail's contrast to the local wallpaper file and adds translucent frosted glass when expanded. Menu bar style uses a native translucent approximation. Reduce Transparency overrides both with an opaque background.") {
                    Text("Sidebar material").tag(WorkspaceSidebarBackground.sidebar)
                    Text("Menu bar style").tag(WorkspaceSidebarBackground.menuBar)
                    Text("Transparent").tag(WorkspaceSidebarBackground.transparent)
                } onChange: { persist("workspace-sidebar", "background", "'\(sidebarBackground.rawValue)'") }
                .disabled(!sidebarEnabled || sidebarAppearance != .system)
                SettingsSidebarFrostedPalette(selection: $sidebarFrostedTint,
                    isEnabled: sidebarEnabled && sidebarAppearance == .system && sidebarBackground == .transparent,
                    onSelectionChange: { persist("workspace-sidebar", "frosted-tint", "'\(sidebarFrostedTint.rawValue)'") })
                SettingsToggle("Focus sidebar monitor only", isOn: $sidebarFocusEnabled, help: "Show the sidebar only on the focused monitor when monitor scope allows it.") { sidebarBool("enable-focus", sidebarFocusEnabled) }
                .disabled(!sidebarEnabled)
                SettingsToggle("Reveal sidebar at the display edge", isOn: $sidebarAutoHide, help: "Hide the compact rail until the pointer reaches the left edge.") { sidebarBool("auto-hide", sidebarAutoHide) }
                .disabled(!sidebarEnabled)
                SettingsToggle("Keep sidebar expanded", isOn: $sidebarAlwaysExpanded, help: "Reserve the full sidebar width for tiled windows.") { sidebarBool("always-expanded", sidebarAlwaysExpanded) }
                .disabled(!sidebarEnabled)
                SettingsStepper("Expanded width", value: $sidebarWidth, range: 120...480, help: "Width of the fully expanded sidebar.") { sidebarInt("width", sidebarWidth) }
                .disabled(!sidebarEnabled)
                SettingsStepper("Collapsed width", value: $collapsedWidth, range: 28...120, help: "Width of the compact sidebar rail.") { sidebarInt("collapsed-width", collapsedWidth) }
                .disabled(!sidebarEnabled)
                SettingsStepper("Menu bar reserve", value: $menuBarReserveHeight, range: 0...72, help: "Use 0 px when the macOS menu bar auto-hides.") { sidebarInt("menu-bar-reserve-height", menuBarReserveHeight) }
                .disabled(!sidebarEnabled)

            }
            SettingsSection("Sidebar content") {
                if !showClock { Text("Enable Show clock to display seconds, date, and weekday.").font(.caption).foregroundStyle(.secondary) }
                if !sidebarEnabled { Text("Enable Show sidebar to change its content.").font(.caption).foregroundStyle(.secondary) }
                SettingsToggle("Show status pills", isOn: $showStatusPills) { sidebarBool("show-status-pills", showStatusPills) }
                .disabled(!sidebarEnabled)
                SettingsToggle("Show clock", isOn: $showClock) { sidebarBool("show-clock", showClock) }
                .disabled(!sidebarEnabled)
                SettingsToggle("Show seconds", isOn: $showSeconds) { sidebarBool("show-seconds", showSeconds) }
                .disabled(!sidebarEnabled || !showClock)
                SettingsToggle("Show date", isOn: $showDate) { sidebarBool("show-date", showDate) }
                .disabled(!sidebarEnabled || !showClock)
                SettingsToggle("Show weekday", isOn: $showWeekday) { sidebarBool("show-weekday", showWeekday) }
                .disabled(!sidebarEnabled || !showClock)
            }
            SettingsSection("Window tabs") {
                if !tabEnabled { Text("Enable Show tab strips to change their dimensions.").font(.caption).foregroundStyle(.secondary) }
                SettingsToggle("Show tab strips", isOn: $tabEnabled, help: "Display browser-like tabs for stacked windows.") { persist("window-tabs", "enabled", tabEnabled ? "true" : "false") }
                SettingsStepper("Tab strip height", value: $tabHeight, range: 21...80, help: "Height of the window tab strip.") { persist("window-tabs", "height", "\(tabHeight)") }
                .disabled(!tabEnabled)
                SettingsStepper("Tab group padding", value: $tabPadding, range: 0...80, help: "Space around tab groups.") { persist(nil, "tab-group-padding", "\(tabPadding)") }
                .disabled(!tabEnabled)
            }
            SettingsSection("Tiling gaps") {
                SettingsStepper("Inner horizontal", value: $innerHorizontalGap, range: 0...80, help: "Space between windows side by side.") { persist("gaps", "inner.horizontal", "\(innerHorizontalGap)") }
                SettingsStepper("Inner vertical", value: $innerVerticalGap, range: 0...80, help: "Space between vertically stacked windows.") { persist("gaps", "inner.vertical", "\(innerVerticalGap)") }
                SettingsStepper("Outer left", value: $outerLeftGap, range: 0...120, help: "Inset at the left display edge.") { persist("gaps", "outer.left", "\(outerLeftGap)") }
                SettingsStepper("Outer right", value: $outerRightGap, range: 0...120, help: "Inset at the right display edge.") { persist("gaps", "outer.right", "\(outerRightGap)") }
                SettingsStepper("Outer top", value: $outerTopGap, range: 0...120, help: "Inset at the top display edge.") { persist("gaps", "outer.top", "\(outerTopGap)") }
                SettingsStepper("Outer bottom", value: $outerBottomGap, range: 0...120, help: "Inset at the bottom display edge.") { persist("gaps", "outer.bottom", "\(outerBottomGap)") }
            }
            SettingsSection("Window borders") {
                SettingsToggle("Show window borders", isOn: $bordersEnabled, help: "Draw a border around each visible managed window.") {
                    persist("borders", "enabled", bordersEnabled ? "true" : "false")
                }
                SettingsDoubleStepper(title: "Border width", value: $borderWidth, range: 0...20, step: 0.5, help: "Width in points; zero hides the border.") {
                    persist("borders", "width", String(borderWidth))
                }
                .disabled(!bordersEnabled)
                SettingsBorderColor("Focused window color", text: $activeBorderColor) {
                    persist("borders", "active-color", "'\(activeBorderColor)'")
                }
                .disabled(!bordersEnabled)
                SettingsBorderColor("Other window color", text: $inactiveBorderColor) {
                    persist("borders", "inactive-color", "'\(inactiveBorderColor)'")
                }
                .disabled(!bordersEnabled)
                SettingsPicker("Border placement", selection: $borderOrder, help: "Draw the border behind or over the window.") {
                    Text("Behind window").tag(WindowBorderOrder.below)
                    Text("Over window").tag(WindowBorderOrder.above)
                } onChange: {
                    persist("borders", "order", "'\(borderOrder.rawValue)'")
                }
                .disabled(!bordersEnabled)
                SettingsTextField("Excluded app bundle IDs", text: $excludedBorderApps, help: "Comma-separated bundle IDs, for example com.apple.finder.") {
                    persist("borders", "exclude-apps", tomlCommaSeparatedStringArray(excludedBorderApps))
                }
            }
        }
        .navigationTitle("Sidebar & Appearance")
        .id(model.settingsRevision)
    }

    private func sidebarBool(_ key: String, _ value: Bool) { persist("workspace-sidebar", key, value ? "true" : "false") }
    private func sidebarInt(_ key: String, _ value: Int) { persist("workspace-sidebar", key, "\(value)") }
    private func persist(_ section: String?, _ key: String, _ value: String) { persistSettingsConfig(section: section, key: key, renderedValue: value, model: model) }
}

struct ShortcutAutomationSettingsView: View {
    @ObservedObject var model: ShortcutSettingsModel
    @State private var startupCommands = ""
    @State private var workspaceCommands = ""
    @State private var focusCommands = ""
    @State private var monitorCommands = ""
    @State private var modeCommands = ""

    var body: some View {
        SettingsScrollView {
            if let error = model.errorMessage {
                SettingsSection("Could not save setting") {
                    Text(error).foregroundStyle(.red).textSelection(.enabled)
                }
            }
            SettingsSection("Event actions") {
                SettingsMultilineField("On workspace change", text: $workspaceCommands, help: "One command per line. Commands run after changing workspaces.", savedValue: config.execOnWorkspaceChange.joined(separator: "\n")) { onSaved in saveCommands("exec-on-workspace-change", workspaceCommands, onSaved: onSaved) }
                SettingsMultilineField("On focus change", text: $focusCommands, help: "One command per line. Commands run after the focused window changes.", savedValue: config.onFocusChanged.map { $0.args.description }.joined(separator: "\n")) { onSaved in saveCommands("on-focus-changed", focusCommands, onSaved: onSaved) }
                SettingsMultilineField("On focused monitor change", text: $monitorCommands, help: "One command per line. Commands run after the active display changes.", savedValue: config.onFocusedMonitorChanged.map { $0.args.description }.joined(separator: "\n")) { onSaved in saveCommands("on-focused-monitor-changed", monitorCommands, onSaved: onSaved) }
                SettingsMultilineField("On mode change", text: $modeCommands, help: "One command per line. Commands run after a mode changes.", savedValue: config.onModeChanged.map { $0.args.description }.joined(separator: "\n")) { onSaved in saveCommands("on-mode-changed", modeCommands, onSaved: onSaved) }
            }
            SettingsSection("Startup") {
                SettingsMultilineField(
                    "After startup",
                    text: $startupCommands,
                    help: "One command per line. Commands run after WinMuxX finishes starting.",
                    savedValue: config.afterStartupCommand.map { $0.args.description }.joined(separator: "\n")
                ) { onSaved in
                    saveCommands("after-startup-command", startupCommands, onSaved: onSaved)
                }
            }
        }
        .navigationTitle("Automation")
        .task { loadCommands() }
        .onChange(of: modeCommands) { model.automationDrafts["on-mode-changed"] = $0 }
        .onChange(of: monitorCommands) { model.automationDrafts["on-focused-monitor-changed"] = $0 }
        .onChange(of: focusCommands) { model.automationDrafts["on-focus-changed"] = $0 }
        .onChange(of: workspaceCommands) { model.automationDrafts["exec-on-workspace-change"] = $0 }
        .onChange(of: startupCommands) { model.automationDrafts["after-startup-command"] = $0 }
        .id(model.settingsRevision)
    }

    private func loadCommands() {
        workspaceCommands = model.automationDrafts["exec-on-workspace-change"] ?? config.execOnWorkspaceChange.joined(separator: "\n")
        startupCommands = model.automationDrafts["after-startup-command"] ?? config.afterStartupCommand.map { $0.args.description }.joined(separator: "\n")
        focusCommands = model.automationDrafts["on-focus-changed"] ?? config.onFocusChanged.map { $0.args.description }.joined(separator: "\n")
        monitorCommands = model.automationDrafts["on-focused-monitor-changed"] ?? config.onFocusedMonitorChanged.map { $0.args.description }.joined(separator: "\n")
        modeCommands = model.automationDrafts["on-mode-changed"] ?? config.onModeChanged.map { $0.args.description }.joined(separator: "\n")
    }

    private func saveCommands(_ key: String, _ commands: String, onSaved: @escaping () -> Void) {
        persistSettingsConfig(section: nil, key: key, renderedValue: tomlStringArray(commands), model: model) {
            if model.automationDrafts[key] == commands { model.automationDrafts.removeValue(forKey: key) }
            onSaved()
        }
    }

}

private func settingsConstantValue(_ value: DynamicConfigValue<Int>) -> Int {
    switch value {
        case .constant(let value): value
        case .perMonitor(_, let `default`): `default`
    }
}
