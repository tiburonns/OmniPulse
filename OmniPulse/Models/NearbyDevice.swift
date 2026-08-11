import CoreLocation
import Foundation

struct DetectionLocation: Hashable, Sendable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
    let timestamp: Date

    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
        timestamp = location.timestamp
    }

    var location: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }
}

enum DetectionSource: String, Codable, CaseIterable, Sendable {
    case iphoneBLE = "iPhone BLE"
    case nativeWiFi = "iPhone Wi-Fi"
    case esp32BLE = "ESP32 BLE"
    case esp32WiFi = "Wi-Fi"

    var transportLabel: String {
        switch self {
        case .iphoneBLE:
            "BLE"
        case .nativeWiFi:
            "Wi-Fi"
        case .esp32BLE:
            "ESP32 BLE"
        case .esp32WiFi:
            "Wi-Fi"
        }
    }
}

struct NearbyDevice: Identifiable, Hashable, Sendable {
    let identifier: String
    var name: String
    var rssi: Int
    let source: DetectionSource
    let firstSeen: Date
    var lastSeen: Date
    var advertisedServices: [String]
    var manufacturerIdentifier: Int?
    var manufacturerName: String?
    var deviceCategory: String?
    var beaconType: String?
    var advertisementInterval: TimeInterval?
    var detectionLocation: DetectionLocation?

    var id: String { identifier }

    var displayName: String {
        name.isEmpty ? "Dispositivo sin nombre" : name
    }

    init(
        identifier: String,
        name: String,
        rssi: Int,
        source: DetectionSource = .iphoneBLE,
        firstSeen: Date = .now,
        lastSeen: Date = .now,
        advertisedServices: [String] = [],
        manufacturerIdentifier: Int? = nil,
        manufacturerName: String? = nil,
        deviceCategory: String? = nil,
        beaconType: String? = nil,
        advertisementInterval: TimeInterval? = nil,
        detectionLocation: DetectionLocation? = nil
    ) {
        self.identifier = identifier
        self.name = name
        self.rssi = rssi
        self.source = source
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.advertisedServices = advertisedServices
        self.manufacturerIdentifier = manufacturerIdentifier
        self.manufacturerName = manufacturerName
        self.deviceCategory = deviceCategory
        self.beaconType = beaconType
        self.advertisementInterval = advertisementInterval
        self.detectionLocation = detectionLocation
    }

    func refreshed(
        name: String,
        rssi: Int,
        advertisedServices: [String],
        manufacturerIdentifier: Int? = nil,
        manufacturerName: String? = nil,
        deviceCategory: String? = nil,
        beaconType: String? = nil,
        advertisementInterval: TimeInterval? = nil,
        detectionLocation: DetectionLocation? = nil,
        at date: Date = .now
    ) -> NearbyDevice {
        var copy = self
        copy.name = name.isEmpty ? self.name : name
        copy.rssi = rssi
        copy.lastSeen = date
        copy.advertisedServices = advertisedServices
        copy.manufacturerIdentifier = manufacturerIdentifier ?? self.manufacturerIdentifier
        copy.manufacturerName = manufacturerName ?? self.manufacturerName
        copy.deviceCategory = deviceCategory ?? self.deviceCategory
        copy.beaconType = beaconType ?? self.beaconType
        copy.advertisementInterval = advertisementInterval ?? self.advertisementInterval
        if let detectionLocation {
            copy.detectionLocation = detectionLocation
        }
        return copy
    }
}
