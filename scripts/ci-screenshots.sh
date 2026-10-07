#!/bin/bash
# CI helper: installs a simulator build on an iPad and an iPhone simulator, launches it in
# each preview state, and saves screenshots.
# Usage: scripts/ci-screenshots.sh <path/to/CairParavel.app> <output-dir>
set -euo pipefail

APP="$1"
OUT="$2"
mkdir -p "$OUT"
BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist")

# Newest iOS runtime first; first device whose name matches the regex.
udid_for() {
  xcrun simctl list devices available -j | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
for runtime in sorted((k for k in devices if "iOS" in k), reverse=True):
    for device in devices[runtime]:
        if re.search(sys.argv[1], device["name"]):
            print(device["udid"])
            sys.exit(0)
sys.exit(1)
' "$1"
}

capture() {
  local udid=$1 label=$2 mood=$3 panel=$4
  xcrun simctl terminate "$udid" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl launch "$udid" "$BUNDLE" -CairPreviewMood "$mood" -CairPreviewPanel "$panel" >/dev/null
  sleep 7
  xcrun simctl io "$udid" screenshot "$OUT/$label.png" >/dev/null
  echo "captured $label"
}

IPAD=$(udid_for '^iPad Pro 13')
IPHONE=$(udid_for '^iPhone 1[6-9] Pro$' || udid_for '^iPhone')
echo "iPad: $IPAD  iPhone: $IPHONE"

for UDID in "$IPAD" "$IPHONE"; do
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true
  xcrun simctl install "$UDID" "$APP"
done

capture "$IPAD" ipad-1-lamplight lamplight none
capture "$IPAD" ipad-2-expedition-chronicles expedition chronicles
capture "$IPAD" ipad-3-teatime-mediahub teaTime mediaHub
capture "$IPHONE" iphone-1-lamplight lamplight none
capture "$IPHONE" iphone-2-expedition expedition none
capture "$IPHONE" iphone-3-chronicles-sheet expedition chronicles
