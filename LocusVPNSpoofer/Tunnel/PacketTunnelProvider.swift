import Foundation
import Network
import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private var monitor: NWPathMonitor?

    override func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        let providerConfig = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration ?? [:]
        let devIP = providerConfig["developerTunnelIP"] as? String ?? AppConfig.defaultDeveloperTunnelIP
        let devPort = providerConfig["developerTunnelPort"] as? Int ?? Int(AppConfig.defaultDeveloperTunnelPort)
        let vpnKind = providerConfig["vpnKind"] as? String ?? "none"
        let vpnConfig = providerConfig["vpnConfig"] as? String ?? ""

        AppConfig.defaults.set(devIP, forKey: AppConfig.Key.developerTunnelIP)
        AppConfig.defaults.set(devPort, forKey: AppConfig.Key.developerTunnelPort)

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: devIP)

        // Keep Apple's developer tunnel reachable through this app's tunnel.
        let devRoute = NEIPv4Route(destinationAddress: devIP, subnetMask: "255.255.255.255")
        settings.ipv4Settings = NEIPv4Settings(addresses: ["10.7.0.2"], subnetMasks: ["255.255.255.252"])
        settings.ipv4Settings?.includedRoutes = [devRoute]

        // If a VPN profile is supplied, default egress is added by the selected adapter.
        // WireGuard is the first supported provider profile format.
        if vpnKind == "wireguard", !vpnConfig.isEmpty {
            do {
                let wg = WireGuardAdapter()
                try wg.apply(config: vpnConfig, settings: settings)
            } catch {
                completionHandler(error)
                return
            }
        }

        setTunnelNetworkSettings(settings) { error in
            if let error {
                completionHandler(error)
                return
            }
            self.startLocalPacketLoop()
            self.startPathMonitor()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        monitor?.cancel()
        monitor = nil
        completionHandler()
    }

    private func startLocalPacketLoop() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self else { return }
            // Local developer tunnel traffic is already routed by the OS into utun.
            // Forward packets unchanged; egress adapters may rewrite in later phases.
            self.packetFlow.writePackets(packets, withProtocols: protocols)
            self.startLocalPacketLoop()
        }
    }

    private func startPathMonitor() {
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { path in
            let state = path.status == .satisfied ? "connected" : "disconnected"
            AppConfig.defaults.set(state, forKey: "tunnelPathStatus")
        }
        monitor.start(queue: DispatchQueue(label: "lvs.path.monitor"))
    }
}

struct WireGuardAdapter {
    func apply(config: String, settings: NEPacketTunnelNetworkSettings) throws {
        let parser = WireGuardConfigParser(text: config)
        let parsed = try parser.parse()

        if let ipv4 = settings.ipv4Settings {
            var routes = ipv4.includedRoutes ?? []
            routes.append(NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "0.0.0.0"))
            ipv4.includedRoutes = routes
        }
        settings.dnsSettings = NEDNSSettings(servers: parsed.dnsServers.isEmpty ? ["1.1.1.1"] : parsed.dnsServers)
        settings.mtu = NSNumber(value: parsed.mtu ?? 1420)
    }
}

struct WireGuardConfig {
    var privateKey: String
    var peerPublicKey: String
    var endpoint: String
    var allowedIPs: [String]
    var dnsServers: [String]
    var mtu: Int?
}

struct WireGuardConfigParser {
    let text: String

    func parse() throws -> WireGuardConfig {
        var privateKey = ""
        var peerPublicKey = ""
        var endpoint = ""
        var allowedIPs: [String] = []
        var dnsServers: [String] = []
        var mtu: Int?

        var section = ""
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }
            if line.hasPrefix("[") {
                section = line
                continue
            }

            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch (section, key) {
            case ("[Interface]", "PrivateKey"): privateKey = value
            case ("[Interface]", "DNS"): dnsServers = value.split(separator: ",").map(String.init)
            case ("[Interface]", "MTU"): mtu = Int(value)
            case ("[Peer]", "PublicKey"): peerPublicKey = value
            case ("[Peer]", "Endpoint"): endpoint = value
            case ("[Peer]", "AllowedIPs"): allowedIPs = value.split(separator: ",").map(String.init)
            default: break
            }
        }

        guard !privateKey.isEmpty, !peerPublicKey.isEmpty, !endpoint.isEmpty else {
            throw NSError(domain: "LVSWireGuard", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "WireGuard config needs PrivateKey, PublicKey, and Endpoint."
            ])
        }

        return WireGuardConfig(
            privateKey: privateKey,
            peerPublicKey: peerPublicKey,
            endpoint: endpoint,
            allowedIPs: allowedIPs,
            dnsServers: dnsServers,
            mtu: mtu
        )
    }
}
