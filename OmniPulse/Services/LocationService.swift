import CoreLocation
import Foundation
import Observation

@Observable
final class LocationService: NSObject {
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var latestLocation: CLLocation?
    private(set) var lastError: String?
    private(set) var isUpdating = false
    private(set) var isVehicleTracking = false

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var vehicleTrackingOwners: Set<String> = []
    @ObservationIgnored private var injectedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
#if DEBUG
        let processInfo = ProcessInfo.processInfo
        let environmentLocation =
            processInfo.environment["OMNIPULSE_UI_TEST_LOCATION"]
        let arguments = processInfo.arguments
        let argumentLocation: String? = {
            guard let index = arguments.firstIndex(
                of: "--ui-test-location"
            ),
            arguments.indices.contains(index + 1) else {
                return nil
            }
            return arguments[index + 1]
        }()

        if let rawLocation =
            environmentLocation ?? argumentLocation {
            let parts = rawLocation
                .split(
                    separator: ",",
                    maxSplits: 1,
                    omittingEmptySubsequences: false
                )
                .compactMap {
                    Double(
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    )
                }
            if parts.count == 2,
               (-90...90).contains(parts[0]),
               (-180...180).contains(parts[1]) {
                injectedLocation = CLLocation(
                    latitude: parts[0],
                    longitude: parts[1]
                )
            }
        }
#endif
    }

    func requestCurrentLocation() {
        lastError = nil
        if let injectedLocation {
            latestLocation = injectedLocation
#if os(macOS)
            authorizationStatus = .authorizedAlways
#else
            authorizationStatus = .authorizedWhenInUse
#endif
            isUpdating = false
            return
        }
        guard CLLocationManager.locationServicesEnabled() else {
            lastError = "Los servicios de ubicación están desactivados en el sistema."
            isUpdating = false
            return
        }

        if isVehicleTracking {
            startVehicleLocationUpdates()
            return
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            isUpdating = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isUpdating = true
            manager.requestLocation()
        case .denied, .restricted:
            lastError = "Autoriza la ubicación en Ajustes para guardar coordenadas."
            isUpdating = false
        @unknown default:
            lastError = "No se pudo determinar el permiso de ubicación."
            isUpdating = false
        }
    }

    func stopUpdatingLocation() {
        guard !isVehicleTracking else { return }
        manager.stopUpdatingLocation()
        isUpdating = false
    }

    func setVehicleTracking(_ active: Bool, owner: String) {
        if active {
            vehicleTrackingOwners.insert(owner)
        } else {
            vehicleTrackingOwners.remove(owner)
        }

        let shouldTrack = !vehicleTrackingOwners.isEmpty
        guard shouldTrack != isVehicleTracking else { return }
        isVehicleTracking = shouldTrack

        if shouldTrack {
            startVehicleLocationUpdates()
        } else {
            manager.stopUpdatingLocation()
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter = kCLDistanceFilterNone
        }
    }

    func freshLocation(maxAge: TimeInterval = 15) -> CLLocation? {
        guard let latestLocation,
              latestLocation.horizontalAccuracy >= 0,
              Date().timeIntervalSince(latestLocation.timestamp) <= maxAge else { return nil }
        return latestLocation
    }

    private func startVehicleLocationUpdates() {
        lastError = nil
        guard CLLocationManager.locationServicesEnabled() else {
            lastError = "Los servicios de ubicación están desactivados en el sistema."
            isVehicleTracking = false
            vehicleTrackingOwners.removeAll()
            return
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 5
            manager.startUpdatingLocation()
        case .denied, .restricted:
            lastError = "Autoriza la ubicación en Ajustes para usar el modo vehículo."
            isVehicleTracking = false
            vehicleTrackingOwners.removeAll()
        @unknown default:
            lastError = "No se pudo determinar el permiso de ubicación."
            isVehicleTracking = false
            vehicleTrackingOwners.removeAll()
        }
    }

    private func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
#if os(macOS)
        status == .authorizedAlways
#else
        status == .authorizedWhenInUse || status == .authorizedAlways
#endif
    }

    var statusDescription: String {
        if isUpdating {
            return authorizationStatus == .notDetermined ? "Solicitando permiso…" : "Actualizando…"
        }
        if isVehicleTracking {
            return latestLocation == nil ? "Modo vehículo; esperando posición" : "Seguimiento continuo activo"
        }
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return latestLocation == nil ? "Autorizada; esperando una posición" : "Ubicación lista"
        case .notDetermined:
            return "Sin solicitar"
        case .denied:
            return "Denegada"
        case .restricted:
            return "Restringida"
        @unknown default:
            return "Desconocida"
        }
    }

    var needsSettings: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isVehicleTracking && isAuthorized(manager.authorizationStatus) {
            startVehicleLocationUpdates()
        } else if isUpdating && isAuthorized(manager.authorizationStatus) {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            isUpdating = false
            lastError = "Autoriza la ubicación en Ajustes para guardar coordenadas."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        latestLocation = location
        lastError = nil
        if !isVehicleTracking {
            isUpdating = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if isVehicleTracking, (error as? CLError)?.code == .locationUnknown {
            return
        }
        lastError = error.localizedDescription
        if !isVehicleTracking {
            isUpdating = false
        }
    }
}
