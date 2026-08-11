import CoreBluetooth
import CoreLocation
import Foundation
import Observation

enum BluetoothScannerStatus: Equatable {
    case ready
    case scanning
    case unavailable(String)

    var title: String {
        switch self {
        case .ready:
            "Bluetooth listo"
        case .scanning:
            "Escaneando BLE"
        case .unavailable:
            "Bluetooth no disponible"
        }
    }

    var detail: String {
        switch self {
        case .ready:
            "Puedes iniciar un escaneo cercano."
        case .scanning:
            "Se actualizan los anuncios que recibe el iPhone."
        case .unavailable(let reason):
            reason
        }
    }
}

@Observable
final class BluetoothScanner: NSObject {
    private(set) var devices: [NearbyDevice] = []
    private(set) var status: BluetoothScannerStatus = .unavailable("Inicializando Bluetooth.")
    private(set) var isScanning = false

    @ObservationIgnored private var centralManager: CBCentralManager!
    @ObservationIgnored private var locationProvider: (() -> CLLocation?)?
    @ObservationIgnored private var lastAdvertisementAt: [String: Date] = [:]
    @ObservationIgnored private var smoothedIntervals: [String: TimeInterval] = [:]
    @ObservationIgnored var onStateChanged: (() -> Void)?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func useLocationProvider(_ provider: @escaping () -> CLLocation?) {
        locationProvider = provider
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            updateStatus(for: centralManager.state)
            return
        }

        devices.removeAll()
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
        status = .scanning
        onStateChanged?()
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if centralManager.state == .poweredOn {
            status = .ready
        }
        onStateChanged?()
    }

    private func updateStatus(for state: CBManagerState) {
        switch state {
        case .poweredOn:
            status = isScanning ? .scanning : .ready
        case .poweredOff:
            status = .unavailable("Activa Bluetooth para buscar anuncios BLE.")
        case .unauthorized:
            status = .unavailable("Autoriza Bluetooth en Ajustes para usar el escáner.")
        case .unsupported:
            status = .unavailable("Este dispositivo no admite Bluetooth Low Energy.")
        case .resetting:
            status = .unavailable("Bluetooth se está reiniciando.")
        case .unknown:
            status = .unavailable("Esperando el estado de Bluetooth.")
        @unknown default:
            status = .unavailable("Estado de Bluetooth desconocido.")
        }
    }
}

extension BluetoothScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            isScanning = false
        }
        updateStatus(for: central.state)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let identifier = peripheral.identifier.uuidString.lowercased()
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? ""
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
            .map(\.uuidString)
            .sorted()
        let now = Date()
        let detectionLocation = locationProvider?().map(DetectionLocation.init)
        let identity = BLEAdvertisementInterpreter.identify(name: name, advertisementData: advertisementData)
        let interval = advertisementInterval(for: identifier, at: now)

        if let index = devices.firstIndex(where: { $0.identifier == identifier }) {
            devices[index] = devices[index].refreshed(
                name: name,
                rssi: RSSI.intValue,
                advertisedServices: services,
                manufacturerIdentifier: identity.manufacturerIdentifier,
                manufacturerName: identity.manufacturerName,
                deviceCategory: identity.category,
                beaconType: identity.beaconType,
                advertisementInterval: interval,
                detectionLocation: detectionLocation,
                at: now
            )
        } else {
            devices.append(
                NearbyDevice(
                    identifier: identifier,
                    name: name,
                    rssi: RSSI.intValue,
                    lastSeen: now,
                    advertisedServices: services,
                    manufacturerIdentifier: identity.manufacturerIdentifier,
                    manufacturerName: identity.manufacturerName,
                    deviceCategory: identity.category,
                    beaconType: identity.beaconType,
                    advertisementInterval: interval,
                    detectionLocation: detectionLocation
                )
            )
        }
        onStateChanged?()
    }

    private func advertisementInterval(for identifier: String, at date: Date) -> TimeInterval? {
        defer { lastAdvertisementAt[identifier] = date }
        guard let previous = lastAdvertisementAt[identifier] else { return nil }
        let sample = date.timeIntervalSince(previous)
        guard sample > 0, sample < 30 else { return smoothedIntervals[identifier] }
        let smoothed = smoothedIntervals[identifier].map { ($0 * 0.7) + (sample * 0.3) } ?? sample
        smoothedIntervals[identifier] = smoothed
        return smoothed
    }
}
