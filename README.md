# Locus VPN Spoofer

Custom iOS location-spoofing app designed to replace stock Locus + LocalDevVPN with one sideloaded IPA that owns the iOS VPN slot.

## What this package is

A complete Xcode source scaffold for:

- Locus-style DVT location spoofing
- embedded Network Extension tunnel replacing LocalDevVPN
- WireGuard-style VPN egress profile import
- unified SwiftUI control panel
- GitHub Actions macOS build workflow

## Current status

- Windows box: source package complete.
- Final signed IPA: requires macOS/Xcode or GitHub Actions macOS runner.
- No compiled IPA exists yet on this machine.

## Build

Fastest path:

1. Push this folder to a private GitHub repo.
2. Add secrets:
   - `SIGNING_CERT_P12`
   - `SIGNING_CERT_PASSWORD`
   - `APP_PROFILE`
   - `TUNNEL_PROFILE`
3. Run workflow `build-locus-vpn-spoofer`.
4. Download `LocusVPNSpoofer-IPA`.

Local macOS path:

```bash
./scripts/fetch-idevice.sh
DEVELOPMENT_TEAM=XXXXXXXXXX ./scripts/build_ipa.sh
```

## Important

This is a source build package. It does not pretend to be a compiled IPA.

The vendored `libidevice_ffi.a` is copied from upstream Locus at build time by `scripts/fetch-idevice.sh`.

## Docs

- `BUILD-SPEC.md`
- `HOW-TO-USE.md`
- `PLAYBOOK.md`
- `SESSION-STATE.md`
- `MANIFEST.md5`
