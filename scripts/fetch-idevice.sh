#!/usr/bin/env bash
set -euo pipefail

# Pull the upstream Locus source and copy the vendored idevice static library
# into this project. Run this on macOS before building.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/locus-upstream"

rm -rf "$TMP"
git clone --depth 1 https://github.com/ChrisMack32/Locus.git "$TMP"

mkdir -p "$ROOT/Vendor/idevice"
cp -R "$TMP/Vendor/idevice/." "$ROOT/Vendor/idevice/"

echo "[+] vendored idevice files:"
find "$ROOT/Vendor/idevice" -maxdepth 2 -type f -print
