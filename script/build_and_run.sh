#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
APP_NAME="Countdown"
BUNDLE_ID="local.countdown.app"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
case "$MODE" in
  run|--debug|--logs|--telemetry|--verify|--build-only) ;;
  *) echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--build-only]" >&2; exit 2 ;;
esac
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
swift build
BUILD_DIR="$(swift build --show-bin-path)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_BINARY="$APP_CONTENTS/MacOS/$APP_NAME"
mkdir -p "$APP_CONTENTS/MacOS" "$APP_CONTENTS/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BINARY"
for resources in "$BUILD_DIR"/*.bundle; do
  [ -d "$resources" ] || continue
  /usr/bin/ditto "$resources" "$APP_CONTENTS/Resources/$(basename "$resources")"
done
cat > "$APP_CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
/usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
case "$MODE" in
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
  --build-only) echo "$APP_BUNDLE" ;;
  --debug) lldb -- "$APP_BINARY" ;;
  --logs) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "Countdown"' ;;
  --telemetry) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'subsystem == "local.countdown.app"' ;;
  --verify) /usr/bin/open -n "$APP_BUNDLE"; sleep 2; pgrep -x "$APP_NAME" >/dev/null; echo "Countdown is running" ;;
esac
