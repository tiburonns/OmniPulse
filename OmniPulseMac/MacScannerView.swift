import CoreLocation
import SwiftData
import SwiftUI

struct MacScannerView: View {
    @Environment(BluetoothScanner.self) private var scanner
    @Environment(SensorBridge.self) private var sensorBridge
    @Environment(LocationService.self) private var locationService
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext

    @AppStorage("macScanDisplayMode") private var displayMode = ScanDisplayMode.discoveryOrder.rawValue
    @State private var feedback = ""

    private var selectedMode: ScanDisplayMode {
        ScanDisplayMode(rawValue: displayMode) ?? .discoveryOrder
    }

    private var devices: [NearbyDevice] {
        selectedMode == .vehicle
            ? scanner.devices.sorted { $0.rssi == $1.rssi ? $0.firstSeen < $1.firstSeen : $0.rssi > $1.rssi }
            : scanner.devices
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            HSplitView {
                deviceList
                    .frame(minWidth: 420)
                sensorBatches
                    .frame(minWidth: 360)
            }
        }
        .navigationTitle("Escanear")
        .onAppear { updateVehicleTracking() }
        .onChange(of: displayMode) { _, _ in updateVehicleTracking() }
        .onDisappear {
            scanner.stopScanning()
            locationService.setVehicleTracking(false, owner: "mac-scanner")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Escaneo local y sensores ESP32")
                        .font(.title2.bold())
                    Text("La Mac puede detectar BLE directamente y recibir lotes Wi‑Fi/BLE desde hasta ocho sensores OmniPulse.")
                        .foregroundStyle(appTheme.secondaryText)
                }
                Spacer()
                Picker("Modo", selection: $displayMode) {
                    ForEach(ScanDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }

            HStack(spacing: 12) {
                Button(scanner.isScanning ? "Detener BLE" : "Iniciar BLE", systemImage: scanner.isScanning ? "stop.fill" : "play.fill") {
                    scanner.isScanning ? scanner.stopScanning() : scanner.startScanning()
                }
                .buttonStyle(.borderedProminent)

                Button(sensorBridge.isSearching ? "Detener búsqueda ESP32" : "Buscar ESP32", systemImage: "sensor.tag.radiowaves.forward") {
                    sensorBridge.isSearching ? sensorBridge.stopSearching() : sensorBridge.findAndConnect()
                }

                Button("Actualizar ubicación", systemImage: "location.fill") {
                    locationService.requestCurrentLocation()
                }

                Spacer()

                Label(locationService.statusDescription, systemImage: "location")
                    .foregroundStyle(appTheme.secondaryText)
            }

            if !feedback.isEmpty {
                Text(feedback)
                    .font(.footnote)
                    .foregroundStyle(appTheme.success)
            }
        }
        .padding(20)
        .background(appTheme.surface)
    }

    private var deviceList: some View {
        List {
            Section("BLE detectado por la Mac (\(scanner.devices.count))") {
                if devices.isEmpty {
                    ContentUnavailableView("Sin detecciones BLE", systemImage: "antenna.radiowaves.left.and.right")
                } else {
                    ForEach(devices) { device in
                        HStack {
                            SignalIcon(rssi: device.rssi)
                            VStack(alignment: .leading) {
                                Text(device.displayName)
                                Text(device.identifier)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(appTheme.secondaryText)
                            }
                            Spacer()
                            Text("\(device.rssi) dBm")
                                .monospacedDigit()
                            Button("Guardar") { save(device) }
                                .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }

    private var sensorBatches: some View {
        List {
            Section("Sensores conectados") {
                if sensorBridge.connectedSensors.isEmpty {
                    Text(sensorBridge.state.detail)
                        .foregroundStyle(appTheme.secondaryText)
                } else {
                    ForEach(sensorBridge.connectedSensors) { sensor in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(sensor.displayName, systemImage: "sensor.tag.radiowaves.forward.fill")
                                    .foregroundStyle(appTheme.success)
                                Spacer()
                                if let package = sensorBridge.firmwarePackage(for: sensor) {
                                    Button(
                                        FirmwareCatalog.isUpdateAvailable(installedVersion: sensor.firmwareVersion, package: package)
                                            ? "Actualizar a \(package.version)"
                                            : "Reinstalar \(package.version)"
                                    ) {
                                        sensorBridge.startFirmwareUpdate(for: sensor)
                                    }
                                    .disabled(isUpdating(sensor.id))
                                }
                            }
                            if let update = sensorBridge.firmwareUpdates[sensor.id], update.stage != .idle {
                                ProgressView(value: update.progress) {
                                    Text(update.message).font(.caption)
                                }
                            }
                        }
                    }
                }
            }

            Section("Lotes ESP32 pendientes (\(sensorBridge.receivedBatches.count))") {
                ForEach(sensorBridge.receivedBatches) { batch in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(batch.payload.sensorName ?? batch.payload.sensorID)
                                .font(.headline)
                            Spacer()
                            Text(batch.receivedAt, style: .relative)
                                .foregroundStyle(appTheme.secondaryText)
                        }
                        ForEach(batch.payload.observations.prefix(4)) { observation in
                            HStack {
                                Image(systemName: observation.kind == .wifiNetwork ? "wifi" : "dot.radiowaves.left.and.right")
                                Text(observation.name ?? observation.identifier)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(observation.rssi) dBm")
                                    .monospacedDigit()
                            }
                        }
                        HStack {
                            Button("Importar") { importBatch(batch) }
                            Button("Descartar", role: .destructive) { sensorBridge.discard(batch) }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }

    private func save(_ device: NearbyDevice) {
        let location = device.detectionLocation?.location
            ?? (selectedMode == .vehicle ? locationService.freshLocation() : locationService.latestLocation)
        modelContext.insert(DetectionRecord(
            nearbyDevice: device,
            location: location,
            projectID: SurveyProjectSelection.activeProjectID
        ))
        try? modelContext.save()
        feedback = "Se guardó \(device.displayName)."
    }

    private func importBatch(_ batch: ReceivedSensorBatch) {
        do {
            let location = batch.detectionLocation?.location
                ?? (selectedMode == .vehicle ? locationService.freshLocation() : locationService.latestLocation)
            let count = try SensorPayloadImporter().importBatch(batch, location: location, into: modelContext)
            sensorBridge.discard(batch)
            feedback = "Se importaron \(count) observaciones."
        } catch {
            feedback = error.localizedDescription
        }
    }

    private func updateVehicleTracking() {
        locationService.setVehicleTracking(selectedMode == .vehicle, owner: "mac-scanner")
    }

    private func isUpdating(_ sensorID: UUID) -> Bool {
        guard let stage = sensorBridge.firmwareUpdates[sensorID]?.stage else { return false }
        return [.preparing, .transferring, .verifying].contains(stage)
    }
}

private struct SignalIcon: View {
    @Environment(AppTheme.self) private var appTheme
    let rssi: Int

    var body: some View {
        Image(systemName: "dot.radiowaves.left.and.right")
            .foregroundStyle(rssi >= -60 ? appTheme.strongSignal : (rssi >= -80 ? appTheme.mediumSignal : appTheme.weakSignal))
    }
}
