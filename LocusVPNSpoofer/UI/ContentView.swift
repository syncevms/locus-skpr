import SwiftUI
import UniformTypeIdentifiers
import NetworkExtension

struct ContentView: View {
    @StateObject private var tunnel = TunnelManager()
    @State private var latitude = "47.6062"
    @State private var longitude = "-122.3321"
    @State private var profileName = ""
    @State private var profileConfig = ""
    @State private var message = "Ready"

    private let engine = LocationEngine()

    var body: some View {
        NavigationStack {
            Form {
                Section("Tunnel") {
                    Text("Developer endpoint: \(AppConfig.developerTunnelIP):\(AppConfig.developerTunnelPort)")
                    Button("Start Embedded Tunnel") {
                        Task { await tunnel.start(profile: currentProfile()); message = "Tunnel started" }
                    }
                    Button("Stop Tunnel") {
                        Task { await tunnel.stop(); message = "Tunnel stopped" }
                    }
                    Text("Status: \(tunnel.status.label)")
                }

                Section("Pairing") {
                    Button("Import RPPairing File") { importPairingFile() }
                    Button("Paste RPPairing plist") { pastePairingFile() }
                    Text(pairingPath ?? "No pairing file")
                }

                Section("Location") {
                    TextField("Latitude", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitude)
                        .keyboardType(.decimalPad)
                    Button("Teleport") { teleport() }
                    Button("Clear") { try? engine.clearLocation() }
                }

                Section("VPN Egress") {
                    TextField("Profile name", text: $profileName)
                    TextEditor(text: $profileConfig)
                        .frame(height: 120)
                    Button("Save WireGuard Profile") { saveProfile() }
                }

                Section("Status") {
                    Text(message)
                        .font(.footnote)
                }
            }
            .navigationTitle("Locus VPN Spoofer")
            .task { await tunnel.load() }
        }
    }

    private var pairingPath: String? {
        let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Pairing/rp_pairing_file.plist").path
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    private func currentProfile() -> VPNProfile? {
        VPNProfile.load()
    }

    private func saveProfile() {
        let profile = VPNProfile(name: profileName, kind: .wireguard, config: profileConfig)
        profile.save()
        message = "Saved \(profile.name)"
    }

    private func teleport() {
        guard let path = pairingPath else {
            message = "Import pairing first"
            return
        }
        do {
            try engine.prepare(pairingPath: path,
                               tunnelIP: AppConfig.developerTunnelIP,
                               tunnelPort: AppConfig.developerTunnelPort)
            let target = SpoofTarget(latitude: Double(latitude) ?? 0,
                                     longitude: Double(longitude) ?? 0)
            try engine.setLocation(target)
            message = "Teleported"
        } catch {
            message = error.localizedDescription
        }
    }

    private func importPairingFile() {
        message = "Use the Share sheet or Files app to open a .plist into Locus VPN Spoofer."
    }

    private func pastePairingFile() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            message = "Clipboard is empty"
            return
        }
        do {
            let url = try pairingURL()
            try text.write(to: url, atomically: true, encoding: .utf8)
            message = "Pairing saved"
        } catch {
            message = error.localizedDescription
        }
    }

    private func pairingURL() throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Pairing", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("rp_pairing_file.plist")
    }
}

extension NEVPNStatus {
    var label: String {
        switch self {
        case .connected: return "connected"
        case .connecting: return "connecting"
        case .disconnected: return "disconnected"
        case .disconnecting: return "disconnecting"
        case .invalid: return "invalid"
        case .reasserting: return "reasserting"
        @unknown default: return "unknown"
        }
    }
}
