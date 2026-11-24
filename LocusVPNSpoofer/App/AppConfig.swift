import Foundation

enum AppConfig {
    static let appGroup = "group.com.skpr.locusvpnspoofer"
    static let bundleID = "com.skpr.locusvpnspoofer"
    static let tunnelBundleID = "com.skpr.locusvpnspoofer.tunnel"
    static let defaultDeveloperTunnelIP = "10.7.0.1"
    static let defaultDeveloperTunnelPort: UInt16 = 49152

    enum Key {
        static let developerTunnelIP = "developerTunnelIP"
        static let developerTunnelPort = "developerTunnelPort"
        static let vpnProfile = "vpnProfile"
        static let tunnelEnabled = "tunnelEnabled"
        static let spoofLatitude = "spoofLatitude"
        static let spoofLongitude = "spoofLongitude"
        static let spoofActive = "spoofActive"
        static let lastError = "lastError"
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static var developerTunnelIP: String {
        let raw = defaults.string(forKey: Key.developerTunnelIP) ?? defaultDeveloperTunnelIP
        let host = raw.split(separator: "/").first.map(String.init) ?? raw
        return host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultDeveloperTunnelIP : host
    }

    static var developerTunnelPort: UInt16 {
        let value = defaults.integer(forKey: Key.developerTunnelPort)
        return value == 0 ? defaultDeveloperTunnelPort : UInt16(truncatingIfNeeded: value)
    }
}
