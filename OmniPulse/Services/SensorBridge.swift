import CoreBluetooth
import CoreLocation
import CryptoKit
import Foundation
import Observation

enum SensorConnectionState: Equatable {
    case idle
    case searching
    case connecting(String)
    case connected(String)
    case unavailable(String)
    case failed(String)

    var title: String {
        switch self {
        case .idle:
            "Listo para conectar"
        case .searching:
            "Buscando sensor"
        case .connecting(let name):
            "Conectando a \(name)"
        case .connected(let name):
            "Conectado a \(name)"
        case .unavailable:
            "Bluetooth no disponible"
        case .failed:
            "No se pudo conectar"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            "Busca un ESP32 OmniPulse cercano para recibir observaciones agregadas."
        case .searching:
            "Solo se buscan sensores que anuncian el servicio OmniPulse. La búsqueda se detiene tras un minuto sin detectar nuevos."
        case .connecting:
            "Descubriendo el servicio y sus notificaciones."
        case .connected:
            "Los lotes recibidos esperan tu confirmación antes de guardarse."
        case .unavailable(let reason), .failed(let reason):
            reason
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

struct ReceivedSensorBatch: Identifiable {
    let id: UUID
    let payload: SensorPayload
    let receivedAt: Date
    let detectionLocation: DetectionLocation?

    var observationCount: Int { payload.observations.count }
}

struct ConnectedSensor: Identifiable, Equatable {
    let id: UUID
    var advertisedName: String
    var sensorIdentifier: String? = nil
    var customName: String? = nil
    var firmwareVersion: String? = nil
    var hardware: String? = nil
    let connectedAt: Date
    var lastReceivedAt: Date? = nil

    var displayName: String {
        customName?.isEmpty == false ? customName! : advertisedName
    }
}

enum FirmwareUpdateStage: String, Sendable {
    case idle, preparing, transferring, verifying, completed, failed
}

struct SensorFirmwareUpdate: Equatable, Sendable {
    var stage: FirmwareUpdateStage = .idle
    var progress: Double = 0
    var message: String = "Listo para actualizar"
}

private final class FirmwareTransferSession {
    let package: FirmwarePackage
    let data: Data
    let controlCharacteristic: CBCharacteristic
    let dataCharacteristic: CBCharacteristic
    var offset = 0
    var didSendBegin = false
    var didSendFinish = false

    init(package: FirmwarePackage, data: Data, controlCharacteristic: CBCharacteristic, dataCharacteristic: CBCharacteristic) {
        self.package = package
        self.data = data
        self.controlCharacteristic = controlCharacteristic
        self.dataCharacteristic = dataCharacteristic
    }
}

@Observable
final class SensorBridge: NSObject {
    static let serviceUUID = CBUUID(string: "7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A101")
    static let observationsCharacteristicUUID = CBUUID(string: "7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A102")
    static let firmwareControlCharacteristicUUID = CBUUID(string: "7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A103")
    static let firmwareDataCharacteristicUUID = CBUUID(string: "7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A104")

    private(set) var state: SensorConnectionState = .unavailable("Inicializando Bluetooth.")
    private(set) var receivedBatches: [ReceivedSensorBatch] = []
    private(set) var connectedSensors: [ConnectedSensor] = []
    private(set) var isSearching = false
    private(set) var firmwareUpdates: [UUID: SensorFirmwareUpdate] = [:]

    @ObservationIgnored private var centralManager: CBCentralManager!
    @ObservationIgnored private var connectedPeripherals: [UUID: CBPeripheral] = [:]
    @ObservationIgnored private var connectingPeripherals: [UUID: CBPeripheral] = [:]
    @ObservationIgnored private var observationsCharacteristics: [UUID: CBCharacteristic] = [:]
    @ObservationIgnored private var firmwareControlCharacteristics: [UUID: CBCharacteristic] = [:]
    @ObservationIgnored private var firmwareDataCharacteristics: [UUID: CBCharacteristic] = [:]
    @ObservationIgnored private var firmwareSessions: [UUID: FirmwareTransferSession] = [:]
    @ObservationIgnored private var discoveryTimer: Timer?
    @ObservationIgnored private var shouldConnectWhenReady = false
    @ObservationIgnored private var sensorAliases: [String: String]
    @ObservationIgnored private var locationProvider: (() -> CLLocation?)?
    @ObservationIgnored var onStateChanged: (() -> Void)?

    private let maximumSensorConnections = 8
    private let discoveryInactivityTimeout: TimeInterval = 60

    override init() {
        sensorAliases = UserDefaults.standard.dictionary(forKey: "sensorAliases") as? [String: String] ?? [:]
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func useLocationProvider(_ provider: @escaping () -> CLLocation?) {
        locationProvider = provider
    }

    func findAndConnect() {
        shouldConnectWhenReady = true
        guard centralManager.state == .poweredOn else {
            updateState(for: centralManager.state)
            return
        }

        startDiscovery()
    }

    func connectAutomatically() {
        guard !isSearching else { return }
        findAndConnect()
    }

    private func startDiscovery() {
        guard connectedSensors.count + connectingPeripherals.count < maximumSensorConnections else {
            refreshConnectedState()
            return
        }

        isSearching = true
        if connectedSensors.isEmpty {
            state = .searching
        }
        centralManager.scanForPeripherals(withServices: [Self.serviceUUID], options: nil)
        scheduleDiscoveryTimeout()
    }

    private func scheduleDiscoveryTimeout() {
        discoveryTimer?.invalidate()
        discoveryTimer = Timer.scheduledTimer(withTimeInterval: discoveryInactivityTimeout, repeats: false) { [weak self] _ in
            self?.stopDiscovery()
        }
    }

    func disconnect() {
        shouldConnectWhenReady = false
        stopDiscovery()
        for peripheral in connectedPeripherals.values {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        for peripheral in connectingPeripherals.values {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        observationsCharacteristics.removeAll()
        firmwareControlCharacteristics.removeAll()
        firmwareDataCharacteristics.removeAll()
        firmwareSessions.removeAll()
        connectedPeripherals.removeAll()
        connectingPeripherals.removeAll()
        connectedSensors.removeAll()
        if centralManager.state == .poweredOn {
            state = .idle
        }
    }

    func stopSearching() {
        stopDiscovery()
    }

    private func stopDiscovery() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        centralManager.stopScan()
        isSearching = false
        refreshConnectedState()
    }

    private func refreshConnectedState() {
        guard !connectedSensors.isEmpty else {
            if centralManager.state == .poweredOn, !isSearching, connectingPeripherals.isEmpty {
                state = .idle
            }
            return
        }
        let label = connectedSensors.count == 1
            ? connectedSensors[0].displayName
            : "\(connectedSensors.count) sensores ESP32"
        state = .connected(label)
        onStateChanged?()
    }

    private func fail(_ message: String, peripheral: CBPeripheral? = nil) {
        if let peripheral {
            connectingPeripherals.removeValue(forKey: peripheral.identifier)
            observationsCharacteristics.removeValue(forKey: peripheral.identifier)
            firmwareControlCharacteristics.removeValue(forKey: peripheral.identifier)
            firmwareDataCharacteristics.removeValue(forKey: peripheral.identifier)
            firmwareSessions.removeValue(forKey: peripheral.identifier)
            connectedPeripherals.removeValue(forKey: peripheral.identifier)
            connectedSensors.removeAll { $0.id == peripheral.identifier }
            centralManager.cancelPeripheralConnection(peripheral)
        }
        if connectedSensors.isEmpty {
            state = .failed(message)
        } else {
            refreshConnectedState()
        }
    }

    func discard(_ batch: ReceivedSensorBatch) {
        receivedBatches.removeAll { $0.id == batch.id }
    }

    func ingestLocalNetworkPayload(_ payload: SensorPayload) {
        append(payload)
    }

    func rename(_ sensor: ConnectedSensor, to proposedName: String) {
        let trimmedName = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = aliasKey(for: sensor)
        if trimmedName.isEmpty {
            sensorAliases.removeValue(forKey: key)
        } else {
            sensorAliases[key] = trimmedName
        }
        UserDefaults.standard.set(sensorAliases, forKey: "sensorAliases")

        guard let index = connectedSensors.firstIndex(where: { $0.id == sensor.id }) else { return }
        connectedSensors[index].customName = trimmedName.isEmpty ? nil : trimmedName
        refreshConnectedState()
    }

    func firmwarePackage(for sensor: ConnectedSensor) -> FirmwarePackage? {
        guard firmwareControlCharacteristics[sensor.id] != nil,
              firmwareDataCharacteristics[sensor.id] != nil else { return nil }
        return FirmwareCatalog.package(for: sensor.hardware)
    }

    func startFirmwareUpdate(for sensor: ConnectedSensor) {
        let identifier = sensor.id
        guard firmwareSessions[identifier] == nil else { return }
        guard let peripheral = connectedPeripherals[identifier],
              let control = firmwareControlCharacteristics[identifier],
              let transfer = firmwareDataCharacteristics[identifier] else {
            firmwareUpdates[identifier] = SensorFirmwareUpdate(
                stage: .failed,
                message: "Este sensor aún no admite OTA. Flashea la versión 1.3.0 una vez por USB."
            )
            return
        }
        guard let package = firmwarePackage(for: sensor),
              let url = package.bundledURL(),
              let data = try? Data(contentsOf: url),
              !data.isEmpty else {
            firmwareUpdates[identifier] = SensorFirmwareUpdate(stage: .failed, message: "No se encontró el firmware compatible dentro de OmniPulse.")
            return
        }

        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let session = FirmwareTransferSession(package: package, data: data, controlCharacteristic: control, dataCharacteristic: transfer)
        firmwareSessions[identifier] = session
        firmwareUpdates[identifier] = SensorFirmwareUpdate(stage: .preparing, message: "Preparando \(package.version)…")
        let command = "{\"cmd\":\"begin\",\"size\":\(data.count),\"sha256\":\"\(digest)\"}"
        peripheral.writeValue(Data(command.utf8), for: control, type: .withResponse)
        session.didSendBegin = true
    }

    private func pumpFirmwareData(for peripheral: CBPeripheral) {
        guard let session = firmwareSessions[peripheral.identifier], session.didSendBegin, !session.didSendFinish else { return }
        let maximumLength = max(20, peripheral.maximumWriteValueLength(for: .withoutResponse))
        var writes = 0
        while session.offset < session.data.count, peripheral.canSendWriteWithoutResponse, writes < 8 {
            let end = min(session.offset + maximumLength, session.data.count)
            peripheral.writeValue(session.data.subdata(in: session.offset..<end), for: session.dataCharacteristic, type: .withoutResponse)
            session.offset = end
            writes += 1
            let progress = Double(session.offset) / Double(session.data.count)
            firmwareUpdates[peripheral.identifier] = SensorFirmwareUpdate(
                stage: .transferring,
                progress: progress,
                message: "Transfiriendo \(Int((progress * 100).rounded())) %"
            )
        }

        if session.offset >= session.data.count, !session.didSendFinish {
            session.didSendFinish = true
            firmwareUpdates[peripheral.identifier] = SensorFirmwareUpdate(stage: .verifying, progress: 1, message: "Verificando e instalando…")
            peripheral.writeValue(Data("{\"cmd\":\"finish\"}".utf8), for: session.controlCharacteristic, type: .withResponse)
        }
    }

    private func handleFirmwareStatus(_ data: Data, from peripheral: CBPeripheral) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let state = object["state"] as? String else { return }
        switch state {
        case "ready":
            pumpFirmwareData(for: peripheral)
        case "complete":
            let version = firmwareSessions[peripheral.identifier]?.package.version ?? FirmwareCatalog.currentVersion
            firmwareUpdates[peripheral.identifier] = SensorFirmwareUpdate(stage: .completed, progress: 1, message: "Firmware \(version) instalado; el sensor se reiniciará.")
            firmwareSessions.removeValue(forKey: peripheral.identifier)
        case "error":
            let message = object["message"] as? String ?? "El sensor rechazó la actualización."
            firmwareUpdates[peripheral.identifier] = SensorFirmwareUpdate(stage: .failed, message: message)
            firmwareSessions.removeValue(forKey: peripheral.identifier)
        default:
            break
        }
    }

    private func aliasKey(for sensor: ConnectedSensor) -> String {
        sensor.sensorIdentifier ?? "peripheral-\(sensor.id.uuidString)"
    }

    private func updateConnectedSensor(_ peripheral: CBPeripheral, with payload: SensorPayload) {
        guard !payload.observations.isEmpty,
              let index = connectedSensors.firstIndex(where: { $0.id == peripheral.identifier }) else { return }

        let previousKey = aliasKey(for: connectedSensors[index])
        let sensorIdentifier = payload.sensorID
        let stableAlias = sensorAliases[sensorIdentifier] ?? sensorAliases[previousKey]
        if let stableAlias, previousKey != sensorIdentifier {
            sensorAliases[sensorIdentifier] = stableAlias
            sensorAliases.removeValue(forKey: previousKey)
            UserDefaults.standard.set(sensorAliases, forKey: "sensorAliases")
        }

        connectedSensors[index].advertisedName = payload.sensorName ?? connectedSensors[index].advertisedName
        connectedSensors[index].sensorIdentifier = sensorIdentifier
        connectedSensors[index].customName = stableAlias
        connectedSensors[index].firmwareVersion = payload.firmwareVersion
        connectedSensors[index].hardware = payload.hardware
        connectedSensors[index].lastReceivedAt = .now
        refreshConnectedState()
    }

    private func updateState(for bluetoothState: CBManagerState) {
        switch bluetoothState {
        case .poweredOn:
            if connectedSensors.isEmpty && !isSearching {
                state = .idle
            }
        case .poweredOff:
            state = .unavailable("Activa Bluetooth para conectar el sensor ESP32.")
        case .unauthorized:
            state = .unavailable("Autoriza Bluetooth en Ajustes para conectar el sensor.")
        case .unsupported:
            state = .unavailable("Este dispositivo no admite Bluetooth Low Energy.")
        case .resetting:
            state = .unavailable("Bluetooth se está reiniciando.")
        case .unknown:
            state = .unavailable("Esperando el estado de Bluetooth.")
        @unknown default:
            state = .unavailable("Estado de Bluetooth desconocido.")
        }
    }

    private func append(_ payload: SensorPayload) {
        guard !payload.observations.isEmpty else { return }
        let incoming = payload.observations[0]
        let detectionLocation = locationProvider?().map(DetectionLocation.init)
        if payload.observations.count == 1,
           let existingIndex = receivedBatches.firstIndex(where: { batch in
               guard batch.payload.sensorID == payload.sensorID,
                     batch.payload.observations.count == 1,
                     let existing = batch.payload.observations.first else { return false }
               return existing.kind == incoming.kind && existing.identifier == incoming.identifier
           }) {
            let existingID = receivedBatches[existingIndex].id
            receivedBatches[existingIndex] = ReceivedSensorBatch(
                id: existingID,
                payload: payload,
                receivedAt: .now,
                detectionLocation: detectionLocation ?? receivedBatches[existingIndex].detectionLocation
            )
        } else {
            receivedBatches.append(
                ReceivedSensorBatch(
                    id: UUID(),
                    payload: payload,
                    receivedAt: .now,
                    detectionLocation: detectionLocation
                )
            )
        }
        if receivedBatches.count > 50 {
            receivedBatches.removeFirst(receivedBatches.count - 50)
        }
        onStateChanged?()
    }
}

extension SensorBridge: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateState(for: central.state)
        if central.state == .poweredOn, shouldConnectWhenReady {
            startDiscovery()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let identifier = peripheral.identifier
        guard connectedPeripherals[identifier] == nil,
              connectingPeripherals[identifier] == nil else { return }
        guard connectedSensors.count + connectingPeripherals.count < maximumSensorConnections else {
            stopDiscovery()
            return
        }

        scheduleDiscoveryTimeout()
        connectingPeripherals[identifier] = peripheral
        if connectedSensors.isEmpty {
            state = .connecting(peripheral.name ?? "sensor ESP32")
        }
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectingPeripherals.removeValue(forKey: peripheral.identifier)
        connectedPeripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        fail(error?.localizedDescription ?? "El sensor rechazó la conexión.", peripheral: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectingPeripherals.removeValue(forKey: peripheral.identifier)
        observationsCharacteristics.removeValue(forKey: peripheral.identifier)
        firmwareControlCharacteristics.removeValue(forKey: peripheral.identifier)
        firmwareDataCharacteristics.removeValue(forKey: peripheral.identifier)
        firmwareSessions.removeValue(forKey: peripheral.identifier)
        connectedPeripherals.removeValue(forKey: peripheral.identifier)
        connectedSensors.removeAll { $0.id == peripheral.identifier }
        refreshConnectedState()

        if shouldConnectWhenReady, central.state == .poweredOn {
            startDiscovery()
        } else if let error, connectedSensors.isEmpty {
            state = .failed(error.localizedDescription)
        }
    }
}

extension SensorBridge: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            fail(error.localizedDescription, peripheral: peripheral)
            return
        }

        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            fail("El sensor no ofrece el servicio OmniPulse esperado.", peripheral: peripheral)
            return
        }
        peripheral.discoverCharacteristics(
            [Self.observationsCharacteristicUUID, Self.firmwareControlCharacteristicUUID, Self.firmwareDataCharacteristicUUID],
            for: service
        )
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            fail(error.localizedDescription, peripheral: peripheral)
            return
        }

