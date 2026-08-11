import Foundation
import Network
import Observation

@Observable
@MainActor
final class NativeWiFiService {
    private(set) var isConnectedViaWiFi = false
    private(set) var isLoading = false
    private(set) var status = "Comprobando la conexión Wi-Fi…"

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let monitorQueue = DispatchQueue(label: "OmniPulse.NativeWiFi")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.update(with: path)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func refresh() {
        isLoading = true
        update(with: monitor.currentPath)
    }

    private func update(with path: NWPath) {
        isLoading = false
        isConnectedViaWiFi = path.status == .satisfied && path.usesInterfaceType(.wifi)
        status = isConnectedViaWiFi
            ? "El iPhone está conectado mediante Wi-Fi."
            : "El iPhone no está usando una conexión Wi-Fi."
    }
}
