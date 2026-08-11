#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="OmniPulse"
BUNDLE_ID="com.tiburonns.OmniPulse"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${TMPDIR:-/tmp}/OmniPulse-macOS-${UID}"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/OmniPulse.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/OmniPulse"

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

xcodegen generate
xcodebuild \
  -project OmniPulse.xcodeproj \
  -scheme OmniPulseMac \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  build

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    echo "$APP_NAME se compiló y está ejecutándose."
    ;;
  *)
    echo "uso: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
