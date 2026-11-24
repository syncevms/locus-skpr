# PLAYBOOK

## P-LVS-01 — No macOS on Windows

Final IPA compilation requires Xcode. Use GitHub Actions `macos-15` runner or a rented macOS VM. Windows can only prepare source and docs.

## P-LVS-02 — One VPN slot

iOS allows one active VPN slot. The custom app must own that slot. Do not try to run LocalDevVPN and Nord/Express together.

## P-LVS-03 — Local route first

The embedded tunnel must always keep `10.7.0.1/32` reachable. If default egress is added, preserve the local developer route.

## P-LVS-04 — Pairing file type

Use RPPairing, not SideStore lockdown pairing. Wrong pairing file causes tunnel/simulation errors.

## P-LVS-05 — Vendored FFI

`libidevice_ffi.a` comes from upstream Locus. Pull it with `scripts/fetch-idevice.sh` before building.

## P-LVS-06 — Signing

App and tunnel extension need matching App Group and correct bundle IDs:

- `com.skpr.locusvpnspoofer`
- `com.skpr.locusvpnspoofer.tunnel`

## P-LVS-07 — Anti-spoof apps

Developer-simulated GPS is system-level but detectable. Apps with integrity checks may reject it.

## P-LVS-08 — WireGuard phase

The current adapter parses WireGuard config and adds default route/DNS. Full encrypted WireGuard packet transport requires integrating a WireGuard implementation or using a provider SDK in the tunnel extension.
