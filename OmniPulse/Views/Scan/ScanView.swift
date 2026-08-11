import CoreLocation
import SwiftData
import SwiftUI

struct ScanView: View {
    private let vehicleTrackingOwner = "iphone-ble-scan"

    @Environment(BluetoothScanner.self) private var scanner
    @Environment(LocationService.self) private var locationService
    @Environment(NativeWiFiService.self) private var nativeWiFiService
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext

    @AppStorage("scanDisplayMode") private var scanDisplayMode = ScanDisplayMode.discoveryOrder.rawValue
    @State private var feedback = ""
    @State private var isShowingFeedback = false

    private var selectedDisplayMode: ScanDisplayMode {
        ScanDisplayMode(rawValue: scanDisplayMode) ?? .discoveryOrder
    }

    private var selectedAccent: Color {
        appTheme.accent
    }

    private var displayedDevices: [NearbyDevice] {
        switch selectedDisplayMode {
        case .discoveryOrder:
            scanner.devices
        case .vehicle:
            scanner.devices.sorted {
                if $0.rssi == $1.rssi { return $0.firstSeen < $1.firstSeen }
                return $0.rssi > $1.rssi
            }
        }
    }

    var body: some View {
        List {
            Section {
                statusCard
                    .listRowInsets(.init(top: 12, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section("Modo de lista") {
                Picker("Orden", selection: $scanDisplayMode) {
                    ForEach(ScanDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text(selectedDisplayMode == .vehicle
                     ? "Reordena continuamente por intensidad de señal para uso en movimiento."
                     : "Conserva el orden en el que cada dispositivo fue detectado por primera vez.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if selectedDisplayMode == .vehicle {
                    Label("La ubicación se mantiene actualizada y se asigna a cada detección.", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Controles") {
                Button {
                    scanner.isScanning ? scanner.stopScanning() : scanner.startScanning()
                } label: {
                    Label(
                        scanner.isScanning ? "Detener escaneo" : "Iniciar escaneo BLE",
                        systemImage: scanner.isScanning ? "stop.fill" : "play.fill"
                    )
                }

                Button {
                    locationService.requestCurrentLocation()
                } label: {
                    if locationService.isUpdating {
                        Label("Actualizando ubicación…", systemImage: "location.fill")
                    } else {
                        Label("Actualizar ubicación", systemImage: "location.fill")
                    }
                }
                .disabled(locationService.isUpdating)
                .accessibilityIdentifier("update-location-button")

                if !scanner.devices.isEmpty {
                    Button {
                        saveAllDiscoveries()
                    } label: {
                        Label("Guardar lote actual", systemImage: "tray.and.arrow.down.fill")
                    }
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
                    LabeledContent("Precisión", value: "±\(location.horizontalAccuracy.formatted(.number.precision(.fractionLength(0)))) m")
                }

                if let error = locationService.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Wi-Fi del iPhone") {
                Label(
                    nativeWiFiService.isConnectedViaWiFi ? "Wi-Fi conectado" : "Wi-Fi no conectado",
                    systemImage: nativeWiFiService.isConnectedViaWiFi ? "wifi" : "wifi.slash"
                )
                .foregroundStyle(nativeWiFiService.isConnectedViaWiFi ? appTheme.success : appTheme.secondaryText)

                Text(nativeWiFiService.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("iOS no permite escanear redes cercanas. Con una cuenta y capacidad compatibles solo puede leerse la red actualmente conectada.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Button {
                    nativeWiFiService.refresh()
                } label: {
                    if nativeWiFiService.isLoading {
                        Label("Consultando…", systemImage: "wifi")
                    } else {
                        Label("Actualizar red Wi-Fi", systemImage: "wifi")
                    }
                }
                .disabled(nativeWiFiService.isLoading)
            }

            Section("Dispositivos cercanos (\(scanner.devices.count))") {
                if scanner.devices.isEmpty {
                    ContentUnavailableView(
                        scanner.isScanning ? "Buscando anuncios BLE" : "Aún no hay descubrimientos",
                        systemImage: scanner.isScanning ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right",
                        description: Text("Inicia un escaneo para ver dispositivos que anuncian servicios Bluetooth Low Energy.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(displayedDevices) { device in
                        NavigationLink {
                            NearbyDeviceDetailView(
                                device: device,
                                usesFreshLocationOnly: selectedDisplayMode == .vehicle
                            )
                        } label: {
                            NearbyDeviceRow(device: device)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                save(device)
                            } label: {
                                Label("Guardar", systemImage: "tray.and.arrow.down.fill")
                            }
                            .tint(selectedAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Escanear")
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
        .alert("OmniPulse", isPresented: $isShowingFeedback) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(feedback)
        }
        .onAppear {
            updateVehicleTracking(for: selectedDisplayMode)
        }
        .onChange(of: selectedDisplayMode) { _, mode in
            updateVehicleTracking(for: mode)
        }
        .onDisappear {
            scanner.stopScanning()
            locationService.setVehicleTracking(false, owner: vehicleTrackingOwner)
        }
    }

    private var statusCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: scanner.isScanning ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right")
                .font(.title2)
                .foregroundStyle(scanner.isScanning ? selectedAccent : .secondary)
                .symbolEffect(.variableColor.iterative, isActive: scanner.isScanning)

            VStack(alignment: .leading, spacing: 4) {
                Text(scanner.status.title)
                    .font(.headline)
                Text(scanner.status.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(appTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(selectedAccent.opacity(0.14), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func save(_ device: NearbyDevice) {
        modelContext.insert(DetectionRecord(
            nearbyDevice: device,
            location: location(for: device),
            projectID: SurveyProjectSelection.activeProjectID
        ))
        persist(message: "Se guardó \(device.displayName).")
    }

    private func saveAllDiscoveries() {
        for device in scanner.devices {
            modelContext.insert(DetectionRecord(
                nearbyDevice: device,
                location: location(for: device),
                projectID: SurveyProjectSelection.activeProjectID
            ))
        }
        persist(message: "Se guardaron \(scanner.devices.count) observaciones.")
    }

    private func updateVehicleTracking(for mode: ScanDisplayMode) {
        locationService.setVehicleTracking(mode == .vehicle, owner: vehicleTrackingOwner)
    }

    private func location(for device: NearbyDevice) -> CLLocation? {
        device.detectionLocation?.location
            ?? (selectedDisplayMode == .vehicle ? locationService.freshLocation() : locationService.latestLocation)
    }

    private func persist(message: String) {
        do {
            try modelContext.save()
            feedback = message
        } catch {
            feedback = "No se pudo guardar el registro: \(error.localizedDescription)"
        }
        isShowingFeedback = true
    }
}

struct NearbyDeviceRow: View {
    @Environment(AppTheme.self) private var appTheme
    let device: NearbyDevice

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.title3)
                .foregroundStyle(signalColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(device.displayName)
                    .lineLimit(1)
                Text(device.source.transportLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(device.rssi) dBm")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(signalColor)
                Text(device.lastSeen, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var signalColor: Color {
        if device.rssi >= -60 {
            return appTheme.strongSignal
        } else if device.rssi >= -80 {
            return appTheme.mediumSignal
        } else {
            return appTheme.weakSignal
        }
    }
}

struct NearbyDeviceDetailView: View {
    let device: NearbyDevice
    let usesFreshLocationOnly: Bool

    @Environment(LocationService.self) private var locationService
    @Environment(\.modelContext) private var modelContext

    @State private var feedback = ""
    @State private var isShowingFeedback = false

    var body: some View {
        Form {
            Section("Lectura") {
                LabeledContent("Nombre", value: device.displayName)
                LabeledContent("Origen", value: device.source.rawValue)
                LabeledContent("Señal", value: "\(device.rssi) dBm")
                if let category = device.deviceCategory {
                    LabeledContent("Categoría", value: category)
                }
                if let manufacturer = device.manufacturerName {
                    LabeledContent("Fabricante", value: manufacturer)
                }
                if let beaconType = device.beaconType {
                    LabeledContent("Beacon", value: beaconType)
                }
                if let interval = device.advertisementInterval {
                    LabeledContent("Intervalo de anuncio", value: "\(Int((interval * 1_000).rounded())) ms")
                }
                LabeledContent("Visto", value: device.lastSeen.formatted(date: .abbreviated, time: .standard))
            }

            Section("Identificador") {
                Text(device.identifier)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            }

            if !device.advertisedServices.isEmpty {
                Section("Servicios anunciados") {
                    ForEach(device.advertisedServices, id: \.self) { service in
                        Text(service)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }

            Section("Ubicación al guardar") {
                if let location = saveLocation {
                    Text("\(location.coordinate.latitude.formatted(.number.precision(.fractionLength(5)))), \(location.coordinate.longitude.formatted(.number.precision(.fractionLength(5))))")
                } else {
                    Text("Sin ubicación disponible. Puedes guardar el registro sin coordenadas.")
                        .foregroundStyle(.secondary)
                }

                Button("Actualizar ubicación") {
                    locationService.requestCurrentLocation()
                }
            }
        }
        .navigationTitle(device.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Guardar") {
                    save()
                }
            }
        }
        .alert("OmniPulse", isPresented: $isShowingFeedback) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(feedback)
        }
    }

    private func save() {
        modelContext.insert(
            DetectionRecord(
                nearbyDevice: device,
                location: saveLocation,
                projectID: SurveyProjectSelection.activeProjectID
            )
        )
        do {
            try modelContext.save()
            feedback = "La observación se guardó en el historial."
        } catch {
            feedback = "No se pudo guardar el registro: \(error.localizedDescription)"
        }
        isShowingFeedback = true
    }

    private var saveLocation: CLLocation? {
        device.detectionLocation?.location
            ?? (usesFreshLocationOnly ? locationService.freshLocation() : locationService.latestLocation)
    }
}
