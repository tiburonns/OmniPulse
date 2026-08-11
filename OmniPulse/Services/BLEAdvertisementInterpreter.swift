import CoreBluetooth
import Foundation

struct BLEAdvertisementIdentity: Equatable, Sendable {
    let manufacturerIdentifier: Int?
    let manufacturerName: String?
    let category: String
    let beaconType: String?
}

enum BLEAdvertisementInterpreter {
    private static let manufacturers: [Int: String] = [
        0x0006: "Microsoft",
        0x004C: "Apple",
        0x0059: "Nordic Semiconductor",
        0x0075: "Samsung",
        0x0087: "Garmin",
        0x00E0: "Google",
        0x02E5: "Espressif Systems"
    ]

    static func identify(name: String, advertisementData: [String: Any]) -> BLEAdvertisementIdentity {
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let manufacturerIdentifier = companyIdentifier(in: manufacturerData)
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
            .map { $0.uuidString.uppercased() }
        let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] ?? [:]
        let beaconType = beaconType(
            manufacturerIdentifier: manufacturerIdentifier,
            manufacturerData: manufacturerData,
            services: services,
            serviceData: serviceData
        )
        return BLEAdvertisementIdentity(
            manufacturerIdentifier: manufacturerIdentifier,
            manufacturerName: manufacturerIdentifier.flatMap { manufacturers[$0] } ?? manufacturerIdentifier.map {
                String(format: "Fabricante 0x%04X", $0)
            },
            category: category(name: name, services: services, beaconType: beaconType),
            beaconType: beaconType
        )
    }

    static func companyIdentifier(in data: Data?) -> Int? {
        guard let data, data.count >= 2 else { return nil }
        return Int(data[data.startIndex]) | (Int(data[data.startIndex + 1]) << 8)
    }

    private static func beaconType(
        manufacturerIdentifier: Int?,
        manufacturerData: Data?,
        services: [String],
        serviceData: [CBUUID: Data]
    ) -> String? {
        if manufacturerIdentifier == 0x004C,
           let manufacturerData,
           manufacturerData.count >= 4,
           manufacturerData[manufacturerData.startIndex + 2] == 0x02,
           manufacturerData[manufacturerData.startIndex + 3] == 0x15 {
            return "iBeacon"
        }

        if services.contains("FEAA") || serviceData.keys.contains(CBUUID(string: "FEAA")) {
            guard let frame = serviceData[CBUUID(string: "FEAA")]?.first else { return "Eddystone" }
            switch frame {
            case 0x00: return "Eddystone UID"
            case 0x10: return "Eddystone URL"
            case 0x20: return "Eddystone TLM"
            case 0x30: return "Eddystone EID"
            default: return "Eddystone"
            }
        }
        return nil
    }

    private static func category(name: String, services: [String], beaconType: String?) -> String {
        if beaconType != nil { return "Beacon" }
        let normalizedName = name.lowercased()
        if normalizedName.contains("airpods") || normalizedName.contains("beats") { return "Audio" }
        if normalizedName.contains("watch") || normalizedName.contains("band") { return "Wearable" }
        if normalizedName.contains("keyboard") || normalizedName.contains("mouse") { return "Entrada" }
        if normalizedName.contains("esp32") || normalizedName.contains("omnipulse") { return "IoT / ESP32" }
        if services.contains("180D") { return "Salud" }
        if services.contains("181A") { return "Sensor ambiental" }
        if services.contains("1812") { return "Entrada" }
        if services.contains("180F") { return "Sensor con batería" }
        return "Dispositivo BLE"
    }
}
