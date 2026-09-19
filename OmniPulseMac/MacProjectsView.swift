import Charts
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MacProjectsView: View {
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SurveyProject.updatedAt, order: .reverse) private var projects: [SurveyProject]
    @Query(sort: \DetectionRecord.seenAt, order: .reverse) private var allRecords: [DetectionRecord]
    @State private var selection: UUID?
    @State private var isCreating = false

    var body: some View {
        HSplitView {
            List(selection: $selection) {
                ForEach(projects) { project in
                    Label(project.name, systemImage: SurveyProjectSelection.activeProjectID == project.id ? "folder.fill.badge.checkmark" : "folder")
                        .tag(Optional(project.id))
                        .contextMenu {
                            Button("Usar como activo") { SurveyProjectSelection.activeProjectID = project.id }
                            Button("Eliminar", role: .destructive) { delete(project) }
                        }
                }
            }
            .frame(minWidth: 220, idealWidth: 250)

            if let project = projects.first(where: { $0.id == selection }) ?? projects.first {
                MacProjectDashboard(project: project, records: allRecords.filter { $0.projectID == project.id })
                    .frame(minWidth: 620)
            } else {
                ContentUnavailableView("Sin proyectos", systemImage: "folder.badge.plus", description: Text("Crea un proyecto para organizar mediciones e informes."))
                    .frame(minWidth: 620)
            }
        }
        .navigationTitle("Proyectos")
        .toolbar {
            Button("Nuevo proyecto", systemImage: "plus") { isCreating = true }
        }
        .sheet(isPresented: $isCreating) {
            MacNewProjectView()
        }
        .onAppear {
            if selection == nil { selection = projects.first?.id }
        }
    }

    private func delete(_ project: SurveyProject) {
        if SurveyProjectSelection.activeProjectID == project.id { SurveyProjectSelection.activeProjectID = nil }
        for record in allRecords where record.projectID == project.id { record.projectID = nil }
        modelContext.delete(project)
        try? modelContext.save()
        selection = projects.first(where: { $0.id != project.id })?.id
    }
}

private struct MacNewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var notes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nuevo proyecto").font(.title2.bold())
            TextField("Nombre", text: $name)
            TextField("Notas", text: $notes, axis: .vertical).lineLimit(3...6)
            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }
                Button("Crear") {
                    let project = SurveyProject(name: name.trimmingCharacters(in: .whitespacesAndNewlines), notes: notes)
                    modelContext.insert(project)
                    try? modelContext.save()
                    SurveyProjectSelection.activeProjectID = project.id
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 430)
    }
}

private struct MacProjectDashboard: View {
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext
    let project: SurveyProject
    let records: [DetectionRecord]
    @State private var isImportingPlan = false
    @State private var report: SurveyReportDocument?
    @State private var isExporting = false
    @AppStorage("wifiRecommendationWidthMHz")
    private var recommendationWidthMHz = 20
    @AppStorage("wifiIncludePotentialDFS")
    private var includePotentialDFS = false

    private var samples: [WiFiChannelSample] { WiFiChannelAnalyzer.samples(from: records) }
    private var stats: [WiFiChannelStat] { WiFiChannelAnalyzer.statistics(samples: samples) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(project.name).font(.largeTitle.bold())
                        Text("\(records.count) observaciones · \(records.filter { $0.transport == "Wi-Fi" }.count) Wi-Fi")
                            .foregroundStyle(appTheme.secondaryText)
                    }
                    Spacer()
                    Button(SurveyProjectSelection.activeProjectID == project.id ? "Proyecto activo" : "Activar proyecto", systemImage: "record.circle") {
                        SurveyProjectSelection.activeProjectID = project.id
                    }
                    .buttonStyle(.borderedProminent)
                }

                GroupBox("Recomendaciones") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            Picker(
                                "Ancho objetivo",
                                selection: $recommendationWidthMHz
                            ) {
                                ForEach([20, 40, 80, 160, 320], id: \.self) {
                                    Text("\($0) MHz").tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 180)

                            Toggle(
                                "Considerar DFS en 5 GHz",
                                isOn: $includePotentialDFS
                            )
                            .toggleStyle(.switch)

                            Spacer()
                        }

                        Text(
                            "La app compara presión espectral observada. "
                            + "La disponibilidad real de canales depende del país, "
                            + "del punto de acceso y del hardware."
                        )
                        .font(.caption)
                        .foregroundStyle(appTheme.secondaryText)

                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 190), spacing: 12)
                        ],
                        alignment: .leading,
                        spacing: 12
                    ) {
                        ForEach(WiFiBand.allCases) { band in
                            if let recommendation = WiFiChannelAnalyzer.recommendation(
                                for: band,
                                samples: samples,
                                channelWidthMHz: recommendationWidthMHz,
                                includePotentialDFS: includePotentialDFS
                            ) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Label(
                                        "\(band.rawValue): canal \(recommendation.channel)",
                                        systemImage: "checkmark.seal.fill"
                                    )
                                    .font(.headline)
                                    .foregroundStyle(appTheme.success)

                                    Text(
                                        "\(recommendation.channelWidthMHz) MHz · "
                                        + "\(recommendation.observedNetworkCount) redes observadas"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(appTheme.secondaryText)

                                    if recommendation.isPotentialDFS {
                                        Text("DFS potencial")
                                            .font(.caption.bold())
                                            .foregroundStyle(.orange)
                                    }

                                    Text(recommendation.explanation)
                                        .font(.caption)
                                        .foregroundStyle(appTheme.secondaryText)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    appTheme.surface.opacity(0.55),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(band.rawValue).font(.headline)
                                    Text("Sin muestras con banda identificable")
                                        .font(.caption)
                                        .foregroundStyle(appTheme.secondaryText)
                                }
                                .padding(10)
                            }
                        }
                    }
                    .padding(8)
                    }
                }

                GroupBox("Ocupación de canales") {
                    if stats.isEmpty {
                        ContentUnavailableView("Sin canales observados", systemImage: "chart.bar")
                    } else {
                        Chart(stats) { stat in
                            BarMark(x: .value("Canal", String(stat.channel)), y: .value("Congestión", stat.congestionScore))
                                .foregroundStyle(by: .value("Banda", stat.band.rawValue))
                        }
                        .frame(height: 240)
                        .padding(8)
                    }
                }

                if let data = project.floorPlanData, let image = NSImage(data: data) {
                    GroupBox("Plano") {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 360)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                    }
                }

                HStack {
                    Button(project.floorPlanData == nil ? "Importar plano" : "Cambiar plano", systemImage: "photo.badge.plus") {
                        isImportingPlan = true
                    }
                    Button("Exportar informe PDF", systemImage: "doc.richtext") {
                        report = SurveyReportDocument(project: project, records: records)
                        isExporting = true
                    }
                    .disabled(records.isEmpty)
                    Spacer()
                }
            }
            .padding(24)
        }
        .fileImporter(isPresented: $isImportingPlan, allowedContentTypes: [.image]) { result in
            if let url = try? result.get(), let data = try? Data(contentsOf: url) {
                project.floorPlanData = data
                project.updatedAt = .now
                try? modelContext.save()
            }
        }
        .fileExporter(isPresented: $isExporting, document: report, contentType: .pdf, defaultFilename: "OmniPulse-\(project.name)") { _ in }
    }
}
