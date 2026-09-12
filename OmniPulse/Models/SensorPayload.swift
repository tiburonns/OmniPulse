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
    let uptimeSeconds: UInt64?
    let freeHeapBytes: Int?
    let observations: [SensorObservation]
}

struct SensorCalibration: Codable, Hashable, Sendable {
    let sensorID: String
    var rssiOffset: Int
    var updatedAt: Date

    static func standard(for sensorID: String) -> SensorCalibration {
        SensorCalibration(sensorID: sensorID, rssiOffset: 0, updatedAt: .now)
    }
}

enum SensorHealthLevel: String, Sendable {
    case healthy
    case attention
    case stale
    case waiting
}

struct SensorHealth: Sendable {
    var level: SensorHealthLevel
    var title: String
    var detail: String
}

enum SensorPayloadDecodingError: LocalizedError {
    case unsupportedVersion(Int)
    case missingSensorID
    case payloadTooLarge
    case invalidObservation

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            "Versión de protocolo no compatible: \(version)."
        case .missingSensorID:
            "El lote no contiene un identificador de sensor."
        case .payloadTooLarge:
            "El lote del sensor supera los límites permitidos."
        case .invalidObservation:
            "El lote contiene una observación inválida o duplicada."
        }
    }
}

enum SensorPayloadDecoder {
    static let maximumPayloadBytes = 256 * 1_024
    static let maximumObservations = 256

    static func decode(_ data: Data) throws -> SensorPayload {
        guard data.count <= maximumPayloadBytes else {
            throw SensorPayloadDecodingError.payloadTooLarge
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(SensorPayload.self, from: data)

        guard payload.version == 1 else {
            throw SensorPayloadDecodingError.unsupportedVersion(payload.version)
        }
        let sensorID = payload.sensorID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sensorID.isEmpty, sensorID.count <= 128 else {
            throw SensorPayloadDecodingError.missingSensorID
        }
        guard payload.observations.count <= maximumObservations,
              payload.freeHeapBytes.map({ $0 >= 0 }) ?? true,
              [payload.sensorName, payload.firmwareVersion, payload.hardware]
                .compactMap({ $0 }).allSatisfy({ $0.count <= 128 }) else {
            throw SensorPayloadDecodingError.payloadTooLarge
        }

        var identifiers = Set<String>()
        for observation in payload.observations {
            let identifier = observation.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            let identity = "\(observation.kind.rawValue):\(identifier)"
            guard !identifier.isEmpty,
                  identifier.count <= 256,
                  (observation.name?.count ?? 0) <= 256,
                  (-127...20).contains(observation.rssi),
                  observation.channel.map({ (1...233).contains($0) }) ?? true,
                  (observation.services?.count ?? 0) <= 32,
                  observation.services?.allSatisfy({ $0.count <= 128 }) ?? true,
                  identifiers.insert(identity).inserted else {
                throw SensorPayloadDecodingError.invalidObservation
            }
        }

        return payload
    }
}
