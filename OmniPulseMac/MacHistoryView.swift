import SwiftData
import SwiftUI

struct MacHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppTheme.self) private var appTheme
    @Query(sort: \DetectionRecord.seenAt, order: .reverse) private var records: [DetectionRecord]

    @State private var selection: DetectionRecord?
    @State private var searchText = ""
    @State private var exportDocument: DetectionExportDocument?
    @State private var isExporting = false

    private var filtered: [DetectionRecord] {
        guard !searchText.isEmpty else { return records }
        return records.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
                || $0.transport.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HSplitView {
            List(filtered, selection: $selection) { record in
                HStack {
                    Image(systemName: record.transport == "Wi-Fi" ? "wifi" : "dot.radiowaves.left.and.right")
                        .foregroundStyle(appTheme.accent)
                    VStack(alignment: .leading) {
                        Text(record.displayName)
                        Text("\(record.transport) · \(record.rssi) dBm")
                            .font(.caption)
                            .foregroundStyle(appTheme.secondaryText)
                    }
                }
                .tag(record)
            }
            .searchable(text: $searchText)
            .frame(minWidth: 360)
            .scrollContentBackground(.hidden)
            .background(appTheme.background)

            Group {
                if let selection {
                    Form {
                        LabeledContent("Nombre", value: selection.displayName)
                        LabeledContent("Origen", value: selection.source)
                        LabeledContent("Señal", value: "\(selection.rssi) dBm")
                        LabeledContent("Fecha", value: selection.seenAt.formatted())
                        if let coordinate = selection.coordinate {
                            LabeledContent("Ubicación", value: "\(coordinate.latitude), \(coordinate.longitude)")
                        }
                        Text(selection.deviceIdentifier)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                    .formStyle(.grouped)
                    .scrollContentBackground(.hidden)
                    .background(appTheme.background)
                } else {
                    ContentUnavailableView("Selecciona un registro", systemImage: "clock.arrow.circlepath")
                }
            }
            .frame(minWidth: 420)
            .background(appTheme.background)
        }
        .navigationTitle("Historial")
        .toolbar {
            Button("Exportar CSV", systemImage: "square.and.arrow.up") {
                exportDocument = DetectionExportDocument(records: filtered)
                isExporting = true
            }
            .disabled(filtered.isEmpty)
            Button("Eliminar", systemImage: "trash", role: .destructive) {
                guard let selection else { return }
                modelContext.delete(selection)
                try? modelContext.save()
                self.selection = nil
            }
            .disabled(selection == nil)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "OmniPulse-historial"
        ) { _ in }
    }
}
