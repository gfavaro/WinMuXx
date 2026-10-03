# Dwindle comparison — 2026-10-03

Compared WinMuxX with Dinky commit
[`d488ce74`](https://github.com/mikker/Dinky/tree/d488ce74eb1ec4319409118f56caebd88844fac6).
Findings come from its implementation and layout tests, not interactive comparison.

## Delivered in this change

WinMuxX now stores a ratio for each implicit dwindle split, defaulting to 50/50.
`resize width`, `height`, `smart` and `smart-opposite` select the nearest relevant
split, including nested tiles. Mouse edge resizing updates those same ratios.
Live layout and resize previews share geometry. Ratios are constrained to 10–90%,
and feasible learned minimums reserve space for both sides. When minimums cannot
fit, the requested distribution remains the fallback.

`balance-sizes` resets dwindle ratios and recursively balances tiles without
changing order, focus or tab-group membership. It no longer writes tile weights
to dwindle children, which caused the reported crash. Ratios survive frozen-world
serialization/restoration; old snapshots default to 50/50.

Dinky stores normalized sibling ratios in an explicit container tree. WinMuxX
retains its existing implicit child-versus-remainder splits. Consequently, resetting
all splits to 50/50 does not mean every window has the same overall area.

## Implemented follow-ups

All eight dwindle follow-ups are implemented. WinMuxX keeps its implicit
child-versus-remainder tree; it does not copy Dinky's explicit sibling model.

| Area | WinMuxX behavior |
| --- | --- |
| Insertion | Uses the anchor's physical rectangle, falling back to virtual geometry before the first layout. A tiles parent with the same axis is reused; otherwise the anchor is wrapped. A tab group remains intact. Replacing a dwindle slot preserves its ratios. |
| Membership and ratios | Closing or moving a child out removes its share and normalizes the survivors proportionally, subject to the existing 10–90% split bounds. Inserting into an adjusted dwindle divides the preceding slot's share (the first slot for index zero). Fresh/reset containers retain the default 50/50 spiral. Swaps preserve both parents' slot ratios; normalization preserves a replaced slot. |
| Minimums | Aggregation receives the workspace's resolved gaps and allocated rectangle. Nested dwindle follows each resolved split axis rather than summing every remaining window. Tabs reserve their bar and shell. Tiles fit content minimums plus their gap share, avoiding double subtraction. Layout, mouse geometry and tile previews share frame calculation. Impossible minimums retain the existing requested-distribution fallback. |
| Movement | `move` reorders slots within the same parent. Across parents it enters a matching tiles parent or wraps the spatial target with the requested axis, allowing a node to enter/leave containers. Tab groups move as a unit. Existing explicit swap operations retain slot-swap behavior. |
| Selection | Directional focus uses virtual slots and requires positive overlap on the perpendicular axis. There is no diagonal fallback. A tab group exposes its active tab as one spatial target; `focus tab-index`, `tab-next`, `tab-prev` and DFS selection reach hidden tabs. Workspace wrap uses the geometric opposite edge. |
| Orientation | Dwindle is automatic unless an explicit axis is selected. `layout horizontal`/`vertical` fix its split axis; `layout auto` restores automatic resolution. Layout, resize and navigation use the same resolver. The mode survives snapshots; missing fields keep old snapshots automatic. The default orientation setting applies at creation and updates existing dwindle roots when that setting changes. Unrelated reloads preserve manual choices. |
| Corner resize | Processes horizontal then vertical changes against recomputed geometry. Mouse-down edges determine adjacency. If resizing changes an automatic split's axis, the other axis does not reuse its stale length or ratio. Transfers continue to affect the implicit remainder, not an invented adjacent-sibling model. |
| Flatten | Preserves DFS window order and the chosen root layout, removes empty wrappers, resets dwindle ratios and returns orientation to the configured default. It preserves logical focus/MRU and leaves floating windows in place. `balance-sizes` continues to preserve the tree. |

Accordion is excluded by product decision: WinMuxX keeps its tab interface.
Fixed workspace layouts remain deferred as requested. Manual Accessibility checks
with real minimum-constrained applications, nested tab groups, corner drags and
rotated/external displays remain part of runtime validation.

## Primary references

- [Insertion, orientation, focus and flatten](https://github.com/mikker/Dinky/blob/d488ce74eb1ec4319409118f56caebd88844fac6/Sources/DinkyLayout/Workspace.swift)
- [Tree mutation and ratio redistribution](https://github.com/mikker/Dinky/blob/d488ce74eb1ec4319409118f56caebd88844fac6/Sources/DinkyLayout/Tree.swift)
- [Directional movement, virtual focus and keyboard resize](https://github.com/mikker/Dinky/blob/d488ce74eb1ec4319409118f56caebd88844fac6/Sources/DinkyLayout/Commands.swift)
- [Edge and corner resizing](https://github.com/mikker/Dinky/blob/d488ce74eb1ec4319409118f56caebd88844fac6/Sources/DinkyLayout/ResizeTo.swift)
- [Minimum fitting](https://github.com/mikker/Dinky/blob/d488ce74eb1ec4319409118f56caebd88844fac6/Sources/DinkyLayout/Geometry.swift)

The original nine resize regressions remain, and 15 additional tests cover
membership redistribution, matching-axis insertion, slot replacement and
normalization, nested minimums, tab chrome, per-monitor gaps, explicit/automatic
orientation and reload, structural movement, sequential corners, hidden tabs,
slot-preserving swaps, flatten and geometric wrap. Existing focus and move tests
now assert the intentionally changed alignment and slot-preservation policies.
The complete Swift suite passes with 706 tests; the 11 release-script tests also
pass. Dependency resolution leaves `Package.resolved` unchanged. Interactive
Accessibility validation remains pending.
