<p align="left">
  <img src="resources/winmux-logo.svg" width="80" alt="WinMuXx logo">
</p>

# WinMuXx

WinMuXx is gfavaro's fork of [ZimengXiong/WinMux](https://github.com/ZimengXiong/WinMux).
The fork keeps the original project and adds the changes listed first below. Fork builds and
maintenance details are in [docs/FORK.md](docs/FORK.md).

## WinMuXx additions

The section below describes changes specific to this fork. The original WinMux README follows it
for reference. When the two sections describe different behavior, use the WinMuXx instructions.

### Layout and workspaces

Set `default-root-container-layout = 'dwindle'` to use recursive dwindle tiling automatically.
WinMuXx applies the setting to tiled windows already open at startup, including windows restored
from saved state, and to existing tiled roots after a config reload. Floating windows, tab groups and
manual layout choices are preserved during ordinary refreshes and unrelated config changes.

Workspace commands target the focused display unless `--monitor` names another one. For example:

```sh
winmuxx workspace 2 --monitor secondary
winmuxx workspace --name 9
```

Selecting a workspace that is already visible on another display exchanges the active workspaces
and focuses the destination display, subject to `workspace-to-monitor-force-assignment`.
`workspace next` and `workspace prev` skip workspaces shown on other displays. Back-and-forth
navigation keeps a separate history for each display, and sidebar clicks act on the display that
owns that sidebar.

### Menu, diagnostics and recovery

The menu-bar icon lists window, layout, workspace, project and monitor actions. It shows shortcuts
from the active mode's configuration and refreshes them whenever the menu opens. Actions without a
configured shortcut have no shortcut label. Other command chains, modifier taps and key sequences
appear under **Other Key Bindings** when they do not match a catalog action.

**Diagnostics…** reports the loaded config path, validation results, effective layout, permissions,
monitors, other window managers and per-app accessibility latency. Use **Refresh** or **Copy
Diagnostics** in the report window, or run `winmuxx doctor`. Checks do not change macOS preferences
or stop other apps. Review paths and app names before sharing a report.

After an interrupted session, the menu can offer **Recover N Windows from Previous Session…**.
Recovery pauses tiling and restores the positions and sizes recorded before WinMuXx moved the windows.
It checks each app's process and launch identity, skips disconnected displays and native fullscreen or
minimized windows, and keeps failed entries for another attempt. Choose **Enable** to resume tiling.
The recovery journal is separate from the saved managed layout.

### Window borders

WinMuXx draws click-through borders around visible managed windows, with a different color for the
focused window. Configure them in `winmux.toml`:

```toml
[borders]
    enabled = true
    width = 4
    active-color = '#e1e3e4'
    inactive-color = '#494d64'
    order = 'below'
    exclude-apps = []
```

Colors accept `#RRGGBB` or `#RRGGBBAA`; width is measured in points. Changes apply on config reload.
Borders hide with their windows and in fullscreen. If you started JankyBorders in
`after-startup-command`, remove that command and stop its `borders` process to avoid duplicates.

### App name, CLI and installation

