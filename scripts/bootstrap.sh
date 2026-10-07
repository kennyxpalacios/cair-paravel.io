#!/bin/sh
# Generates CairParavel.xcodeproj from project.yml and opens it in Xcode.
# Run it after every pull: ./scripts/bootstrap.sh
set -eu
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing XcodeGen with Homebrew..."
    brew install xcodegen
  else
    echo "XcodeGen is required. Install Homebrew from https://brew.sh, then run this script again." >&2
    exit 1
  fi
fi

if [ ! -f Config/Signing.local.xcconfig ]; then
  cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
  echo "Created Config/Signing.local.xcconfig. Add your Team ID there to run on a real device."
fi

xcodegen generate
open CairParavel.xcodeproj
