import Foundation

struct VPNProfile: Codable, Equatable {
    enum Kind: String, Codable {
        case wireguard
        case openvpn
        case ikev2
    }

    var name: String
    var kind: Kind
    var config: String
    var createdAt = Date()

    static func load() -> VPNProfile? {
        guard let data = AppConfig.defaults.data(forKey: AppConfig.Key.vpnProfile) else { return nil }
        return try? JSONDecoder().decode(VPNProfile.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppConfig.defaults.set(data, forKey: AppConfig.Key.vpnProfile)
    }

    static func remove() {
        AppConfig.defaults.removeObject(forKey: AppConfig.Key.vpnProfile)
    }
}
