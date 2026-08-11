import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityClient: NSObject {
    private(set) var snapshot: WatchAppSnapshot = .empty
    private(set) var status = "Conectando con el iPhone"

    @ObservationIgnored private var session: WCSession?

    override init() {
        super.init()
        guard WCSession.isSupported() else {
            status = "Conexión con iPhone no disponible"
            return
        }
        let session = WCSession.default
        self.session = session
        session.delegate = self
        session.activate()
    }

    func send(_ command: WatchCommand) {
        guard let session else { return }
        let payload: [String: Any] = ["command": command.rawValue]
        if session.isReachable {
            session.sendMessage(payload) { [weak self] reply in
                Task { @MainActor in self?.consume(reply) }
            } errorHandler: { [weak self] error in
                Task { @MainActor in self?.status = error.localizedDescription }
            }
        } else {
            session.transferUserInfo(payload)
            status = "Comando en espera del iPhone"
        }
    }

    func refresh() { send(.requestSnapshot) }

    private func consume(_ payload: [String: Any]) {
        guard let data = payload["snapshot"] as? Data,
              let decoded = try? JSONDecoder().decode(WatchAppSnapshot.self, from: data) else { return }
        snapshot = decoded
        status = "Actualizado"
    }
}

extension WatchConnectivityClient: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.status = error?.localizedDescription ?? (activationState == .activated ? "Conectado al iPhone" : "Esperando al iPhone")
            self.refresh()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.consume(message) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.consume(applicationContext) }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in self.consume(userInfo) }
    }
}
