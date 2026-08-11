import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct DetectionExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }

    var csv: String

    init(records: [DetectionRecord]) {
        let header = [
            "id", "deviceIdentifier", "deviceName", "transport", "source", "rssi", "wifiChannel",
            "wifiBand", "manufacturer", "category", "beaconType", "advertisementInterval",
            "sensorID", "sensorHardware", "sensorFirmware", "projectID",
            "seenAt", "latitude", "longitude", "horizontalAccuracy", "floorPlanX", "floorPlanY"
        ]
        let rows = records.map { record in
            var rawFields: [String] = []
            rawFields.append(record.id.uuidString)
            rawFields.append(record.deviceIdentifier)
            rawFields.append(record.displayName)
            rawFields.append(record.transport)
            rawFields.append(record.source)
            rawFields.append(String(record.rssi))
            rawFields.append(record.wifiChannel.map { String($0) } ?? "")
            rawFields.append(record.wifiBand ?? "")
            rawFields.append(record.manufacturerName ?? "")
            rawFields.append(record.deviceCategory ?? "")
            rawFields.append(record.beaconType ?? "")
            rawFields.append(record.advertisementInterval.map { String($0) } ?? "")
            rawFields.append(record.sensorIdentifier ?? "")
            rawFields.append(record.sensorHardware ?? "")
            rawFields.append(record.sensorFirmwareVersion ?? "")
            rawFields.append(record.projectID?.uuidString ?? "")
            rawFields.append(ISO8601DateFormatter().string(from: record.seenAt))
            rawFields.append(record.latitude.map { String($0) } ?? "")
            rawFields.append(record.longitude.map { String($0) } ?? "")
            rawFields.append(record.horizontalAccuracy.map { String($0) } ?? "")
            rawFields.append(record.floorPlanX.map { String($0) } ?? "")
            rawFields.append(record.floorPlanY.map { String($0) } ?? "")
            let escapedFields = rawFields.map(Self.escapedCSVField)
            return escapedFields.joined(separator: ",")
        }
        let escapedHeader = header.map(Self.escapedCSVField).joined(separator: ",")
        csv = ([escapedHeader] + rows).joined(separator: "\n")
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        csv = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(csv.utf8))
    }

    private static func escapedCSVField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
