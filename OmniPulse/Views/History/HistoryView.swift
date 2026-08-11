import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case iphoneBLE
    case sensorBLE
    case wifi

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            "Todo"
        case .iphoneBLE:
            "iPhone BLE"
        case .sensorBLE:
            "ESP32 BLE"
        case .wifi:
            "Wi-Fi"
        }
    }

    func includes(_ record: DetectionRecord) -> Bool {
        switch self {
        case .all:
            true
        case .iphoneBLE:
            record.source == DetectionSource.iphoneBLE.rawValue
        case .sensorBLE:
            record.source == DetectionSource.esp32BLE.rawValue
        case .wifi:
            record.transport == "Wi-Fi"
        }
    }
}

struct HistoryView: View {
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DetectionRecord.seenAt, order: .reverse) private var records: [DetectionRecord]

    @State private var searchText = ""
    @State private var selectedFilter: HistoryFilter = .all
    @State private var exportDocument: DetectionExportDocument?
    @State private var isExporting = false
    @State private var exportFeedback = ""
    @State private var isShowingExportFeedback = false

    private var filteredRecords: [DetectionRecord] {
        records.filter { record in
            let matchesFilter = selectedFilter.includes(record)
            let matchesSearch = searchText.isEmpty
                || record.displayName.localizedCaseInsensitiveContains(searchText)
                || record.transport.localizedCaseInsensitiveContains(searchText)
                || record.source.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        Group {
            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    records.isEmpty ? "Historial vacío" : "Sin coincidencias",
                    systemImage: records.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass",
                    description: Text(records.isEmpty ? "Guarda un descubrimiento desde la pestaña Escanear." : "Prueba con otro término de búsqueda.")
                )
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        NavigationLink {
                            DetectionRecordDetailView(record: record)
                        } label: {
                            DetectionRecordRow(record: record)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("Historial")
        .background(appTheme.background)
        .searchable(text: $searchText, prompt: "Nombre, origen o transporte")
        .toolbar {
            historyToolbar
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "OmniPulse-historial"
        ) { result in
            switch result {
            case .success:
                exportFeedback = "El archivo CSV se exportó correctamente."
            case .failure(let error):
                exportFeedback = "No se pudo exportar el archivo: \(error.localizedDescription)"
            }
            isShowingExportFeedback = true
        }
        .alert("Exportación", isPresented: $isShowingExportFeedback) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(exportFeedback)
        }
    }

    @ToolbarContentBuilder
    private var historyToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Filtrar", selection: $selectedFilter) {
                        ForEach(HistoryFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }

                    Divider()

                    Button {
                        exportFilteredRecords()
                    } label: {
                        Label("Exportar CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(filteredRecords.isEmpty)
                } label: {
                    Label("Opciones", systemImage: "line.3.horizontal.decrease.circle")
                }
        }
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredRecords[index])
        }
        try? modelContext.save()
    }

    private func exportFilteredRecords() {
        exportDocument = DetectionExportDocument(records: filteredRecords)
        isExporting = true
    }
}

struct DetectionRecordRow: View {
    @Environment(AppTheme.self) private var appTheme
    let record: DetectionRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.transport == "Wi-Fi" ? "wifi" : "dot.radiowaves.left.and.right")
                .foregroundStyle(record.hasLocation ? appTheme.accent : appTheme.secondaryText)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.displayName)
                    .lineLimit(1)
                Text("\(record.transport) · \(record.source)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(record.rssi) dBm")
                    .font(.subheadline.monospacedDigit())
                Text(record.seenAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct DetectionRecordDetailView: View {
    @Environment(AppTheme.self) private var appTheme
    let record: DetectionRecord

    var body: some View {
        Form {
            Section("Registro") {
                LabeledContent("Nombre", value: record.displayName)
                LabeledContent("Transporte", value: record.transport)
                LabeledContent("Origen", value: record.source)
                LabeledContent("Señal", value: "\(record.rssi) dBm")
                if let channel = record.wifiChannel {
                    LabeledContent("Canal Wi-Fi", value: "\(channel)")
                    if let band = record.wifiBand {
                        LabeledContent("Banda", value: band)
                    }
                }
                if let manufacturer = record.manufacturerName {
                    LabeledContent("Fabricante", value: manufacturer)
                }
                if let category = record.deviceCategory {
                    LabeledContent("Categoría", value: category)
                }
                if let beaconType = record.beaconType {
                    LabeledContent("Beacon", value: beaconType)
                }
                if let interval = record.advertisementInterval {
                    LabeledContent("Intervalo de anuncio", value: "\(Int((interval * 1_000).rounded())) ms")
                }
                LabeledContent("Fecha", value: record.seenAt.formatted(date: .abbreviated, time: .standard))
            }

            Section("Identificador") {
                Text(record.deviceIdentifier)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            }

            if record.sensorIdentifier != nil || record.sensorHardware != nil {
                Section("Sensor ESP32") {
                    if let identifier = record.sensorIdentifier { LabeledContent("Sensor", value: identifier) }
                    if let hardware = record.sensorHardware { LabeledContent("Hardware", value: hardware) }
                    if let firmware = record.sensorFirmwareVersion { LabeledContent("Firmware", value: firmware) }
                }
            }

            Section("Ubicación") {
                if let coordinate = record.coordinate {
                    LabeledContent("Coordenadas") {
                        Text("\(coordinate.latitude.formatted(.number.precision(.fractionLength(5)))), \(coordinate.longitude.formatted(.number.precision(.fractionLength(5))))")
                            .multilineTextAlignment(.trailing)
                    }
                    if let accuracy = record.horizontalAccuracy, accuracy >= 0 {
                        LabeledContent("Precisión", value: "±\(accuracy.formatted(.number.precision(.fractionLength(0)))) m")
                    }
                } else {
                    Text("Este registro se guardó sin coordenadas.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(record.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }
}
