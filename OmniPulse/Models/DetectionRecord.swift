import CoreLocation
import Foundation
import SwiftData

@Model
final class DetectionRecord {
    @Attribute(.unique) var id: UUID
    var deviceIdentifier: String
    var deviceName: String
    var transport: String
    var source: String
    var rssi: Int
    var wifiChannel: Int?
    var seenAt: Date
    var latitude: Double?
    var longitude: Double?
    var horizontalAccuracy: Double?
    var projectID: UUID?
    var floorPlanX: Double?
    var floorPlanY: Double?
    var manufacturerName: String?
    var deviceCategory: String?
    var beaconType: String?
    var advertisementInterval: Double?
    var sensorIdentifier: String?
    var sensorHardware: String?
    var sensorFirmwareVersion: String?

    init(
        id: UUID = UUID(),
        deviceIdentifier: String,
        deviceName: String,
        transport: String,
        source: String,
        rssi: Int,
        wifiChannel: Int? = nil,
        seenAt: Date = .now,
        location: CLLocation? = nil,
        projectID: UUID? = nil,
        manufacturerName: String? = nil,
        deviceCategory: String? = nil,
        beaconType: String? = nil,
        advertisementInterval: Double? = nil,
        sensorIdentifier: String? = nil,
        sensorHardware: String? = nil,
        sensorFirmwareVersion: String? = nil
    ) {
        self.id = id
        self.deviceIdentifier = deviceIdentifier
        self.deviceName = deviceName
        self.transport = transport
        self.source = source
        self.rssi = rssi
        self.wifiChannel = wifiChannel
        self.seenAt = seenAt
        self.latitude = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
        self.horizontalAccuracy = location?.horizontalAccuracy
        self.projectID = projectID
        self.manufacturerName = manufacturerName
        self.deviceCategory = deviceCategory
        self.beaconType = beaconType
        self.advertisementInterval = advertisementInterval
        self.sensorIdentifier = sensorIdentifier
        self.sensorHardware = sensorHardware
        self.sensorFirmwareVersion = sensorFirmwareVersion
    }

    convenience init(nearbyDevice: NearbyDevice, location: CLLocation? = nil, projectID: UUID? = nil) {
        self.init(
            deviceIdentifier: nearbyDevice.identifier,
            deviceName: nearbyDevice.displayName,
            transport: nearbyDevice.source.transportLabel,
            source: nearbyDevice.source.rawValue,
            rssi: nearbyDevice.rssi,
            seenAt: nearbyDevice.lastSeen,
            location: location,
            projectID: projectID,
            manufacturerName: nearbyDevice.manufacturerName,
            deviceCategory: nearbyDevice.deviceCategory,
            beaconType: nearbyDevice.beaconType,
            advertisementInterval: nearbyDevice.advertisementInterval
        )
    }

    var displayName: String {
        deviceName.isEmpty ? "Dispositivo sin nombre" : deviceName
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var hasLocation: Bool {
        coordinate != nil
    }

    var wifiBand: String? {
        guard transport == "Wi-Fi", let wifiChannel else { return nil }
        return wifiChannel <= 14 ? "2.4 GHz" : "5 GHz"
    }

    var hasFloorPlanPosition: Bool {
        floorPlanX != nil && floorPlanY != nil
    }
}
