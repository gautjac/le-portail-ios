#!/usr/bin/env bash
# Boot a sim, install the Debug build, and capture demo screenshots.
set -euo pipefail
cd "$(dirname "$0")/.."

DD="/tmp/le-portail-ios-dd"
APP="$DD/Build/Products/Debug-iphonesimulator/LePortail.app"
BUNDLE="app.atelier.portail.ios"
OUT="screenshots"
mkdir -p "$OUT"

# Resolve a single iPhone 17 Pro UDID deterministically.
UDID="$(xcrun simctl list devices available | awk '/iPhone 17 Pro \(/{gsub(/[()]/,"",$4); print $4; exit}')"
[ -n "$UDID" ] || { echo "No iPhone 17 Pro sim found"; exit 1; }
echo "Sim: $UDID"

xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true

shot() { # <name> <arg...>
  local name="$1"; shift
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl install "$UDID" "$APP" >/dev/null
  xcrun simctl launch "$UDID" "$BUNDLE" "$@" >/dev/null
  sleep 3.2
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null
  echo "  → $name.png"
}

shot 01-home-fr            --demo-lang fr
shot 02-grid-fr            --demo-lang fr --demo-screen grid
shot 03-home-en            --demo-lang en
shot 04-search-fr          --demo-lang fr --demo-query accordeur
shot 05-filter-web-fr      --demo-lang fr --demo-platform web
shot 06-filter-ios-fr      --demo-lang fr --demo-platform iOS
shot 07-open-web-safari    --demo-lang fr --demo-open le-vertige --demo-safari
shot 08-detail-mac-en      --demo-lang en --demo-open darwin
shot 09-detail-ios-fr      --demo-lang fr --demo-open topo

echo "Done. Screenshots in $OUT/"
