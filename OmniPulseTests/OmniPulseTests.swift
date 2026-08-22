import CoreBluetooth
import CoreLocation
import XCTest
@testable import OmniPulse

final class OmniPulseTests: XCTestCase {
    func testRefreshingNearbyDeviceKeepsItsOriginalDiscoveryTime() {
        let firstSeen = Date(timeIntervalSince1970: 1_000)
        let updatedAt = Date(timeIntervalSince1970: 1_100)
        let device = NearbyDevice(
            identifier: "device-1",
            name: "Sensor",
            rssi: -72,
            firstSeen: firstSeen,
            lastSeen: firstSeen
        )

        let refreshed = device.refreshed(
            name: "Sensor actualizado",
            rssi: -55,
            advertisedServices: ["180F"],
            at: updatedAt
        )

        XCTAssertEqual(refreshed.firstSeen, firstSeen)
        XCTAssertEqual(refreshed.lastSeen, updatedAt)
        XCTAssertEqual(refreshed.rssi, -55)
        XCTAssertEqual(refreshed.advertisedServices, ["180F"])
    }

    func testRefreshingNearbyDeviceReplacesItsDetectionLocation() {
        let firstLocation = CLLocation(latitude: 25.6866, longitude: -100.3161)
        let currentLocation = CLLocation(latitude: 25.6900, longitude: -100.3200)
        let device = NearbyDevice(
            identifier: "device-1",
            name: "Sensor",
            rssi: -72,
            detectionLocation: DetectionLocation(firstLocation)
        )

        let refreshed = device.refreshed(
            name: "Sensor",
            rssi: -55,
            advertisedServices: [],
            detectionLocation: DetectionLocation(currentLocation)
        )

        XCTAssertEqual(refreshed.detectionLocation?.latitude ?? 0, 25.6900, accuracy: 0.00001)
        XCTAssertEqual(refreshed.detectionLocation?.longitude ?? 0, -100.3200, accuracy: 0.00001)
    }

