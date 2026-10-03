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
                SettingsStepper("Hover delay", value: $focusFollowsMouseDwell, range: 0...2000, help: "Time the pointer must remain still before focusing the window.") {
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

private struct SettingsScrollView<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        Form { content }
            .formStyle(.grouped)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        Section { content } header: { Text(title) }
    }
}

private struct SettingsToggle: View {
    let title: String; @Binding var isOn: Bool; var help: String? = nil; let save: () -> Void
    init(_ title: String, isOn: Binding<Bool>, help: String? = nil, save: @escaping () -> Void) { self.title = title; _isOn = isOn; self.help = help; self.save = save }
    var body: some View {
        Toggle(title, isOn: $isOn)
        .help(help ?? title)
        .modifier(SettingsFieldFeedback(title: title))
        .onChange(of: isOn) { _ in
            ShortcutSettingsModel.shared.activeSettingTitle = title
            save()
        }
    }
}

private struct SettingsStepper: View {
    let title: String; @Binding var value: Int; let range: ClosedRange<Int>; let help: String; let save: () -> Void
    init(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, help: String, save: @escaping () -> Void) {
        self.title = title
        _value = value
        self.range = range
        self.help = help
        self.save = save
    }
    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(title)
                Spacer()
                TextField(title, value: $value, format: .number)
                    .labelsHidden().multilineTextAlignment(.trailing).frame(width: 70)
                Text("pt").foregroundStyle(.secondary)
            }
        }
        .help(help)
        .modifier(SettingsFieldFeedback(title: title))
        .onChange(of: value) { newValue in
            let clamped = min(max(newValue, range.lowerBound), range.upperBound)
            if clamped != newValue { value = clamped } else {
                ShortcutSettingsModel.shared.activeSettingTitle = title
                save()
            }
        }
    }
}

private struct SettingsDoubleStepper: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let help: String
    let save: () -> Void

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                TextField(title, value: $value, format: .number)
                    .labelsHidden().multilineTextAlignment(.trailing).frame(width: 70)
                Text("pt").foregroundStyle(.secondary)
            }
        }
        .help(help)
        .modifier(SettingsFieldFeedback(title: title))
        .onChange(of: value) { newValue in
            let clamped = min(max(newValue, range.lowerBound), range.upperBound)
            if clamped != newValue { value = clamped } else {
                ShortcutSettingsModel.shared.activeSettingTitle = title
                save()
            }
        }
    }
}

private struct SettingsBorderColor: View {
    let title: String
    @Binding var text: String
    let save: () -> Void

    init(_ title: String, text: Binding<String>, save: @escaping () -> Void) {
        self.title = title
        _text = text
        self.save = save
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ColorPicker(title, selection: Binding(
                get: {
                    let normalized = normalizedWindowBorderColor(text) ?? "#000000"
                    let value = UInt32(normalized.dropFirst(), radix: 16) ?? 0
                    let hasAlpha = normalized.count == 9
                    let rgb = hasAlpha ? value >> 8 : value
                    return Color(red: Double((rgb >> 16) & 255) / 255,
                                 green: Double((rgb >> 8) & 255) / 255,
                                 blue: Double(rgb & 255) / 255,
                                 opacity: hasAlpha ? Double(value & 255) / 255 : 1)
                },
                set: { color in
                    let components = NSColor(color).usingColorSpace(.sRGB) ?? .black
                    text = String(format: "#%02X%02X%02X%02X",
                                  Int((components.redComponent * 255).rounded()),
                                  Int((components.greenComponent * 255).rounded()),
                                  Int((components.blueComponent * 255).rounded()),
                                  Int((components.alphaComponent * 255).rounded()))
                    ShortcutSettingsModel.shared.activeSettingTitle = title
                    save()
                }
            ), supportsOpacity: true)
            SettingsTextField("Hex value", text: $text,
                              help: "Use #RRGGBB or #RRGGBBAA, including optional opacity.",
                              validate: settingsHexColorError, save: save)
        }
    }
}

struct SettingsTextField: View {
    @FocusState private var isFocused: Bool
    @State private var committedText: String?
    let title: String
    @Binding var text: String
    let help: String
    let validate: (String) -> String?
    let save: () -> Void

