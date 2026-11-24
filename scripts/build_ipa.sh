#!/usr/bin/env bash
set -euo pipefail

# Build on macOS with Xcode 16+.
# Required env:
#   DEVELOPMENT_TEAM=XXXXXXXXXX
# Optional env:
#   EXPORT_METHOD=development   # development|ad-hoc
#   PROVISIONING_PROFILE_SPECIFIER="Locus VPN Spoofer Development"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

: "${DEVELOPMENT_TEAM:?set DEVELOPMENT_TEAM to your Apple Team ID}"
EXPORT_METHOD="${EXPORT_METHOD:-development}"

echo "[+] generating Xcode project"
xcodegen generate --spec project.yml

echo "[+] selecting Xcode"
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

echo "[+] archive"
xcodebuild \
  -project LocusVPNSpoofer.xcodeproj \
  -scheme LocusVPNSpoofer \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath build/LocusVPNSpoofer.xcarchive \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Manual \
  clean archive

cat > build/export.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>$EXPORT_METHOD</string>
  <key>teamID</key>
  <string>$DEVELOPMENT_TEAM</string>
  <key>uploadSymbols</key>
  <false/>
  <key>compileBitcode</key>
  <false/>
  <key>signingStyle</key>
  <string>manual</string>
</dict>
</plist>
EOF

echo "[+] export IPA"
xcodebuild \
  -exportArchive \
  -archivePath build/LocusVPNSpoofer.xcarchive \
  -exportOptionsPlist build/export.plist \
  -exportPath build/ipa

echo "[+] IPA:"
ls -lh build/ipa/*.ipa
shasum -a 256 build/ipa/*.ipa