    func testDetectionRecordCapturesALocationSnapshot() {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 25.6866, longitude: -100.3161),
            altitude: 0,
            horizontalAccuracy: 12,
            verticalAccuracy: 20,
            timestamp: .now
        )
        let record = DetectionRecord(
            deviceIdentifier: "device-1",
            deviceName: "Sensor",
            transport: "BLE",
            source: "iPhone BLE",
            rssi: -51,
            location: location
        )

        guard let coordinate = record.coordinate else {
            return XCTFail("The record should keep the location coordinates.")
        }
        XCTAssertEqual(coordinate.latitude, 25.6866, accuracy: 0.00001)
        XCTAssertEqual(coordinate.longitude, -100.3161, accuracy: 0.00001)
        XCTAssertEqual(record.horizontalAccuracy ?? -1, 12)
    }

    func testSensorPayloadRejectsUnsupportedVersions() throws {
        let json = """
        {
          "version": 2,
          "sensorID": "sensor-1",
          "observations": []
        }
        """

        XCTAssertThrowsError(try SensorPayloadDecoder.decode(Data(json.utf8))) { error in
            XCTAssertEqual(error.localizedDescription, "Versión de protocolo no compatible: 2.")
        }
    }

    func testSensorPayloadDecodesWiFiChannel() throws {
        let json = """
        {
          "version": 1,
          "sensorID": "sensor-1",
          "sensorName": "OmniPulse 0001",
          "firmwareVersion": "1.2.0",
          "hardware": "ESP32-S3",
          "observations": [{
            "kind": "wifiNetwork",
            "identifier": "wifi-1",
            "name": "Laboratorio",
            "rssi": -61,
            "channel": 6
          }]
        }
        """

        let payload = try SensorPayloadDecoder.decode(Data(json.utf8))
        XCTAssertEqual(payload.observations.first?.channel, 6)
        XCTAssertEqual(payload.sensorName, "OmniPulse 0001")
        XCTAssertEqual(payload.firmwareVersion, "1.2.0")
        XCTAssertEqual(payload.hardware, "ESP32-S3")
    }

    func testCustomThemePaletteCanBePersisted() throws {
        var palette = ThemePalette.defaultCustom
        palette.accent = "12ABEF"
        palette.strongSignal = "00FF66"

        let data = try JSONEncoder().encode(palette)
        let restored = try JSONDecoder().decode(ThemePalette.self, from: data)

        XCTAssertEqual(restored, palette)
        XCTAssertEqual(restored.accent, "12ABEF")
        XCTAssertEqual(restored.strongSignal, "00FF66")
    }

    func testThemePresetsAreSeparatedByAppearance() {
        XCTAssertEqual(
            AppThemePreset.darkPresets.map(\.rawValue),
            ["dark", "slate", "moonlight", "midnight", "ember", "nord"]
        )
        XCTAssertEqual(
            AppThemePreset.lightPresets.map(\.rawValue),
            ["light", "indigo", "sunshine", "ocean", "forest", "rose", "lavender", "monochrome"]
        )
        XCTAssertTrue(AppThemePreset.darkPresets.allSatisfy {
            $0.category == .dark && $0.appearanceMode == .dark && $0.palette != nil
        })
        XCTAssertTrue(AppThemePreset.lightPresets.allSatisfy {
            $0.category == .light && $0.appearanceMode == .light && $0.palette != nil
        })
    }

    func testLegacyThemePresetMigration() {
        XCTAssertEqual(AppThemePreset.restored(from: "sunset"), .sunshine)
        XCTAssertEqual(AppThemePreset.restored(from: "cyber"), .midnight)
        XCTAssertEqual(AppThemePreset.restored(from: "graphite"), .slate)
        XCTAssertEqual(AppThemePreset.restored(from: "ocean"), .ocean)
        XCTAssertEqual(AppThemePreset.restored(from: "unknown"), .system)
    }

    func testChannelAnalyzerRecommendsTheLeastCongestedNonOverlappingChannel() {
        let samples = [
            WiFiChannelSample(identifier: "ap-1", name: "Oficina", channel: 1, rssi: -38),
            WiFiChannelSample(identifier: "ap-2", name: "Invitados", channel: 6, rssi: -48),
            WiFiChannelSample(identifier: "ap-3", name: "IoT", channel: 6, rssi: -62)
        ]

        let recommendation = WiFiChannelAnalyzer.recommendation(for: .twoPointFour, samples: samples)

        XCTAssertEqual(recommendation?.channel, 11)
    }

    func testChannelAnalyzerKeepsOnlyTheStrongestRepeatedObservation() {
        let records = [
            DetectionRecord(deviceIdentifier: "ap-1", deviceName: "Oficina", transport: "Wi-Fi", source: "ESP32", rssi: -72, wifiChannel: 6),
            DetectionRecord(deviceIdentifier: "ap-1", deviceName: "Oficina", transport: "Wi-Fi", source: "ESP32", rssi: -43, wifiChannel: 6)
        ]

        let samples = WiFiChannelAnalyzer.samples(from: records)

        XCTAssertEqual(samples.count, 1)
        XCTAssertEqual(samples.first?.rssi, -43)
    }

    func testBLEInterpreterReadsLittleEndianCompanyIdentifierAndIBeacon() {
        let manufacturerData = Data([0x4C, 0x00, 0x02, 0x15, 0x00])
        let identity = BLEAdvertisementInterpreter.identify(
            name: "Beacon de prueba",
            advertisementData: [CBAdvertisementDataManufacturerDataKey: manufacturerData]
        )

        XCTAssertEqual(identity.manufacturerIdentifier, 0x004C)
        XCTAssertEqual(identity.manufacturerName, "Apple")
        XCTAssertEqual(identity.beaconType, "iBeacon")
        XCTAssertEqual(identity.category, "Beacon")
    }

    func testSurveyReportProducesAPDF() {
        let project = SurveyProject(name: "Prueba")
        let records = [
            DetectionRecord(deviceIdentifier: "ap-1", deviceName: "Laboratorio", transport: "Wi-Fi", source: "ESP32", rssi: -51, wifiChannel: 36, projectID: project.id)
        ]

        let data = SurveyReportRenderer.render(project: project, records: records)

        XCTAssertTrue(data.starts(with: Data("%PDF".utf8)))
        XCTAssertGreaterThan(data.count, 500)
    }
}
