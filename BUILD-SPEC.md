# Locus VPN Spoofer — Build Spec

Status: source package build in progress on Windows; final signed IPA requires macOS/Xcode.

## Objective

Build a sideloadable iOS app that combines:

1. Locus-style system location spoofing through Apple's developer location service.
2. An embedded Network Extension packet tunnel that replaces LocalDevVPN.
3. Normal VPN egress support using WireGuard/OpenVPN/IKEv2-style profiles.
4. One unified control panel.

## Why this design

iOS allows one active VPN slot. Stock Locus occupies that slot indirectly through LocalDevVPN. Nord/Express also need that slot. Therefore the custom app must own the slot and perform both roles:

- local route to the developer tunnel endpoint, default `10.7.0.1/32`
- default-route egress through a user-supplied VPN profile

## Source intelligence

Repo: `https://github.com/ChrisMack32/Locus`

Verified files:

- `README.md`
- `SETUP.md`
- `Locus/Engine/LocationEngine.swift`
- `Locus/Engine/DeviceTunnel.swift`
- `Locus/Engine/SpoofSession.swift`
- `Locus/Engine/PairingStore.swift`
- `Locus/Engine/PairOnDeviceService.swift`
- `Locus/Engine/PairableHostAdvertiser.swift`
- `Locus/Support/LocalDevVPN.swift`
- `Locus/Resources/Info.plist`
- `Locus/Resources/Locus.entitlements`
- `project.yml`
- latest release metadata v1.0.3

Key facts:

- Locus bundle ID: `com.chrismack.locus`
- iOS deployment target: `18.0`
- vendored `libidevice_ffi.a`
- tunnel endpoint default: `10.7.0.1:49152`
- pairing file: `rp_pairing_file.plist`
- iOS 27 on-device pairing via `_remotepairing-pairable-host._tcp`
- iOS 18–26 requires RPPairing import from `idevice_pair`
- DVT calls: `tunnel_create_rppairing`, `remote_server_connect_rsd`, `location_simulation_new`, `location_simulation_set`
- Locus re-sends location every 8 seconds and health-checks every 12 seconds

## Target app

Working name: `Locus VPN Spoofer`

Suggested bundle IDs:

- app: `com.skpr.locusvpnspoofer`
- tunnel extension: `com.skpr.locusvpnspoofer.tunnel`

## Components

### App

- SwiftUI control panel
- RPPairing import/paste/on-device pairing
- location engine bridge to `libidevice_ffi.a`
- VPN profile import and storage
- tunnel manager using NetworkExtension
- public IP and location verification

### Packet Tunnel Provider

- `NEPacketTunnelProvider`
- local route: `10.7.0.1/32`
- optional default route through VPN egress
- WireGuard adapter first
- OpenVPN/IKEv2 adapters later
- persistent tunnel status shared with app via UserDefaults suite or App Group

### Location Engine

Reuse Locus engine with minimal changes:

- keep DVT injection
- keep 8s resend
- keep 12s health check
- remove LocalDevVPN dependency
- read tunnel endpoint from shared config

### Pairing

Keep both Locus paths:

- iOS 27 on-device pairable-host
- iOS 18–26 RPPairing import/paste

## Build requirements

- macOS with Xcode 16+
- XcodeGen
- Apple Developer account, free account works for sideloading
- iOS 18+ device
- sideload tool: Feather / SideStore / AltStore / Sideloadly

## Entitlements

App:

- App Group
- Keychain Sharing
- network client/server
- file sharing
- document types for plist/gpx/conf

Tunnel extension:

- `com.apple.developer.networking.vpn.api = allow-vpn`
- App Group
- network client/server

## Build phases

1. Source package scaffold — this build.
2. macOS build script generates Xcode project and archive.
3. Export IPA with development signing.
4. Sideload and test pairing.
5. Test local tunnel route to `10.7.0.1:49152`.
6. Test location spoof in Apple Maps.
7. Add WireGuard egress profile import.
8. Test public IP change while spoofed location remains active.

## Honest limits

- Final IPA cannot be compiled on this Windows box.
- App Store distribution is not targeted; sideload only.
- Apps with anti-spoof checks may reject developer-simulated GPS.
- VPN provider support depends on available protocol configs/keys.
- Network Extension signing requires correct entitlements from Apple.
