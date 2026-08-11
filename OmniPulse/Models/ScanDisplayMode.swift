import Foundation

enum ScanDisplayMode: String, CaseIterable, Identifiable {
    case discoveryOrder
    case vehicle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .discoveryOrder:
            "Detección"
        case .vehicle:
            "Vehículo"
        }
    }
}
