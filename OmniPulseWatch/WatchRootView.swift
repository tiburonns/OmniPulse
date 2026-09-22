import SwiftUI

struct WatchRootView: View {
    @Environment(WatchConnectivityClient.self) private var connectivity

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(
                            connectivity.snapshot.isScanning
                                ? watchLocalized("Escaneando")
                                : watchLocalized("Escaneo detenido"),
                            systemImage: connectivity.snapshot.isScanning
                                ? "dot.radiowaves.left.and.right"
                                : "pause.circle"
                        )
                        .font(.headline)
                        .foregroundStyle(
                            connectivity.snapshot.isScanning
                                ? .cyan
                                : .secondary
                        )

                        Text(connectionStatusText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(
                            watchLocalizedFormat(
                                "%lld ESP32 conectados",
                                Int64(connectivity.snapshot.connectedSensorCount)
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }

                Section(watchLocalized("Controles")) {
                    Button {
                        connectivity.send(
                            connectivity.snapshot.isScanning
                                ? .stopScanning
                                : .startScanning
                        )
                    } label: {
                        Label(
                            connectivity.snapshot.isScanning
                                ? watchLocalized("Detener")
                                : watchLocalized("Iniciar"),
                            systemImage: connectivity.snapshot.isScanning
                                ? "stop.fill"
                                : "play.fill"
                        )
                    }

                    Toggle(
                        watchLocalized("Vehículo"),
                        isOn: Binding(
                            get: { connectivity.snapshot.isVehicleMode },
                            set: {
                                connectivity.send(
                                    $0
                                        ? .enableVehicleMode
                                        : .disableVehicleMode
                                )
                            }
                        )
                    )

                    Button(
                        watchLocalized("Guardar lote"),
                        systemImage: "tray.and.arrow.down.fill"
                    ) {
                        connectivity.send(.saveCurrentBatch)
                    }
                    .disabled(connectivity.snapshot.detections.isEmpty)
                }

                Section(
                    watchLocalizedFormat(
                        "Recientes (%lld)",
                        Int64(connectivity.snapshot.detections.count)
                    )
                ) {
                    if connectivity.snapshot.detections.isEmpty {
                        Text(
                            watchLocalized(
                                "Las detecciones del iPhone aparecerán aquí."
                            )
                        )
                        .foregroundStyle(.secondary)
                    } else {
                        ForEach(
                            connectivity.snapshot.detections.prefix(12)
                        ) { detection in
                            NavigationLink {
                                WatchDetectionDetail(detection: detection)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(displayName(for: detection))
                                        .lineLimit(1)
                                    HStack {
                                        Text(watchLocalized(detection.transport))
                                        Spacer()
                                        Text("\(detection.rssi) dBm")
                                            .monospacedDigit()
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(
                                        signalColor(detection.rssi)
                                    )
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
                Button(
                    watchLocalized("Actualizar"),
                    systemImage: "arrow.clockwise"
                ) {
                    connectivity.refresh()
                }
            }
        }
    }

    private var connectionStatusText: String {
        guard let state = connectivity.snapshot.connectionState else {
            return connectivity.snapshot.connectionStatus
        }

        switch state {
        case .idle:
            return watchLocalized("Listo para conectar")
        case .searching:
            return watchLocalized("Buscando sensor")
        case .connecting:
            if let name = connectivity.snapshot.connectionName {
                return watchLocalizedFormat("Conectando a %@", name)
            }
            return watchLocalized("Buscando sensor")
        case .connected:
            if let name = connectivity.snapshot.connectionName {
                return watchLocalizedFormat("Conectado a %@", name)
            }
            return watchLocalized("Conectado")
        case .unavailable:
            return watchLocalized("Bluetooth no disponible")
        case .failed:
            return watchLocalized("No se pudo conectar")
        }
    }

    private func displayName(
        for detection: WatchDetectionSummary
    ) -> String {
        switch detection.fallbackName {
        case .hiddenNetwork:
            return watchLocalized("Red oculta")
        case .bluetoothDevice:
            return watchLocalized("Dispositivo BLE")
        case .unnamedDevice:
            return watchLocalized("Dispositivo sin nombre")
        case .none:
            return detection.name
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
            LabeledContent(
                watchLocalized("Origen"),
                value: watchLocalized(detection.transport)
            )
            LabeledContent(
                watchLocalized("Señal"),
                value: "\(detection.rssi) dBm"
            )
            LabeledContent(
                watchLocalized("Visto"),
                value: detection.seenAt.formatted(
                    date: .omitted,
                    time: .standard
                )
            )
            if let latitude = detection.latitude,
               let longitude = detection.longitude {
                Section(watchLocalized("Ubicación")) {
                    Text(
                        "\(latitude.formatted(.number.precision(.fractionLength(5)))), \(longitude.formatted(.number.precision(.fractionLength(5))))"
                    )
                    .font(.caption.monospaced())
                }
            }
        }
        .navigationTitle(displayName)
    }

    private var displayName: String {
        switch detection.fallbackName {
        case .hiddenNetwork:
            return watchLocalized("Red oculta")
        case .bluetoothDevice:
            return watchLocalized("Dispositivo BLE")
        case .unnamedDevice:
            return watchLocalized("Dispositivo sin nombre")
        case .none:
            return detection.name
        }
    }
}
