import CoreLocation
import SwiftData
import SwiftUI
import UIKit

struct SensorImportView: View {
    @Environment(SensorBridge.self) private var sensorBridge
    @Environment(LocationService.self) private var locationService
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    let observationFilter: SensorObservationKind?

    @State private var importFeedback = ""
    @State private var isShowingImportFeedback = false
    @State private var esp8266Client = ESP8266SensorClient()
    @AppStorage("wifiScanDisplayMode") private var wifiScanDisplayMode = ScanDisplayMode.discoveryOrder.rawValue
    @AppStorage("esp32BLEScanDisplayMode") private var esp32BLEScanDisplayMode = ScanDisplayMode.discoveryOrder.rawValue

    init(observationFilter: SensorObservationKind? = nil) {
        self.observationFilter = observationFilter
    }

    private var visibleBatches: [ReceivedSensorBatch] {
        guard let observationFilter else { return sensorBridge.receivedBatches }
        return sensorBridge.receivedBatches.filter { batch in
            batch.payload.observations.contains { $0.kind == observationFilter }
        }
    }

    private var selectedDisplayMode: ScanDisplayMode {
        let rawValue = observationFilter == .bluetoothLE ? esp32BLEScanDisplayMode : wifiScanDisplayMode
        return ScanDisplayMode(rawValue: rawValue) ?? .discoveryOrder
    }

    private var displayModeSelection: Binding<String> {
        Binding(
            get: {
                observationFilter == .bluetoothLE ? esp32BLEScanDisplayMode : wifiScanDisplayMode
            },
            set: { value in
                if observationFilter == .bluetoothLE {
                    esp32BLEScanDisplayMode = value
                } else {
                    wifiScanDisplayMode = value
                }
            }
        )
    }

    private var vehicleTrackingOwner: String {
        observationFilter == .bluetoothLE ? "esp32-ble-scan" : "esp32-wifi-scan"
    }

    private var displayedBatches: [ReceivedSensorBatch] {
        switch selectedDisplayMode {
        case .discoveryOrder:
            return visibleBatches
        case .vehicle:
            return visibleBatches.sorted {
                let leftRSSI = filteredObservation(in: $0)?.rssi ?? Int.min
                let rightRSSI = filteredObservation(in: $1)?.rssi ?? Int.min
                if leftRSSI == rightRSSI { return $0.receivedAt < $1.receivedAt }
                return leftRSSI > rightRSSI
            }
        }
    }

