#if os(iOS)
import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
final class PhoneWatchConnectivity: NSObject {
    private(set) var activationState = "Preparando Apple Watch"

    @ObservationIgnored private var session: WCSession?
    @ObservationIgnored private var snapshotProvider: (() -> WatchAppSnapshot)?
    @ObservationIgnored private var commandHandler: ((WatchCommand) -> Void)?
    @ObservationIgnored private var pendingSnapshotTask: Task<Void, Never>?

    override init() {
        super.init()
        guard WCSession.isSupported() else {
            activationState = "WatchConnectivity no disponible"
            return
        }
        let session = WCSession.default
        self.session = session
        session.delegate = self
        session.activate()
    }

    func configure(
        snapshotProvider: @escaping () -> WatchAppSnapshot,
        commandHandler: @escaping (WatchCommand) -> Void
    ) {
        self.snapshotProvider = snapshotProvider
        self.commandHandler = commandHandler
        sendCurrentSnapshot(immediately: true)
    }

    func sendCurrentSnapshot(immediately: Bool = false) {
        if immediately {
            pendingSnapshotTask?.cancel()
            pendingSnapshotTask = nil
            sendSnapshotNow()
            return
        }
        guard pendingSnapshotTask == nil else { return }
        pendingSnapshotTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled, let self else { return }
            self.pendingSnapshotTask = nil
            self.sendSnapshotNow()
        }
    }

    private func sendSnapshotNow() {
        guard let session, let payload = currentPayload() else { return }
        try? session.updateApplicationContext(payload)
    }

    private func currentPayload() -> [String: Any]? {
        guard let snapshotProvider,
              let data = try? JSONEncoder().encode(snapshotProvider()) else { return nil }
        return ["snapshot": data]
    }

    private func handle(_ message: [String: Any]) {
        guard let rawCommand = message["command"] as? String,
              let command = WatchCommand(rawValue: rawCommand) else { return }
        commandHandler?(command)
        sendCurrentSnapshot(immediately: true)
    }
}

extension PhoneWatchConnectivity: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.activationState = error?.localizedDescription
                ?? (activationState == .activated ? "Apple Watch enlazado" : "Apple Watch no enlazado")
            self.sendCurrentSnapshot(immediately: true)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.handle(message) }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            self.handle(message)
            replyHandler(self.currentPayload() ?? [:])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in self.handle(userInfo) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.handle(applicationContext) }
    }
}
#endif
