import SwiftUI

struct WatchRootView: View {
    @Environment(WatchConnectivityClient.self) private var connectivity

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(
                            connectivity.snapshot.isScanning ? "Escaneando" : "Escaneo detenido",
                            systemImage: connectivity.snapshot.isScanning ? "dot.radiowaves.left.and.right" : "pause.circle"
                        )
                        .font(.headline)
                        .foregroundStyle(connectivity.snapshot.isScanning ? .cyan : .secondary)
                        Text(connectivity.snapshot.connectionStatus)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(connectivity.snapshot.connectedSensorCount) ESP32 conectados")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Controles") {
                    Button {
                        connectivity.send(connectivity.snapshot.isScanning ? .stopScanning : .startScanning)
                    } label: {
                        Label(
                            connectivity.snapshot.isScanning ? "Detener" : "Iniciar",
                            systemImage: connectivity.snapshot.isScanning ? "stop.fill" : "play.fill"
                        )
                    }
                    Toggle(
                        "Vehículo",
                        isOn: Binding(
                            get: { connectivity.snapshot.isVehicleMode },
                            set: { connectivity.send($0 ? .enableVehicleMode : .disableVehicleMode) }
                        )
                    )
                    Button("Guardar lote", systemImage: "tray.and.arrow.down.fill") {
                        connectivity.send(.saveCurrentBatch)
                    }
                    .disabled(connectivity.snapshot.detections.isEmpty)
                }

                Section("Recientes (\(connectivity.snapshot.detections.count))") {
                    if connectivity.snapshot.detections.isEmpty {
                        Text("Las detecciones del iPhone aparecerán aquí.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(connectivity.snapshot.detections.prefix(12)) { detection in
                            NavigationLink {
                                WatchDetectionDetail(detection: detection)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(detection.name)
                                        .lineLimit(1)
                                    HStack {
                                        Text(detection.transport)
                                        Spacer()
                                        Text("\(detection.rssi) dBm")
                                            .monospacedDigit()
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(signalColor(detection.rssi))
                                }
                            }
                        }
                    }
                }

                Text(connectivity.status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("OmniPulse")
            .toolbar {
                Button("Actualizar", systemImage: "arrow.clockwise") { connectivity.refresh() }
            }
        }
    }

    private func signalColor(_ rssi: Int) -> Color {
        if rssi >= -60 { return .green }
        if rssi >= -80 { return .orange }
        return .secondary
    }
}

private struct WatchDetectionDetail: View {
    let detection: WatchDetectionSummary

    var body: some View {
        List {
            LabeledContent("Origen", value: detection.transport)
            LabeledContent("Señal", value: "\(detection.rssi) dBm")
            LabeledContent("Visto", value: detection.seenAt.formatted(date: .omitted, time: .standard))
            if let latitude = detection.latitude, let longitude = detection.longitude {
                Section("Ubicación") {
                    Text("\(latitude.formatted(.number.precision(.fractionLength(5)))), \(longitude.formatted(.number.precision(.fractionLength(5))))")
                        .font(.caption.monospaced())
                }
            }
        }
        .navigationTitle(detection.name)
    }
}
