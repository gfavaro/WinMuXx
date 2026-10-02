# Personal fork: WinMuxX

This fork integrates the six upstream contributions and retains personal defaults
(automatic dwindle and enabled built-in borders). Additional workspace persistence,
the roadmap, and experimental session-local minimum-size observations remain fork
changes. Minimum-size observations do not yet constrain the layout engine.

## Repository workflow

- `origin`: https://github.com/gfavaro/WinMux.git
- `upstream`: https://github.com/ZimengXiong/WinMux.git
- `main`: stable personal integration branch; never rebase or force-push it.
- `feat/*`: personal feature branches, based on `main`.
- `contrib/*`: clean upstream contributions, based on `upstream/main`.

The existing six PR branches are preserved. Do not rebase or delete them while
their PRs are open. Weekly synchronization opens a PR, never auto-merges. A merge
conflict stops synchronization for manual resolution. If upstream squash-merges
a contribution, check for duplicate or altered implementations during integration.

```sh
git fetch upstream
git switch -c feat/my-change main
# For a contribution instead:
git switch -c contrib/my-fix upstream/main
```

## App isolation

Release app: `WinMuxX.app`, bundle ID `com.gfavaro.winmuxx`.
Debug app: `WinMuxX-Debug`, bundle ID `com.gfavaro.winmuxx.debug`.
The CLI packaged in the release is `Contents/MacOS/winmuxx-cli`; it connects to the
fork socket, not the original app. Debug CLI builds connect to the debug fork.
The app's displayed name and bundle identity are WinMuxX. Existing owned configuration
and Application Support directories retain their historical `winmux-gf`/`WinMux-GF`
names so the rename preserves user settings and recovery state. Login registration,
diagnostics, and sockets remain separate. No original launch agents are deleted.

The owned config is `${XDG_CONFIG_HOME:-~/.config}/winmux-gf/winmux.toml`.
On first launch, an existing original WinMux config is copied, not modified.
If none exists, the original AeroSpace import behavior is retained; otherwise a
starter config is generated. `--config-path` overrides this selection. Explicitly
sharing a config makes settings edits shared as well. Never run two window managers
at once: distinct bundle IDs do not prevent competing window manipulation.

## Local build and installation

### Workspace selection across monitors

Selecting a workspace already visible on another monitor now focuses it there,
without exchanging workspaces or changing either monitor's history. This applies
to shortcuts, explicit `workspace --monitor`, back-and-forth, and sidebar clicks.
Hidden workspaces still activate on the requested/focused monitor, respecting
forced assignments. Explicit move/summon commands retain their own behavior.

### Sidebar appearance

`[workspace-sidebar] appearance = 'system'` is the fork default, including when
omitted in an existing config. It uses a native AppKit sidebar material with
behind-window translucency, follows the system light/dark appearance, and uses
an opaque system background when Reduce Transparency is enabled. It does not
capture the wallpaper or reproduce the system menu bar pixel-for-pixel.

The Sidebar background picker controls `[workspace-sidebar] background` in system
appearance: `sidebar` (default, existing material), `menu-bar` (native AppKit header
material, an approximation of the menu bar), or `transparent` (compact rail without
panel fill or blur). The compact rail samples the left strip of each monitor's local
wallpaper file off the UI thread, with cached thumbnails and 15-second checks. It
chooses black/white text, strengthens secondary labels, and adds an opposite-color
halo. Expanded mode fades in translucent native HUD material (86% opacity) with a
light 8% tint, retaining behind-window blur and using system theme colors
so windows behind it do not compete with the content. No screen capture, copied
wallpaper, or network access is used. Unreadable/dynamic wallpapers fall back to
the system theme; the file may not match a live video or dynamic wallpaper frame.
Controls and selection highlights remain visible. Reduce Transparency takes
priority over every background option. Custom appearance ignores this setting.

`frosted-tint` affects only the expanded transparent sidebar. `automatic` retains
the wallpaper's average color behind each monitor's expanded sidebar as a 28% veil,
with a neutral 8% fallback if the local image cannot be read. Brightness of that
expanded strip chooses the automatic text theme independently of the compact rail.
`white`, `black`, `cyan`, `pink`, `indigo`, `purple`,
`ice` (white/cyan/pink gradient), and `aurora` (black/indigo/purple gradient) use a
28% colored veil over the native frost. Explicit colors choose a matching text
theme; collapsed mode retains wallpaper-adaptive contrast. Other backgrounds,
custom appearance, and Reduce Transparency ignore this preference. The visual
palette in Appearance settings persists the same config key via reload.

Choose `appearance = 'custom'` to retain the previous dark sidebar with the
configured `chrome-style` and solid colors. Tabs and the switcher always continue
to use those Chrome settings independently. The Sidebar appearance picker applies
changes through configuration reload; no automatic config migration is performed.

Developer visual checks use synthetic fixtures and a code-defined backdrop only:

```sh
swift run winmux-marketing-renderer --sidebar-appearance-proof .release/sidebar-appearance-previews
```

The output includes expanded/collapsed light and dark themes, reduced transparency,
increased contrast, and both legacy custom styles. Only the renderer's own windows
are captured; the running window manager and the user's wallpaper are not captured.

### Building

Xcode and the toolchain in `.swift-version` are required; `make xcodeproj` installs
the pinned XcodeGen helper if absent. The build has no Apple team dependency:

```sh
make check
make fork-build BUILD_NUMBER=1
```

Outputs: `.release/WinMuxX.app` and a version/build-number ZIP. The build is not
notarized. By default it uses an ad hoc signature. To keep macOS privacy permissions
across local builds, the script reads a signing identity name from
`${XDG_CONFIG_HOME:-~/.config}/winmux-gf/signing-identity` (or `CODESIGN_IDENTITY`);
the same certificate and bundle ID must be retained. CI without that local identity
continues to use ad hoc signing.
Quit the original window manager, then copy the app to `/Applications/WinMuxX.app`
and open it. The build command does not install, launch, or replace any app.
The old upstream `make install` target is intentionally disabled.

## CI and releases

CI tests PRs and `main`; trusted `main` builds also upload the app ZIP as an artifact.
Bot-created synchronization PRs do not rely on the normal PR event: synchronization
explicitly dispatches CI on its branch. Check that run in Actions before merging.
If dispatch fails, run CI manually on that branch. GitHub Actions must be allowed
to create pull requests in the fork's Actions settings.
Enable GitHub Actions for this fork if disabled. Releases run only on `gf-v*` tags,
test the code again, and require the tagged commit to be part of `main`.
The tag suffix must match `VERSION`. Build numbers use the GitHub run number.
Increment `VERSION` before a new release, then:

```sh
git tag gf-v0.5.7 main  # example; must match VERSION
git push origin gf-v0.5.7
```

Automatic updates are disabled in code and the app plist: no upstream feed or
Sparkle public key is bundled. To enable them later, create fork-owned Ed25519
keys, store the private key as an Actions secret, publish a fork appcast, and
configure the fork public key and feed. Keep the private key out of Git.
Apple certificate-based signing/notarization is a separate future setup.

## Bootstrap verification

Local tests/build results should be recorded separately from hosted CI. Publishing
the branch does not prove the hosted pinned-toolchain build passed. Existing
upstream PRs retain their independent defaults and do not receive fork branding.

Bootstrap local verification: 631 Swift tests and 9 Python tests passed. The
release app and its release CLI were built with local Apple Swift 6.4 / Xcode 27,
not the pinned CI Swift toolchain. Ad hoc signatures and bundled fork metadata
were verified. No app was installed or launched as part of bootstrap verification.
