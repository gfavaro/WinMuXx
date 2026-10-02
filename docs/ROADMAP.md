# WinMuXx roadmap

## Current delivery

- [x] Native menu-bar action catalog: categorized clickable commands, current-mode shortcuts, custom bindings, taps and sequences.
- [x] Shared CLI and GUI diagnostics: loaded config path, validation, permissions, displays, AX latency and potentially conflicting window managers; refresh/copy without changing system settings.

Verified with the full Swift test suite (607 tests), a Debug app build, and runtime checks of the native menu and the GUI/CLI diagnostics. Automated menu-action tests cover routing on two monitors. Future priorities below are intentionally not implemented in this delivery.

## Next priorities

Crash-recovery journal and manual menu action are implemented in source but await compilation, tests and runtime validation at the user's request. Original geometry is recorded atomically before frame changes; recovery pauses tiling, verifies app identity and readback, skips disconnected displays/native fullscreen/minimized windows, and retains failures. No native Space manipulation is included.

Learned minimum sizes now have an observation stage: per-window session-local evidence, two delayed readbacks, conservative rounding tolerance, cancellation on changed requests/closure/recovery, diagnostics and a manual reset. No layout constraints or persisted limits are applied yet. Next: distribute available space respecting these limits across tiles, dwindle and nested tab groups; report overflow without automatically regrouping windows. Persist only after a reliable window-type identity is available, never a blanket application-wide limit.

Validation update: all 626 Swift tests passed and the Xcode Debug app built successfully. Installed and launched the updated Debug app; live CLI diagnostics confirmed valid config, dwindle, two monitors, recovery journal availability and learned minimum observations. Manual recovery was deliberately not exercised against the user's live windows. Screen-capture permission is currently reported missing for this build and may require reauthorization.

1. **Crash recovery.** Complement layout persistence with a durable journal of original window frames. Offer explicit recovery; validate ownership and identity before touching a window, handle disconnected displays and partial failures. Never confuse restoring the managed layout with recovering original geometry. [Dinky reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/Recovery.swift).
2. **Learned minimum sizes.** Read back refused resize requests, confirm constraints, avoid repeated unsuccessful writes, persist useful limits and provide a reset action. Distinguish different window types in the same app instead of applying a single overly broad minimum. [Dinky reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/FrameApplier.swift).

## Ideas to revisit

- **Fixed workspace layouts:** reserve grid cells, preserve empty slots, define overflow expansion without rearranging existing placements. Acceptance: predictable terminal/editor/browser placement and reversible overflow. [Reference](https://github.com/mikker/Dinky/blob/main/docs/configuration.md#workspacenumber).
- **Optional short animations:** retarget in-flight transitions, respect Reduce Motion, settle correctly after display disconnect or stalled animation clocks. Prioritize reliability before visual effects. [Reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/Animator.swift).
- **Focus follows mouse:** off by default, configurable dwell, ignore dragging/menus and protect focus after app/workspace changes. Acceptance: a stationary pointer never undoes Cmd-Tab or a workspace switch. [Reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/FocusFollowsMouse.swift).
- **Mission Control / Exposé:** temporarily hide borders and suppress hover focus. Detect across supported macOS versions; do not copy Dinky's macOS-27-specific window heuristic blindly. [Reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/MissionControl.swift).

Future items need a detailed implementation plan and tests before execution. The current delivery does not change the TOML format, create additional global hotkeys, alter macOS preferences or stop other apps.
