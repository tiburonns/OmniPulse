import AppIntents
import SwiftData
import SwiftUI

@main
@MainActor
struct OmniPulseApp: App {
    @State private var bluetoothScanner: BluetoothScanner
    @State private var locationService: LocationService
    @State private var nativeWiFiService = NativeWiFiService()
    @State private var sensorBridge: SensorBridge
    @State private var appTheme = AppTheme()
    @State private var watchConnectivity = PhoneWatchConnectivity()
    @State private var appNavigation: AppNavigation
    private let sharedModelContainer: ModelContainer

    init() {
        let locationService = LocationService()
        let bluetoothScanner = BluetoothScanner()
        let sensorBridge = SensorBridge()
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: DetectionRecord.self, SurveyProject.self)
        } catch {
            fatalError("No se pudo abrir la base de OmniPulse: \(error.localizedDescription)")
        }
        bluetoothScanner.useLocationProvider { [weak locationService] in
            locationService?.freshLocation()
        }
        sensorBridge.useLocationProvider { [weak locationService] in
            locationService?.freshLocation()
        }

        _bluetoothScanner = State(initialValue: bluetoothScanner)
        _locationService = State(initialValue: locationService)
        _sensorBridge = State(initialValue: sensorBridge)
        sharedModelContainer = modelContainer

        let navigation = AppNavigation()
        _appNavigation = State(initialValue: navigation)

        let watchConnectivity = PhoneWatchConnectivity()
        let makeSnapshot = {
            Self.makeWatchSnapshot(scanner: bluetoothScanner, sensorBridge: sensorBridge)
        }
        watchConnectivity.configure(snapshotProvider: makeSnapshot) { command in
            Self.handleWatchCommand(
                command,
                scanner: bluetoothScanner,
                sensorBridge: sensorBridge,
                locationService: locationService,
                modelContext: modelContainer.mainContext
            )
        }
        bluetoothScanner.onStateChanged = { [weak watchConnectivity] in watchConnectivity?.sendCurrentSnapshot() }
        sensorBridge.onStateChanged = { [weak watchConnectivity] in watchConnectivity?.sendCurrentSnapshot() }
        _watchConnectivity = State(initialValue: watchConnectivity)
        if #available(iOS 18.0, *) {
            AppDependencyManager.shared.add(dependency: navigation)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(bluetoothScanner)
                .environment(locationService)
                .environment(nativeWiFiService)
                .environment(sensorBridge)
                .environment(appTheme)
                .environment(watchConnectivity)
                .environment(appNavigation)
        }
        .modelContainer(sharedModelContainer)
    }

    private static func makeWatchSnapshot(
        scanner: BluetoothScanner,
        sensorBridge: SensorBridge
    ) -> WatchAppSnapshot {
        let native = scanner.devices.map { device in
            WatchDetectionSummary(
                id: "iphone-\(device.identifier)",
                name: device.displayName,
                transport: "BLE iPhone",
                rssi: device.rssi,
                seenAt: device.lastSeen,
                latitude: device.detectionLocation?.latitude,
                longitude: device.detectionLocation?.longitude
            )
        }
        let sensor = sensorBridge.receivedBatches.flatMap { batch in
            batch.payload.observations.map { observation in
                WatchDetectionSummary(
                    id: "\(batch.payload.sensorID)-\(observation.kind.rawValue)-\(observation.identifier)",
                    name: observation.name ?? (observation.kind == .wifiNetwork ? "Red oculta" : "Dispositivo BLE"),
                    transport: observation.kind == .wifiNetwork ? "Wi‑Fi ESP32" : "BLE ESP32",
                    rssi: observation.rssi,
                    seenAt: observation.seenAt ?? batch.receivedAt,
                    latitude: batch.detectionLocation?.latitude,
                    longitude: batch.detectionLocation?.longitude
                )
            }
        }
        let detections = (native + sensor)
            .sorted { $0.seenAt > $1.seenAt }
            .prefix(30)
        return WatchAppSnapshot(
            isScanning: scanner.isScanning,
            isVehicleMode: UserDefaults.standard.string(forKey: "scanDisplayMode") == ScanDisplayMode.vehicle.rawValue,
            connectionStatus: sensorBridge.state.title,
            connectedSensorCount: sensorBridge.connectedSensors.count,
            detections: Array(detections),
            updatedAt: .now
        )
    }

    private static func handleWatchCommand(
        _ command: WatchCommand,
        scanner: BluetoothScanner,
        sensorBridge: SensorBridge,
        locationService: LocationService,
        modelContext: ModelContext
    ) {
        switch command {
        case .requestSnapshot:
            break
        case .startScanning:
            scanner.startScanning()
            sensorBridge.connectAutomatically()
        case .stopScanning:
            scanner.stopScanning()
            sensorBridge.stopSearching()
        case .enableVehicleMode:
            UserDefaults.standard.set(ScanDisplayMode.vehicle.rawValue, forKey: "scanDisplayMode")
            locationService.setVehicleTracking(true, owner: "apple-watch")
        case .disableVehicleMode:
            UserDefaults.standard.set(ScanDisplayMode.discoveryOrder.rawValue, forKey: "scanDisplayMode")
            locationService.setVehicleTracking(false, owner: "apple-watch")
        case .saveCurrentBatch:
            for device in scanner.devices {
                modelContext.insert(
                    DetectionRecord(
                        nearbyDevice: device,
                        location: device.detectionLocation?.location ?? locationService.freshLocation(),
                        projectID: SurveyProjectSelection.activeProjectID
                    )
                )
            }
            for batch in sensorBridge.receivedBatches {
                _ = try? SensorPayloadImporter().importBatch(
                    batch,
                    location: batch.detectionLocation?.location ?? locationService.freshLocation(),
                    into: modelContext
                )
                sensorBridge.discard(batch)
            }
            try? modelContext.save()
        }
    }
}