    init(_ title: String, text: Binding<String>, help: String,
         validate: @escaping (String) -> String? = { _ in nil }, save: @escaping () -> Void) {
        self.title = title
        _text = text
        self.help = help
        self.validate = validate
        self.save = save
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .focused($isFocused)
                .onAppear { committedText = text }
                .onSubmit(commit)
                .onChange(of: isFocused) { focused in if !focused { commit() } }
                .onDisappear { commit() }
                .help(help)
            if let error = validate(text) {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .modifier(SettingsFieldFeedback(title: title))
    }

    private func commit() {
        guard let committedText, committedText != text, validate(text) == nil else { return }
        self.committedText = text
        ShortcutSettingsModel.shared.activeSettingTitle = title
        save()
    }
}

func settingsHexColorError(_ text: String) -> String? {
    guard normalizedWindowBorderColor(text) != nil else {
        return "Use # followed by six or eight hexadecimal digits, for example #E1E3E4."
    }
    return nil
}

private struct SettingsMultilineField: View {
    @State private var savedText: String?
    @State private var isSaving = false
    let title: String
    @Binding var text: String
    let help: String
    let savedValue: String
    let save: (@escaping () -> Void) -> Void

    init(_ title: String, text: Binding<String>, help: String, savedValue: String, save: @escaping (@escaping () -> Void) -> Void) {
        self.title = title
        _text = text
        self.help = help
        self.save = save
        self.savedValue = savedValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
            Text(help).font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.system(size: 12, design: .monospaced))
                .frame(minHeight: 50)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(nsColor: .separatorColor)))
            Button(isSaving ? "Saving…" : "Save and apply") {
                let submittedText = text
                isSaving = true
                ShortcutSettingsModel.shared.activeSettingTitle = title
                save {
                    savedText = submittedText
                    isSaving = false
                }
            }
            .controlSize(.small)
            .disabled(isSaving || savedText == text)
            if savedText != text {
                Text("Unsaved changes").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .modifier(SettingsFieldFeedback(title: title))
        .onAppear { savedText = savedValue }
    }
}

private struct SettingsPicker<Selection: Hashable, Content: View>: View {
    let title: String; @Binding var selection: Selection; let help: String; @ViewBuilder let content: Content; let onChange: () -> Void
    init(_ title: String, selection: Binding<Selection>, help: String, @ViewBuilder content: () -> Content, onChange: @escaping () -> Void) { self.title = title; _selection = selection; self.help = help; self.content = content(); self.onChange = onChange }
    var body: some View {
        Picker(title, selection: $selection, content: { content })
            .help(help)
            .modifier(SettingsFieldFeedback(title: title))
            .onChange(of: selection) { _ in
                ShortcutSettingsModel.shared.activeSettingTitle = title
                onChange()
            }
    }
}

private struct SettingsSidebarFrostedPalette: View {
    @Binding var selection: WorkspaceSidebarFrostedTint
    let isEnabled: Bool
    let onSelectionChange: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Expanded frosted tint")
            Text("Automatic samples the wallpaper behind this monitor's sidebar. Other colors override the expanded glass tint. The compact rail keeps wallpaper-adaptive contrast.")
                .font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(WorkspaceSidebarFrostedTint.allCases) { tint in
                    Button { selection = tint } label: {
                        VStack(spacing: 4) {
                            LinearGradient(colors: tint.colors(colorScheme: colorScheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8).strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                                    if selection == tint {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, .black.opacity(0.75))
                                    }
                                }
                            Text(tint.title).font(.caption).foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tint.title)
                    .accessibilityAddTraits(selection == tint ? .isSelected : [])
                }
            }
        }
        .padding(14)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .onChange(of: selection) { _ in onSelectionChange() }
    }
}

private struct SettingsSolidColorPalette: View {
    @Binding var selection: ChromeSolidColor
    @Binding var customColor: String
    let isEnabled: Bool
    let onSelectionChange: () -> Void
    let onCustomColorChange: () -> Void
    private let columns = Array(repeating: GridItem(.flexible(minimum: 40), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Solid color")
            Text("Choose an opaque chrome color.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(ChromeSolidColor.allCases) { color in
                    Button {
                        selection = color
                    } label: {
                        GlassSurface(
                            shape: RoundedRectangle(cornerRadius: 8, style: .continuous),
                            hasBorder: false,
                            style: .solid,
                            solidColor: color == .custom ? Color(chromeHex: customColor) : color.color,
                        )
                            .frame(height: 42)
                            .overlay {
                                if selection == color {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.4), radius: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .help(color.title)
                    .accessibilityLabel(color.title)
                    .accessibilityAddTraits(selection == color ? .isSelected : [])
                }
            }
            if selection == .custom {
                ColorPicker("Custom color", selection: Binding(
                    get: { Color(chromeHex: customColor) },
                    set: { customColor = $0.chromeHex },
                ), supportsOpacity: false)
            }
        }
        .padding(14)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 14)
        }
        .onChange(of: selection) { _ in onSelectionChange() }
        .onChange(of: customColor) { _ in
            guard selection == .custom else { return }
            onCustomColorChange()
        }
    }
}

