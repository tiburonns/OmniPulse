import Foundation

enum WatchDetectionFallbackName: String, Codable, Hashable, Sendable {
    case hiddenNetwork
    case bluetoothDevice
    case unnamedDevice
}

struct WatchDetectionSummary: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let transport: String
    let rssi: Int
    let seenAt: Date
    let latitude: Double?
    let longitude: Double?
    var fallbackName: WatchDetectionFallbackName? = nil
}

enum WatchSensorConnectionState: String, Codable, Equatable, Sendable {
    case idle
    case searching
    case connecting
    case connected
    case unavailable
    case failed
}

struct WatchAppSnapshot: Codable, Equatable, Sendable {
    var isScanning: Bool
    var isVehicleMode: Bool

    // Kept for compatibility with application-context payloads produced by
    // earlier builds. New builds render the semantic state locally so the
    // Apple Watch can use its own language.
    var connectionStatus: String
    var connectionState: WatchSensorConnectionState? = nil
    var connectionName: String? = nil

    var connectedSensorCount: Int
    var detections: [WatchDetectionSummary]
    var updatedAt: Date

    static let empty = WatchAppSnapshot(
        isScanning: false,
        isVehicleMode: false,
        connectionStatus: "",
        connectionState: .idle,
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
