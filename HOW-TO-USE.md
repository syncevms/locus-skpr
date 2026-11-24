# HOW TO USE

## What it does

This project builds one sideloaded iPhone app that spoofs system GPS and owns the iOS VPN slot, so a normal VPN egress profile can be used without LocalDevVPN.

## What you need

- GitHub account with Actions enabled, or a macOS/Xcode machine
- Apple Developer account, free account works for sideloading
- Signing certificate exported as `.p12`
- App provisioning profile for `com.skpr.locusvpnspoofer`
- Tunnel provisioning profile for `com.skpr.locusvpnspoofer.tunnel`
- iOS 18+ iPhone
- Sideload tool: Feather, SideStore, AltStore, or Sideloadly

## Build without macOS

1. Create a private GitHub repo.
2. Copy this whole `locus-vpn-spoofer` folder into it.
3. Add GitHub secrets:
   - `SIGNING_CERT_P12` = base64 of the `.p12`
   - `SIGNING_CERT_PASSWORD` = `.p12` password
   - `APP_PROFILE` = base64 of app `.mobileprovision`
   - `TUNNEL_PROFILE` = base64 of tunnel `.mobileprovision`
4. Open Actions → `build-locus-vpn-spoofer` → Run workflow.
5. Enter Apple Team ID.
6. Download the `LocusVPNSpoofer-IPA` artifact.
7. Unzip it and sideload the `.ipa`.

Base64 commands on macOS/Linux:

```bash
base64 -i cert.p12 | tr -d '\n'
base64 -i app.mobileprovision | tr -d '\n'
base64 -i tunnel.mobileprovision | tr -d '\n'
```

## Build on macOS

```bash
./scripts/fetch-idevice.sh
DEVELOPMENT_TEAM=XXXXXXXXXX ./scripts/build_ipa.sh
```

## First run on iPhone

1. Sideload the IPA.
2. Open the app.
3. Import or paste an RPPairing file.
4. Start the embedded tunnel.
5. Enter latitude/longitude.
6. Tap Teleport.
7. Open Apple Maps to verify.

## Pairing

- iOS 27: use on-device pairing through Developer Mode.
- iOS 18–26: generate RPPairing with `idevice_pair`, then import it.

## VPN egress

1. Paste a WireGuard config into the VPN Egress section.
2. Save profile.
3. Start embedded tunnel.
4. Check public IP in Safari.

## Common problems

- Build fails with signing error: check Team ID and provisioning profiles.
- Tunnel fails to start: check Network Extension entitlement and tunnel bundle ID.
- Location fails: pairing file is missing or invalid.
- App rejects spoofed GPS: target app has anti-spoof checks.

## Honest limits

- Final IPA requires macOS/Xcode or GitHub Actions.
- Sideloaded apps expire and need resigning depending on the signing method.
- Not all apps accept developer-simulated location.
- WireGuard egress is the first supported profile format in this scaffold.