@MainActor
func persistSettingsConfig(section: String?, key: String, renderedValue: String, model: ShortcutSettingsModel, onSaved: (() -> Void)? = nil) {
    let settingTitle = model.activeSettingTitle
    model.activeSettingTitle = nil
    let previousSave = model.pendingSettingsSave
    model.pendingSettingsSave = Task { @MainActor in
        await previousSave?.value
        model.errorMessage = nil
        model.failedSettingTitle = nil
        do {
            let url = preferredEditableConfigUrl()
            let current = (try? String(contentsOf: url, encoding: .utf8)) ?? starterConfigText()
            let updated = updateSettingsScalarConfig(in: current, section: section, key: key, renderedValue: renderedValue)
            let parsed = parseConfig(updated)
            guard parsed.errors.isEmpty else {
                throw NSError(domain: "WinMux", code: 1, userInfo: [NSLocalizedDescriptionKey: parsed.errors.map(\.description).joined(separator: "\n")])
            }
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try updated.write(to: url, atomically: true, encoding: .utf8)
            guard try await reloadConfig(forceConfigUrl: url) else { throw NSError(domain: "WinMux", code: 1, userInfo: [NSLocalizedDescriptionKey: "Saved the setting, but could not reload the config."]) }
            model.reload()
            onSaved?()
        } catch {
            model.errorMessage = error.localizedDescription
            model.failedSettingTitle = settingTitle
            model.failedSaveRevision += 1
        }
    }
}

func updateSettingsScalarConfig(in text: String, section: String?, key: String, renderedValue: String) -> String {
    let header = section.map { "[\($0)]" }
    var lines = text.components(separatedBy: "\n")
    let start: Int
    let end: Int
    if let header, let index = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == header }) {
        start = index + 1
        end = lines[start...].firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("[") }) ?? lines.endIndex
    } else if let header {
        if !lines.last.map({ $0.isEmpty })! { lines.append("") }
        lines.append(header)
        lines.append("    \(key) = \(renderedValue)")
        return lines.joined(separator: "\n")
    } else {
        start = 0
        end = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("[") }) ?? lines.endIndex
    }
    for index in start..<end where settingsKey(in: lines[index]) == key {
        let indent = String(lines[index].prefix(while: { $0.isWhitespace }))
        lines[index] = "\(indent)\(key) = \(renderedValue)"
        return lines.joined(separator: "\n")
    }
    lines.insert("\(section == nil ? "" : "    ")\(key) = \(renderedValue)", at: start)
    return lines.joined(separator: "\n")
}

private func settingsKey(in line: String) -> String? {
    let line = line.trimmingCharacters(in: .whitespaces)
    guard !line.hasPrefix("#"), let equal = line.firstIndex(of: "=") else { return nil }
    return String(line[..<equal]).trimmingCharacters(in: .whitespaces)
}

func tomlStringArray(_ text: String) -> String {
    let values = text.split(whereSeparator: \ .isNewline).map { value in
        "\"\(value.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }
    return "[\(values.joined(separator: ", "))]"
}

private func settingsConstantValue(_ value: DynamicConfigValue<Int>) -> Int {
    switch value {
        case .constant(let value): value
        case .perMonitor(_, let `default`): `default`
    }
}

@MainActor
private func currentSettingsConfigText() -> String {
    let url = preferredEditableConfigUrl()
    return (try? String(contentsOf: url, encoding: .utf8)) ?? starterConfigText()
}

func tomlCommaSeparatedStringArray(_ text: String) -> String {
    tomlStringArray(text.split(whereSeparator: { $0 == "," || $0.isNewline })
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }.joined(separator: "\n"))
}

private struct SettingsFieldFeedback: ViewModifier {
    let title: String
    @ObservedObject private var model = ShortcutSettingsModel.shared

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
            if model.failedSettingTitle == title, let error = model.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled)
            }
        }
    }
}