The app is named `WinMuXx`; the standalone command-line executable is `winmuxx`. Download the
latest ZIP from [this fork's releases](https://github.com/gfavaro/WinMuXx/releases), or build it:

```sh
make check
make fork-build
open .release/WinMuXx.app
```

Fork builds are ad-hoc signed and not notarized. macOS may require you to right-click the app and
choose **Open** on first launch. Automatic updates are disabled. The app bundle includes the CLI as
`Contents/MacOS/winmuxx-cli`; the standalone SwiftPM product is `winmuxx`.

WinMuXx stores its config in `${XDG_CONFIG_HOME:-~/.config}/winmux-gf/winmux.toml`. On first launch,
it copies an existing `~/.config/winmux/winmux.toml` into the fork's config directory and leaves the
original file untouched. See [docs/FORK.md](docs/FORK.md) for the fork's repository workflow, builds
and releases.

### Experimental window-size observations

WinMuXx can record minimum-size observations for windows during a session. These observations are
experimental and do not currently constrain layout.

## Original WinMux README

The following sections preserve the original project's feature and usage documentation. The
installation and migration instructions here apply to WinMux, not to WinMuXx. For this fork, use the
WinMuXx installation and config instructions above.

## Highlights

### Projects
Projects are collection of workspaces. Think of it like a parent/child hiearchy, you can switch between projects. Each project has it's own set of workspaces.

### Sidebar
The sidebar is a more interactively-performant and useful alternative to [Sketchybar](https://github.com/felixkratz/sketchybar) and traditional workspace menu bar dropdowns for most everyday tasks. It provides better visibility into spaces and spatial awareness on the desktop.

You can drag windows in and out of the sidebar from and to the current workspace. You can rearrange windows across all spaces using the sidebar, including tab groups.

By default the sidebar rests as a compact rail and expands when hovered. To hide the rail
completely until the pointer reaches the left display edge, enable auto-hide. On macOS 26 and
newer, native Liquid Glass is enabled by default. Choose an opaque solid color for greater
contrast across the sidebar, tab groups, and switcher:

```toml
[workspace-sidebar]
    auto-hide = true
    chrome-style = 'solid'
    solid-chrome-color = 'lavender' # Choose any color shown in Appearance, including custom.
```

To keep the full sidebar visible, reserve its expanded width when laying out tiled windows:

```toml
[workspace-sidebar]
    always-expanded = true
    width = 240
```

`always-expanded` takes precedence over `auto-hide`. The configured `gaps.outer.left` remains
the spacing between the sticky sidebar and tiled windows, and monitor selection continues to
control which displays reserve sidebar space.

The sidebar clock can be configured independently:

```toml
[workspace-sidebar]
    show-clock = true
    show-seconds = true
    show-date = true
    show-weekday = true
```

`show-clock` hides the entire clock card. The other settings independently control seconds,
the month and day, and the weekday; for example, `show-date = false` with
`show-weekday = true` leaves a weekday-only calendar label in the expanded sidebar.

### Window and sidebar spacing

The `[gaps]` settings control the visible borders around tiled windows. `inner.horizontal`
and `inner.vertical` set the space between neighboring windows. The outer gaps set the space
at each display edge; when the sidebar is enabled, `outer.left` is the space between the
sidebar and the tiled windows. Any of these values can be reduced or set to zero independently.

For borderless tiling, including no border beside the sidebar:

```toml
[gaps]
    inner.horizontal = 0
    inner.vertical = 0
    outer.left = 0
    outer.bottom = 0
    outer.top = 0
    outer.right = 0
```

### Tab Groups
![](resources/screenshots/tab-groups.png)
Tab groups allow you to have many windows occupy the same footprint, similar to Yabai stacks but with browser-like tab behavior. This is useful when you want to have multiple pieces of reference information next to an editor, multiple tabs in different browser profiles, or, when you simply want multiple fullscreen views without the additional friction and overhead of creating a new workspace.

Unlike stack-only layouts, WinMux tab groups behave more intuitively like you would expect tabs to in browsers, and don't need a keyboard shortcut to activate. You can drag tabs from tab groups into another window's [intent zone](#managed-tiling-mode), or in between workspaces. You can also rearrange tab order within a tab group, and navigate through them with relative and absolute keybindings.

### Philosophy

#### Automatic tiling

WinMux tiles newly discovered windows by default. To keep their existing macOS size and position while still using WinMux's sidebar, workspaces, and manual layout commands, disable automatic tiling:

```toml
automatically-tile-new-windows = false
```

This applies to windows discovered when WinMux starts and windows opened later. You can still tile an individual floating window with `winmux layout tiling` or the configured `layout floating tiling` shortcut.

While dragging a window by its title bar, shake it horizontally to toggle between floating and tiling. The gesture requires several deliberate direction changes in quick succession, and does not activate during resize, sidebar, tab-strip, or tab-group drags. Disable it with:

```toml
enable-shake-to-toggle-tiling = false
```

#### Workspaces
You can NOT create workspaces that have no windows in them. Workspaces with no windows are automatically destroyed.

### Multi-Monitors
Monitors share the global project/workspace state. Each monitor can be treated as *independent* from each other. They each just use the sidebar to browse through projects and 'select' a workspace to view.

Monitors can not be attached to the same workspace at the same time. They can be on the same project at the same time.

#### App Launching
WinMux supports single-modifer keybindings (e.g. triggering an action on press of `⌘`)

I highly recommend that you configure the apps you use every day to be launch with Left/Right Option+Command, or similar shortcuts, otherwise it might be hard to launch common things into the current workspace (and instead, take you to the other workspace where the app is currently active). Here is some of the apps that I have keybinded:

```toml
[mode.main.binding-tap]
    left-alt = 'exec-and-forget /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --profile-directory="Default"'
    right-cmd = 'exec-and-forget /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --profile-directory="Profile 1"'

[mode.main.binding]
    # Disable the native "Hide App" shortcut.
    cmd-h = []

    cmd-d = 'exec-and-forget osascript ~/Documents/scripts/launchTerminalWindow.scpt'
    cmd-e = 'exec-and-forget osascript ~/Documents/scripts/launchFinderWindow.scpt'
```

```applescript
# ~/Documents/scripts/launchTerminalWindow.scpt
tell application "cmux"
    if it is running
        tell application "System Events" to tell process "cmux"
            click menu item "New Window" of menu "File" of menu bar 1
        end tell
    else
        activate
    end if
end tell

# ~/Documents/scripts/launchFinderWindow.scpt
tell application "Finder"
    if it is running
        tell application "System Events" to tell process "Finder"
            click menu item "New Finder Window" of menu "File" of menu bar 1
        end tell
    else
        activate
    end if
end tell
```

## Installation
Install WinMux with Homebrew:

```shell
brew tap ZimengXiong/homebrew https://github.com/ZimengXiong/homebrew
brew trust ZimengXiong/homebrew
brew install --cask winmux
xattr -cr /Applications/WinMux.app
```

Or download the latest binary from releases and launch.

Release builds are signed with the project's Apple Development certificate. They are not notarized, so macOS may require you to right-click the app and choose **Open** the first time you launch it.

WinMux checks GitHub Releases for signed updates automatically. You can also select **Check for Updates…** from the menu bar.

## Migrating
### From AeroSpace
If `~/.config/winmux/winmux.toml` already exists, WinMux uses it as-is.

If you have an AeroSpace config but no WinMux config yet, WinMux creates one for you on first launch. It copies over your AeroSpace shortcuts/key mapping and fills in the rest with WinMux defaults, including the sidebar and window tabs.

You do not need to edit anything to get started. After import, WinMux uses `~/.config/winmux/winmux.toml` and leaves your AeroSpace config alone.

If neither exists, WinMux creates a new WinMux config with the bundled defaults.

## Credits
[Aerospace](https://github.com/nikitabobko/AeroSpace)
