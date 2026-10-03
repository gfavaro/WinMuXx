# WinMux roadmap

## Current delivery

- [x] Native menu-bar action catalog: categorized clickable commands, current-mode shortcuts, custom bindings, taps and sequences.
- [x] Shared CLI and GUI diagnostics: loaded config path, validation, permissions, displays, AX latency and potentially conflicting window managers; refresh/copy without changing system settings.

Verified with the Swift test suite, a Debug app build, and runtime checks of the native menu and the GUI/CLI diagnostics. Automated menu-action tests cover routing on two monitors. Display topology handling and learned minimum-size persistence are now implemented and covered by targeted tests.

## Next priorities

Crash-recovery journal and manual menu action are implemented and covered by journal tests. Runtime validation with real windows remains pending. Original geometry is recorded atomically before frame changes; recovery pauses tiling, verifies app identity and readback, skips disconnected displays/native fullscreen/minimized windows, and retains failures. No native Space manipulation is included.

Learned minimum sizes now have per-window evidence, two delayed readbacks, conservative rounding tolerance, cancellation on changed requests/closure/recovery, diagnostics, manual reset, persistence through the frozen-world state, distribution in tile containers, guarded distribution in dwindle, and pure tests for proportional fitting and overflow. Remaining work is validation and refinement for nested containers and tab groups.

Validation update: the Debug build completed after rebuilding the stale SwiftPM cache, and the full Swift suite passes (677 tests). Targeted monitor navigation, recovery, dwindle, focus, movement, minimum redistribution and Mission Control suppression suites also pass. Live CLI diagnostics and recovery behavior remain separate from manual runtime validation. Screen-capture permission is currently reported missing for this build and may require reauthorization.

1. **Runtime validation.** Exercise crash recovery and display reconnection with real windows and dock/undock arrangements. [Recovery reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/Recovery.swift), [display reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/Display.swift).
2. **Learned minimum sizes.** Validate and refine dwindle, nested containers, tab groups and overflow behavior. [Dinky reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/FrameApplier.swift).

## Ideas to revisit

- [x] **Denser frost for the expanded sidebar:** the frosted effect now uses a more opaque AppKit surface and a stronger tint veil, retaining native blur, wallpaper-derived automatic tint, manual color choices, and the current compact rail. Reduce Transparency still overrides it with an opaque surface.
- **Fixed workspace layouts (deferred):** reserve grid cells, preserve empty slots, define overflow expansion without rearranging existing placements. This remains outside the current delivery scope. [Reference](https://github.com/mikker/Dinky/blob/main/docs/configuration.md#workspacenumber).
- [x] **Optional short animations:** sidebar and tab-strip state transitions now disable animation when Reduce Motion is enabled. State-driven SwiftUI transitions retarget to the latest value; monitor reflow remains responsible for settling geometry after display changes. Runtime interruption checks remain useful follow-up validation. [Reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/Animator.swift).
- [x] **Focus follows mouse:** off by default, configurable dwell, ignores dragging and button presses, and protects focus after pointer changes. Runtime validation remains pending. [Reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/FocusFollowsMouse.swift).
- [x] **Mission Control / Exposé:** border overlays are suppressed when macOS exposes the display-sized WindowManager layer, while workspace visibility and activation remain untouched. Runtime validation remains pending. [Reference](https://github.com/mikker/Dinky/blob/main/Sources/dinky/MissionControl.swift).
- [x] **Comparar o algoritmo dwindle:** revisão concluída. O Dinky mantém mínimos no modelo de layout, calcula `minimumExtent` recursivamente e usa `fit` para redistribuir espaço. Na movimentação, usa o layout virtual e relações de container; o WinMux usa geometria física e troca `moveNode` no dwindle. A criação de janelas divide a área focada pelo maior eixo em ambos, com regras adicionais do WinMux para tab groups e janelas não convencionais. [Dinky](https://github.com/mikker/Dinky).

Future items need a detailed implementation plan and tests before execution. The current delivery does not change the TOML format, create additional global hotkeys, alter macOS preferences or stop other apps.
