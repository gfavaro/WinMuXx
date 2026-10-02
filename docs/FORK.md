# Personal fork: WinMuXx

This fork integrates the six upstream contributions and retains personal defaults
(automatic dwindle and enabled built-in borders). Additional workspace persistence,
the roadmap, and experimental session-local minimum-size observations remain fork
changes. Minimum-size observations do not yet constrain the layout engine.

## Repository workflow

- `origin`: https://github.com/gfavaro/WinMuXx.git
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

Release app: `WinMuXx.app`, bundle ID `com.gfavaro.winmux`.
Debug app: `WinMuXx-Debug`, bundle ID `com.gfavaro.winmux.debug`.
The CLI packaged in the release is `Contents/MacOS/winmuxx-cli`; the standalone CLI product
is named `winmuxx` and is placed in the directory reported by
`swift build -c release --show-bin-path`. Both connect to the fork socket, not the original
app. Debug CLI builds connect to the debug fork.
Application Support, recovery journals, login registration, and diagnostics are
separate. No original launch agents are deleted.

The owned config is `${XDG_CONFIG_HOME:-~/.config}/winmux-gf/winmux.toml`.
On first launch, an existing original WinMux config is copied, not modified.
If none exists, the original AeroSpace import behavior is retained; otherwise a
starter config is generated. `--config-path` overrides this selection. Explicitly
sharing a config makes settings edits shared as well. Never run two window managers
at once: distinct bundle IDs do not prevent competing window manipulation.

## Local build and installation

Xcode and the toolchain in `.swift-version` are required; `make xcodeproj` installs
the pinned XcodeGen helper if absent. The build has no Apple team dependency:

```sh
make check
make fork-build BUILD_NUMBER=1
```

Outputs: `.release/WinMuXx.app` and `.release/WinMuXx-<version>-<build>.zip`. The build is ad hoc
signed, **not notarized**. New builds may require granting macOS permissions again.
Quit the original window manager, then copy the app to `/Applications/WinMuXx.app`
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