    private var navigationTitle: String {
        switch observationFilter {
        case .wifiNetwork: "Wi-Fi con sensores"
        case .bluetoothLE: "BLE con ESP32"
        case nil: "Sensor ESP32"
        }
    }

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: sensorBridge.state.isConnected ? "sensor.tag.radiowaves.forward.fill" : "sensor.tag.radiowaves.forward")
                        .font(.title2)
                        .foregroundStyle(sensorBridge.state.isConnected ? appTheme.success : appTheme.secondaryText)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(sensorBridge.state.title)
                            .font(.headline)
                        Text(sensorBridge.state.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if sensorBridge.isSearching, !sensorBridge.connectedSensors.isEmpty {
                            Text("Buscando sensores adicionales…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }

            Section("Controles") {
                Button {
                    sensorBridge.isSearching ? sensorBridge.stopSearching() : sensorBridge.findAndConnect()
                } label: {
                    Label(
                        sensorBridge.isSearching
                            ? "Detener búsqueda"
                            : (sensorBridge.connectedSensors.isEmpty ? "Buscar sensores ESP32" : "Buscar más sensores"),
                        systemImage: sensorBridge.isSearching ? "stop.fill" : "dot.radiowaves.left.and.right"
                    )
                }

                if observationFilter == .wifiNetwork {
                    Button {
                        fetchESP8266Batch()
                    } label: {
                        Label(
                            esp8266Client.isLoading ? "Leyendo ESP8266…" : "Leer ESP8266 / D1 mini",
                            systemImage: "wifi.router"
                        )
                    }
                    .disabled(esp8266Client.isLoading)
                }

                if !sensorBridge.connectedSensors.isEmpty {
                    Button(role: .destructive) {
                        sensorBridge.disconnect()
                    } label: {
                        Label("Desconectar todos", systemImage: "xmark.circle")
                    }
                }

                Button {
                    locationService.requestCurrentLocation()
                } label: {
                    if locationService.isUpdating {
                        Label("Actualizando ubicación…", systemImage: "location.fill")
                    } else {
                        Label("Actualizar ubicación para importar", systemImage: "location.fill")
                    }
                }
                .disabled(locationService.isUpdating)
                .accessibilityIdentifier("update-location-button")

                if observationFilter != nil, !visibleBatches.isEmpty {
                    Button {
                        importAllVisibleBatches()
                    } label: {
                        Label("Guardar todos los lotes", systemImage: "tray.full.fill")
                    }
                }
            }

            if !sensorBridge.connectedSensors.isEmpty {
                Section("Sensores conectados (\(sensorBridge.connectedSensors.count))") {
                    ForEach(sensorBridge.connectedSensors) { sensor in
                        NavigationLink {
                            ConnectedSensorDetailView(sensorID: sensor.id)
                        } label: {
                            ConnectedSensorRow(sensor: sensor)
                        }
                    }
                }
            }

            if observationFilter == .wifiNetwork {
                Section("ESP8266 · D1 mini") {
                    Text(esp8266Client.status)
                    LabeledContent("Red del sensor", value: "OmniPulse-8266-XXXX")
                    LabeledContent("Contraseña", value: "omniXXXX · usa el sufijo de la red")
                    Text("Estas placas escanean únicamente Wi-Fi de 2.4 GHz. No tienen BLE; el iPhone debe estar conectado temporalmente a la red de la placa.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Ubicación") {
                LabeledContent("Estado") {
                    Text(locationService.statusDescription)
                        .accessibilityIdentifier("location-status")
                }

                if let location = locationService.latestLocation {
                    LabeledContent("Coordenadas") {
                        Text("\(location.coordinate.latitude.formatted(.number.precision(.fractionLength(5)))), \(location.coordinate.longitude.formatted(.number.precision(.fractionLength(5))))")
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("location-coordinates")
                    }
                    LabeledContent("Actualizada", value: location.timestamp.formatted(date: .omitted, time: .standard))
                }

                if let error = locationService.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if locationService.needsSettings {
                    Button("Abrir Ajustes de OmniPulse") {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }
            }

            if observationFilter != nil {
                Section("Modo de lista") {
                    Picker("Orden", selection: displayModeSelection) {
                        ForEach(ScanDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(displayModeDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if selectedDisplayMode == .vehicle {
                        Label("La ubicación se mantiene actualizada y se asigna a cada detección.", systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if observationFilter == .wifiNetwork {
                        Text("El ESP32 transmite el nombre SSID; BSSID y direcciones MAC permanecen seudonimizados.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if observationFilter != nil, sensorBridge.connectedSensors.isEmpty, !sensorBridge.isSearching {
                Section("Si el sensor no aparece") {
                    Label("Pulsa una vez RESET en el ESP32, espera unos segundos y vuelve a tocar Buscar sensor ESP32.", systemImage: "arrow.clockwise.circle")
                    Text("En XIAO ESP32S3/Sense, asegúrate también de que la antena externa esté conectada. No mantengas BOOT presionado durante el arranque normal.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Lotes pendientes (\(visibleBatches.count))") {
                if visibleBatches.isEmpty {
                    ContentUnavailableView(
                        "Sin lotes pendientes",
                        systemImage: "tray",
                        description: Text("Los lotes recibidos se muestran aquí antes de guardarse en el historial.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(displayedBatches) { batch in
                        NavigationLink {
                            SensorBatchDetailView(
                                batch: batch,
                                usesFreshLocationOnly: selectedDisplayMode == .vehicle
                            )
                        } label: {
                            SensorBatchRow(batch: batch)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                sensorBridge.discard(batch)
                            } label: {
                                Label("Descartar", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if observationFilter != nil {
                Section("Compatibilidad y preparación") {
                    NavigationLink("Dispositivos compatibles") {
                        CompatibleSensorsView()
                    }
                    NavigationLink("Guías para flashear") {
                        GuidesView()
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
        .alert("OmniPulse", isPresented: $isShowingImportFeedback) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(importFeedback)
        }
        .task {
            if observationFilter != nil {
                sensorBridge.connectAutomatically()
                updateVehicleTracking(for: selectedDisplayMode)
            }
        }
        .onChange(of: selectedDisplayMode) { _, mode in
            updateVehicleTracking(for: mode)
        }
        .onDisappear {
            locationService.setVehicleTracking(false, owner: vehicleTrackingOwner)
        }
    }

    private var displayModeDescription: String {
        if selectedDisplayMode == .vehicle {
            return observationFilter == .wifiNetwork
                ? "Reordena continuamente las redes por intensidad de señal para uso en movimiento."
                : "Reordena continuamente los dispositivos BLE por intensidad de señal para uso en movimiento."
        }
        return observationFilter == .wifiNetwork
            ? "Conserva el orden en el que cada red fue detectada."
            : "Conserva el orden en el que cada dispositivo BLE fue detectado."
    }

    private func filteredObservation(in batch: ReceivedSensorBatch) -> SensorObservation? {
        guard let observationFilter else { return batch.payload.observations.first }
        return batch.payload.observations.first { $0.kind == observationFilter }
    }

    private func updateVehicleTracking(for mode: ScanDisplayMode) {
        guard observationFilter != nil else { return }
        locationService.setVehicleTracking(mode == .vehicle, owner: vehicleTrackingOwner)
    }

    private func importAllVisibleBatches() {
        var importedObservations = 0
        var importedBatches: [ReceivedSensorBatch] = []

        do {
            for batch in visibleBatches {
                importedObservations += try SensorPayloadImporter().importBatch(
                    batch,
                    location: importLocation(for: batch),
                    into: modelContext
                )
                importedBatches.append(batch)
            }
            for batch in importedBatches {
                sensorBridge.discard(batch)
            }
            importFeedback = "Se guardaron \(importedObservations) observaciones de \(importedBatches.count) lotes."
        } catch {
            for batch in importedBatches {
                sensorBridge.discard(batch)
            }
            importFeedback = "Se guardaron \(importedBatches.count) lotes antes del error: \(error.localizedDescription)"
        }
        isShowingImportFeedback = true
    }

    private func fetchESP8266Batch() {
        Task {
            do {
                let payload = try await esp8266Client.fetchPayload()
                sensorBridge.ingestLocalNetworkPayload(payload)
            } catch {
                esp8266Client.report(error)
            }
        }
    }

    private func importLocation(for batch: ReceivedSensorBatch) -> CLLocation? {
        batch.detectionLocation?.location
            ?? (selectedDisplayMode == .vehicle ? locationService.freshLocation() : locationService.latestLocation)
    }
}

private struct ConnectedSensorRow: View {
    @Environment(AppTheme.self) private var appTheme
    let sensor: ConnectedSensor

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sensor.tag.radiowaves.forward.fill")
                .foregroundStyle(appTheme.success)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(sensor.displayName)
                Text(sensorSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let lastReceivedAt = sensor.lastReceivedAt {
                Text(lastReceivedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Esperando datos")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sensorSummary: String {
        let summary = [sensor.hardware, sensor.firmwareVersion.map { "Firmware \($0)" }]
            .compactMap { $0 }
            .joined(separator: " · ")
        return summary.isEmpty ? "Conectado" : summary
    }
}

private struct ConnectedSensorDetailView: View {
    @Environment(SensorBridge.self) private var sensorBridge

    let sensorID: UUID
    @State private var proposedName = ""

    private var sensor: ConnectedSensor? {
        sensorBridge.connectedSensors.first { $0.id == sensorID }
    }

    var body: some View {
        Group {
            if let sensor {
                Form {
                    Section("Estado") {
                        LabeledContent("Conexión", value: "Conectado")
                        LabeledContent("Conectado desde", value: sensor.connectedAt.formatted(date: .omitted, time: .standard))
                        if let lastReceivedAt = sensor.lastReceivedAt {
                            LabeledContent("Última recepción", value: lastReceivedAt.formatted(date: .omitted, time: .standard))
                        } else {
                            LabeledContent("Última recepción", value: "Esperando datos")
                        }
                    }

                    Section("Sensor") {
                        LabeledContent("Nombre anunciado", value: sensor.advertisedName)
                        if let identifier = sensor.sensorIdentifier {
                            LabeledContent("Identificador", value: identifier)
                        }
                        if let hardware = sensor.hardware {
                            LabeledContent("Hardware", value: hardware)
                        }
                        if let firmwareVersion = sensor.firmwareVersion {
                            LabeledContent("Firmware", value: firmwareVersion)
                        }
                    }

                    if let package = sensorBridge.firmwarePackage(for: sensor) {
                        Section("Firmware inalámbrico") {
                            LabeledContent("Disponible", value: package.version)
                            LabeledContent("Bandas", value: package.supportedBands)

                            if let update = sensorBridge.firmwareUpdates[sensor.id], update.stage != .idle {
                                VStack(alignment: .leading, spacing: 8) {
                                    ProgressView(value: update.progress)
                                    Text(update.message)
                                        .font(.footnote)
                                        .foregroundStyle(update.stage == .failed ? .red : .secondary)
                                }
                            }

                            Button {
                                sensorBridge.startFirmwareUpdate(for: sensor)
                            } label: {
                                Label(
                                    FirmwareCatalog.isUpdateAvailable(installedVersion: sensor.firmwareVersion, package: package)
                                        ? "Actualizar por Bluetooth"
                                        : "Reinstalar firmware",
                                    systemImage: "arrow.triangle.2.circlepath"
                                )
                            }
                            .disabled(isFirmwareUpdating(sensor.id))

                            Text("Mantén el sensor conectado a una fuente estable y no cierres OmniPulse durante la transferencia.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Nombre personalizado") {
                        TextField("Ej. Sensor del vehículo", text: $proposedName)
                            .textInputAutocapitalization(.sentences)
                        Button("Guardar nombre") {
                            sensorBridge.rename(sensor, to: proposedName)
                        }
                        if sensor.customName != nil {
                            Button("Restaurar nombre anunciado", role: .destructive) {
                                proposedName = ""
                                sensorBridge.rename(sensor, to: "")
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "Sensor desconectado",
                    systemImage: "sensor.tag.radiowaves.forward",
                    description: Text("Vuelve a la pantalla anterior para buscarlo nuevamente.")
                )
            }
        }
        .navigationTitle(sensor?.displayName ?? "Sensor ESP32")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            proposedName = sensor?.customName ?? ""
        }
    }

    private func isFirmwareUpdating(_ sensorID: UUID) -> Bool {
        guard let stage = sensorBridge.firmwareUpdates[sensorID]?.stage else { return false }
        return [.preparing, .transferring, .verifying].contains(stage)
    }
}

struct SensorBatchRow: View {
    @Environment(AppTheme.self) private var appTheme
    let batch: ReceivedSensorBatch

    private var observation: SensorObservation? {
        batch.payload.observations.first
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: observation?.kind == .wifiNetwork ? "wifi" : "dot.radiowaves.left.and.right")
                .foregroundStyle(signalColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(observation?.name ?? fallbackName)
                    .lineLimit(1)
                Text(observation?.identifier ?? batch.payload.sensorID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if let rssi = observation?.rssi {
                    Text("\(rssi) dBm")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(signalColor)
                }
                Text(batch.receivedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fallbackName: String {
        observation?.kind == .wifiNetwork ? "Red oculta" : "Dispositivo BLE"
    }

    private var signalColor: Color {
        guard let rssi = observation?.rssi else { return .secondary }
        if rssi >= -60 { return appTheme.strongSignal }
        if rssi >= -80 { return appTheme.mediumSignal }
        return appTheme.weakSignal
    }
}

struct SensorBatchDetailView: View {
    let batch: ReceivedSensorBatch
    let usesFreshLocationOnly: Bool

    @Environment(SensorBridge.self) private var sensorBridge
    @Environment(LocationService.self) private var locationService
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext

    @State private var feedback = ""
    @State private var isShowingFeedback = false

    var body: some View {
        List {
            Section("Lote") {
                LabeledContent("Sensor", value: batch.payload.sensorID)
                LabeledContent("Recibido", value: batch.receivedAt.formatted(date: .abbreviated, time: .standard))
                LabeledContent("Observaciones", value: "\(batch.observationCount)")
            }

            Section("Ubicación al importar") {
                if let location = importLocation {
                    Text("\(location.coordinate.latitude.formatted(.number.precision(.fractionLength(5)))), \(location.coordinate.longitude.formatted(.number.precision(.fractionLength(5))))")
                } else {
                    Text("Sin ubicación disponible. Puedes importar el lote sin coordenadas.")
                        .foregroundStyle(.secondary)
                }

                Button("Actualizar ubicación") {
                    locationService.requestCurrentLocation()
                }
                .disabled(locationService.isUpdating)
            }

            Section("Observaciones") {
                ForEach(batch.payload.observations) { observation in
                    HStack(spacing: 12) {
                        Image(systemName: observation.kind == .wifiNetwork ? "wifi" : "dot.radiowaves.left.and.right")
                            .foregroundStyle(observation.kind == .wifiNetwork ? appTheme.warning : appTheme.success)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(observation.name ?? label(for: observation.kind))
                            Text(observation.identifier)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            if let channel = observation.channel {
                                Text("Canal Wi-Fi: \(channel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(observation.rssi) dBm")
                            .font(.subheadline.monospacedDigit())
                    }
                }
            }
        }
        .navigationTitle("Importar lote")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Importar") {
                    importBatch()
                }
            }
        }
        .alert("OmniPulse", isPresented: $isShowingFeedback) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(feedback)
        }
    }

    private func label(for kind: SensorObservationKind) -> String {
        kind == .wifiNetwork ? "Red oculta" : "Dispositivo BLE"
    }

    private func importBatch() {
        do {
            let count = try SensorPayloadImporter().importBatch(
                batch,
                location: importLocation,
                into: modelContext
            )
            sensorBridge.discard(batch)
            feedback = "Se guardaron \(count) observaciones en el historial."
        } catch {
            feedback = "No se pudo importar el lote: \(error.localizedDescription)"
        }
        isShowingFeedback = true
    }

    private var importLocation: CLLocation? {
        batch.detectionLocation?.location
            ?? (usesFreshLocationOnly ? locationService.freshLocation() : locationService.latestLocation)
    }
}
