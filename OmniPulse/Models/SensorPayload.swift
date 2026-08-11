import Foundation

enum SensorObservationKind: String, Codable, Sendable {
    case wifiNetwork
    case bluetoothLE
}

struct SensorObservation: Codable, Hashable, Identifiable, Sendable {
    let kind: SensorObservationKind
    let identifier: String
    let name: String?
    let rssi: Int
    let channel: Int?
    let manufacturerID: Int?
    let services: [String]?
    let beaconType: String?
    let seenAt: Date?

    var id: String { identifier }
}

struct SensorPayload: Codable, Sendable {
    let version: Int
    let sensorID: String
    let sensorName: String?
    let firmwareVersion: String?
    let hardware: String?
    let capturedAt: Date?
    let observations: [SensorObservation]
}

enum SensorPayloadDecodingError: LocalizedError {
    case unsupportedVersion(Int)
    case missingSensorID

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            "Versión de protocolo no compatible: \(version)."
        case .missingSensorID:
            "El lote no contiene un identificador de sensor."
        }
    }
}

enum SensorPayloadDecoder {
    static func decode(_ data: Data) throws -> SensorPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(SensorPayload.self, from: data)

        guard payload.version == 1 else {
            throw SensorPayloadDecodingError.unsupportedVersion(payload.version)
        }
        guard !payload.sensorID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SensorPayloadDecodingError.missingSensorID
        }

        return payload
    }
}
