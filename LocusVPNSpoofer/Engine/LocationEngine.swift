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
    func prepare(pairingPath: String, tunnelIP: String, tunnelPort: UInt16) throws
    func setLocation(_ target: SpoofTarget) throws
    func clearLocation() throws
    func isReady() -> Bool
}

/// Swift bridge to the vendored idevice FFI library.
/// The C ABI is declared in `Engine/idevice_bridge.h` and implemented by
/// `Vendor/idevice/libidevice_ffi.a` copied from the Locus source tree.
final class LocationEngine: LocationSpoofing {
    private var handle: UnsafeMutableRawPointer?
    private var pairingPath: String?
    private var tunnelIP: String?
    private var tunnelPort: UInt16?

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

        let ok = lvs_engine_prepare(
            pairingPath,
            tunnelIP,
            Int32(tunnelPort),
            &handle
        )

        if !ok || handle == nil {
            throw SpoofError.engineFailure("prepare returned false")
        }
    }

    func setLocation(_ target: SpoofTarget) throws {
        guard handle != nil else { throw SpoofError.tunnelMissing }
        guard (-90...90).contains(target.latitude), (-180...180).contains(target.longitude) else {
            throw SpoofError.invalidCoordinates
        }

        let ok = lvs_engine_set_location(
            handle,
            target.latitude,
            target.longitude,
            target.altitude,
            target.speed,
            target.course
        )

        if !ok {
            throw SpoofError.engineFailure("location_simulation_set failed")
        }

        AppConfig.defaults.set(target.latitude, forKey: AppConfig.Key.spoofLatitude)
        AppConfig.defaults.set(target.longitude, forKey: AppConfig.Key.spoofLongitude)
        AppConfig.defaults.set(true, forKey: AppConfig.Key.spoofActive)
    }

    func clearLocation() throws {
        guard handle != nil else { return }
        lvs_engine_clear_location(handle)
        AppConfig.defaults.set(false, forKey: AppConfig.Key.spoofActive)
    }

    func isReady() -> Bool {
        handle != nil
    }

    deinit {
        if let handle { lvs_engine_destroy(handle) }
    }
}
