#!/bin/bash
# Build a personal app without the upstream identity, update feed, or signing team.
set -euo pipefail
cd "$(dirname "$0")/.."
fork_version="${VERSION:-$(tr -d '[:space:]' < VERSION)}"
fork_build_number="${BUILD_NUMBER:-1}"
[[ "$fork_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'VERSION must be numeric major.minor.patch' >&2; exit 1; }
[[ "$fork_build_number" =~ ^[1-9][0-9]*$ ]] || { echo 'BUILD_NUMBER must be a positive integer' >&2; exit 1; }
make xcodeproj VERSION="$fork_version" BUILD_NUMBER="$fork_build_number" CODESIGN_IDENTITY=- DEVELOPMENT_TEAM=
mkdir -p .release
fork_stage="$(mktemp -d "$PWD/.release/fork-build.XXXXXX")"
trap 'echo "Build intermediates retained at: $fork_stage"' EXIT
xcodebuild -project WinMux.xcodeproj -scheme WinMux -configuration Release \
  -derivedDataPath "$PWD/.release/fork-derived" CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= build > "$fork_stage/xcodebuild.log" 2>&1 || {
    tail -80 "$fork_stage/xcodebuild.log" >&2; exit 1;
  }
fork_app="$PWD/.release/fork-derived/Build/Products/Release/WinMuXx.app"
test -d "$fork_app"
source ./script/setup.sh
swift build -c release --product winmuxx
fork_bin="$(swift build -c release --show-bin-path | tail -n 1)"
test -d "$fork_bin"
# Keep the CLI name distinct from the app executable on case-insensitive macOS volumes.
ditto "$fork_bin/winmuxx" "$fork_app/Contents/MacOS/winmuxx-cli"
codesign --force --deep --sign - "$fork_app"
codesign --verify --deep --strict "$fork_app"
"$fork_app/Contents/MacOS/WinMuXx" --help | grep -q -- '--config-path'
fork_plist="$fork_app/Contents/Info.plist"
test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$fork_plist")" = com.gfavaro.winmux
test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$fork_plist")" = "$fork_build_number"
test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$fork_plist")" = "$fork_version"
if /usr/libexec/PlistBuddy -c 'Print SUFeedURL' "$fork_plist" >/dev/null 2>&1; then
  echo 'Refusing to package an app with an update feed' >&2; exit 1
fi
ditto "$fork_app" .release/WinMuXx.app
ditto -c -k --sequesterRsrc --keepParent "$fork_app" ".release/WinMuXx-$fork_version-$fork_build_number.zip"
echo "Built .release/WinMuXx.app (ad hoc signed, not notarized)."