        guard let characteristic = service.characteristics?.first(where: { $0.uuid == Self.observationsCharacteristicUUID }) else {
            fail("El sensor no ofrece la característica de observaciones.", peripheral: peripheral)
            return
        }

        observationsCharacteristics[peripheral.identifier] = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
        if let control = service.characteristics?.first(where: { $0.uuid == Self.firmwareControlCharacteristicUUID }) {
            firmwareControlCharacteristics[peripheral.identifier] = control
            peripheral.setNotifyValue(true, for: control)
        }
        if let transfer = service.characteristics?.first(where: { $0.uuid == Self.firmwareDataCharacteristicUUID }) {
            firmwareDataCharacteristics[peripheral.identifier] = transfer
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            fail(error.localizedDescription, peripheral: peripheral)
            return
        }
        if characteristic.uuid == Self.firmwareControlCharacteristicUUID {
            return
        }
        guard characteristic.uuid == Self.observationsCharacteristicUUID, characteristic.isNotifying else {
            fail("No se pudieron activar las notificaciones del sensor.", peripheral: peripheral)
            return
        }

        if !connectedSensors.contains(where: { $0.id == peripheral.identifier }) {
            connectedSensors.append(
                ConnectedSensor(
                    id: peripheral.identifier,
                    advertisedName: peripheral.name ?? "sensor ESP32",
                    connectedAt: .now
                )
            )
        }
        refreshConnectedState()
        peripheral.readValue(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            fail(error.localizedDescription, peripheral: peripheral)
            return
        }
        guard let value = characteristic.value else {
            return
        }

        if characteristic.uuid == Self.firmwareControlCharacteristicUUID {
            handleFirmwareStatus(value, from: peripheral)
            return
        }
        guard characteristic.uuid == Self.observationsCharacteristicUUID else { return }

        do {
            let payload = try SensorPayloadDecoder.decode(value)
            updateConnectedSensor(peripheral, with: payload)
            append(payload)
        } catch {
            fail("Se recibió un lote no válido: \(error.localizedDescription)", peripheral: peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            firmwareUpdates[peripheral.identifier] = SensorFirmwareUpdate(stage: .failed, message: error.localizedDescription)
            firmwareSessions.removeValue(forKey: peripheral.identifier)
            return
        }
        if characteristic.uuid == Self.firmwareControlCharacteristicUUID,
           let session = firmwareSessions[peripheral.identifier],
           session.didSendBegin,
           !session.didSendFinish {
            pumpFirmwareData(for: peripheral)
        }
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        pumpFirmwareData(for: peripheral)
    }
}
