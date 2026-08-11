import Foundation

struct WatchDetectionSummary: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let transport: String
    let rssi: Int
    let seenAt: Date
    let latitude: Double?
    let longitude: Double?
}

struct WatchAppSnapshot: Codable, Equatable, Sendable {
    var isScanning: Bool
    var isVehicleMode: Bool
    var connectionStatus: String
    var connectedSensorCount: Int
    var detections: [WatchDetectionSummary]
    var updatedAt: Date

    static let empty = WatchAppSnapshot(
        isScanning: false,
        isVehicleMode: false,
        connectionStatus: "Esperando al iPhone",
        connectedSensorCount: 0,
        detections: [],
        updatedAt: .now
    )
}

enum WatchCommand: String, Codable, Sendable {
    case requestSnapshot
    case startScanning
    case stopScanning
    case enableVehicleMode
    case disableVehicleMode
    case saveCurrentBatch
}
