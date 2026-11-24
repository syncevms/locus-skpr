import Foundation

enum SpoofError: LocalizedError {
    case pairingMissing
    case tunnelMissing
    case invalidCoordinates
    case engineFailure(String)

    var errorDescription: String? {
        switch self {
        case .pairingMissing:
            return "Import or create an RPPairing file first."
        case .tunnelMissing:
            return "Start the embedded tunnel first."
        case .invalidCoordinates:
            return "Latitude or longitude is invalid."
        case .engineFailure(let detail):
            return "Location engine failed: \(detail)"
        }
    }
}

struct SpoofTarget {
    var latitude: Double
    var longitude: Double
    var altitude: Double = 0
    var speed: Double = 0
    var course: Double = 0
}

protocol LocationSpoofing {
    func prepare(pairingPath: String, tunnelIP: String, tunnelPort: UInt16) throws {
        guard FileManager.default.fileExists(atPath: pairingPath) else {
            throw SpoofError.pairingMissing
        }
        guard !tunnelIP.isEmpty else {
            throw SpoofError.tunnelMissing
        }
        self.pairingPath = pairingPath
        self.tunnelIP = tunnelIP
        self.tunnelPort = tunnelPort
        self.handle = UnsafeMutableRawPointer(bitPattern: 0x4C565350)
    }

    func setLocation(_ target: SpoofTarget) throws {
        guard handle != nil else { throw SpoofError.tunnelMissing }
        guard (-90...90).contains(target.latitude), (-180...180).contains(target.longitude) else {
            throw SpoofError.invalidCoordinates
        }
        AppConfig.defaults.set(target.latitude, forKey: AppConfig.Key.spoofLatitude)
        AppConfig.defaults.set(target.longitude, forKey: AppConfig.Key.spoofLongitude)
        AppConfig.defaults.set(true, forKey: AppConfig.Key.spoofActive)
    }

    func clearLocation() throws {
        AppConfig.defaults.set(false, forKey: AppConfig.Key.spoofActive)
    }

    func isReady() -> Bool {
        handle != nil
    }

}
