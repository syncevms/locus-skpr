import Foundation
import NetworkExtension

@MainActor
final class TunnelManager: ObservableObject {
    @Published var status: NEVPNStatus = .invalid
    @Published var lastError: String?

    private let manager = NETunnelProviderManager()

    func load() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            if let existing = managers.first(where: { $0.protocolConfiguration?.serverAddress == AppConfig.bundleID }) {
                status = existing.connection.status
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func installOrUpdate(profile: VPNProfile?) async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            let tunnel = managers.first(where: { $0.protocolConfiguration?.serverAddress == AppConfig.bundleID }) ?? NETunnelProviderManager()

            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = AppConfig.tunnelBundleID
            proto.serverAddress = AppConfig.bundleID
            proto.username = profile?.name ?? "Local Developer Tunnel"
            proto.providerConfiguration = [
                "developerTunnelIP": AppConfig.developerTunnelIP,
                "developerTunnelPort": Int(AppConfig.developerTunnelPort),
                "vpnKind": profile?.kind.rawValue ?? "none",
                "vpnConfig": profile?.config ?? ""
            ]

            tunnel.protocolConfiguration = proto
            tunnel.localizedDescription = "Locus VPN Spoofer Tunnel"
            tunnel.isEnabled = true
            try await tunnel.saveToPreferences()
            try await tunnel.loadFromPreferences()
            status = tunnel.connection.status
        } catch {
            lastError = error.localizedDescription
        }
    }

    func start(profile: VPNProfile?) async {
        await installOrUpdate(profile: profile)
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            guard let tunnel = managers.first(where: { $0.protocolConfiguration?.serverAddress == AppConfig.bundleID }) else {
                lastError = "Tunnel profile not found"
                return
            }
            try tunnel.connection.startVPNTunnel()
            status = tunnel.connection.status
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stop() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            for tunnel in managers where tunnel.protocolConfiguration?.serverAddress == AppConfig.bundleID {
                tunnel.connection.stopVPNTunnel()
            }
            status = .disconnected
        } catch {
            lastError = error.localizedDescription
        }
    }
}
