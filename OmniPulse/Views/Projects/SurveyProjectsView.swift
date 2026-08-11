import Charts
import MapKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct SurveyProjectsView: View {
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SurveyProject.updatedAt, order: .reverse) private var projects: [SurveyProject]
    @Query(sort: \DetectionRecord.seenAt, order: .reverse) private var records: [DetectionRecord]
    @State private var isCreatingProject = false

    var body: some View {
        List {
            Section {
                NavigationLink {
                    GlobalChannelAnalysisView(records: records)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Análisis general")
                            Text("Canales, congestión y recomendaciones de todas las mediciones")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundStyle(appTheme.accent)
                    }
                }
            }

            Section("Proyectos") {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "Sin proyectos",
                        systemImage: "folder.badge.plus",
                        description: Text("Crea un proyecto para agrupar mediciones, mapas e informes.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(projects) { project in
                        NavigationLink {
                            SurveyProjectDetailView(project: project)
                        } label: {
                            ProjectRow(
                                project: project,
                                recordCount: records.lazy.filter { $0.projectID == project.id }.count,
                                isActive: SurveyProjectSelection.activeProjectID == project.id
                            )
                        }
                    }
                    .onDelete(perform: deleteProjects)
                }
            }

            Section("Cómo funciona") {
                Text("El proyecto activo recibe automáticamente los lotes y dispositivos que guardes desde Escanear. Puedes cambiarlo en cualquier momento.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Proyectos")
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Nuevo proyecto", systemImage: "plus") {
                    isCreatingProject = true
                }
            }
        }
        .sheet(isPresented: $isCreatingProject) {
            NewSurveyProjectView()
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            if SurveyProjectSelection.activeProjectID == project.id {
                SurveyProjectSelection.activeProjectID = nil
            }
            for record in records where record.projectID == project.id {
                record.projectID = nil
                record.floorPlanX = nil
                record.floorPlanY = nil
            }
            modelContext.delete(project)
        }
        try? modelContext.save()
    }
}

private struct ProjectRow: View {
    let project: SurveyProject
    let recordCount: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isActive ? "folder.fill.badge.checkmark" : "folder")
                .font(.title3)
                .foregroundStyle(isActive ? Color.green : Color.accentColor)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                Text("\(recordCount) observaciones · actualizado \(project.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isActive {
                Text("Activo")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
    }
}

private struct NewSurveyProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nombre del proyecto", text: $name)
                TextField("Notas opcionales", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Nuevo proyecto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        let project = SurveyProject(name: name.trimmingCharacters(in: .whitespacesAndNewlines), notes: notes)
                        modelContext.insert(project)
                        try? modelContext.save()
                        SurveyProjectSelection.activeProjectID = project.id
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct SurveyProjectDetailView: View {
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DetectionRecord.seenAt, order: .reverse) private var allRecords: [DetectionRecord]
    let project: SurveyProject

    @State private var isImportingFloorPlan = false
    @State private var reportDocument: SurveyReportDocument?
    @State private var isExportingReport = false
    @State private var feedback = ""

    private var records: [DetectionRecord] { allRecords.filter { $0.projectID == project.id } }
    private var isActive: Bool { SurveyProjectSelection.activeProjectID == project.id }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        MetricView(value: "\(records.count)", label: "Observaciones")
                        MetricView(value: "\(records.filter { $0.transport == "Wi-Fi" }.count)", label: "Wi-Fi")
                        MetricView(value: "\(records.filter { $0.transport != "Wi-Fi" }.count)", label: "BLE")
                    }
                    if !project.notes.isEmpty {
                        Text(project.notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Captura") {
                Button {
                    SurveyProjectSelection.activeProjectID = isActive ? nil : project.id
                    feedback = isActive ? "Se detuvo la captura para este proyecto." : "Las nuevas observaciones se guardarán en \(project.name)."
                } label: {
                    Label(isActive ? "Detener proyecto activo" : "Usar como proyecto activo", systemImage: isActive ? "stop.circle.fill" : "record.circle")
                }
                .tint(isActive ? appTheme.warning : appTheme.accent)

                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Análisis") {
                NavigationLink {
                    GlobalChannelAnalysisView(records: records, title: project.name)
                } label: {
                    Label("Canales y recomendaciones", systemImage: "chart.bar.xaxis")
                }
                NavigationLink {
                    SurveyCoverageMapView(records: records, title: project.name)
                } label: {
                    Label("Mapa de cobertura", systemImage: "map.fill")
                }
                if let data = project.floorPlanData, !data.isEmpty {
                    NavigationLink {
                        FloorPlanSurveyView(project: project, records: records)
                    } label: {
                        Label("Plano y puntos de medición", systemImage: "square.grid.3x3.square")
                    }
                }
            }

            Section("Plano") {
                Button(project.floorPlanData == nil ? "Importar plano" : "Cambiar plano", systemImage: "photo.badge.plus") {
                    isImportingFloorPlan = true
                }
                if project.floorPlanData != nil {
                    Button("Eliminar plano", role: .destructive) {
                        project.floorPlanData = nil
                        for record in records {
                            record.floorPlanX = nil
                            record.floorPlanY = nil
                        }
                        project.updatedAt = .now
                        try? modelContext.save()
                    }
                }
            }

            Section("Informe") {
                Button("Exportar informe PDF", systemImage: "doc.richtext") {
                    reportDocument = SurveyReportDocument(project: project, records: records)
                    isExportingReport = true
                }
                .disabled(records.isEmpty)
            }

            Section("Observaciones recientes") {
                if records.isEmpty {
                    Text("Activa este proyecto y guarda detecciones desde Escanear.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(records.prefix(15)) { record in
                        DetectionRecordRow(record: record)
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
        .fileImporter(isPresented: $isImportingFloorPlan, allowedContentTypes: [.image]) { result in
            do {
                let url = try result.get()
                let granted = url.startAccessingSecurityScopedResource()
                defer { if granted { url.stopAccessingSecurityScopedResource() } }
                project.floorPlanData = try Data(contentsOf: url)
                project.updatedAt = .now
                try modelContext.save()
            } catch {
                feedback = "No se pudo importar el plano: \(error.localizedDescription)"
            }
        }
        .fileExporter(
            isPresented: $isExportingReport,
            document: reportDocument,
            contentType: .pdf,
            defaultFilename: "OmniPulse-\(project.name)"
        ) { result in
            if case .failure(let error) = result {
                feedback = "No se pudo exportar el informe: \(error.localizedDescription)"
            }
        }
    }
}

private struct MetricView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GlobalChannelAnalysisView: View {
    @Environment(AppTheme.self) private var appTheme
    let records: [DetectionRecord]
    var title = "Análisis Wi-Fi"

    private var samples: [WiFiChannelSample] { WiFiChannelAnalyzer.samples(from: records) }
    private var stats: [WiFiChannelStat] { WiFiChannelAnalyzer.statistics(samples: samples) }

    var body: some View {
        List {
            ForEach(WiFiBand.allCases) { band in
                Section(band.rawValue) {
                    if let recommendation = WiFiChannelAnalyzer.recommendation(for: band, samples: samples) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Canal recomendado: \(recommendation.channel)").font(.headline)
                                Text(recommendation.explanation).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(appTheme.success)
                        }
                    } else {
                        Text("Sin observaciones para esta banda.").foregroundStyle(.secondary)
                    }

                    let bandStats = stats.filter { $0.band == band }
                    if !bandStats.isEmpty {
                        Chart(bandStats) { stat in
                            BarMark(
                                x: .value("Canal", String(stat.channel)),
                                y: .value("Congestión", stat.congestionScore)
                            )
                            .foregroundStyle(appTheme.accent.gradient)
                            .annotation(position: .top) {
                                Text("\(stat.networkCount)").font(.caption2)
                            }
                        }
                        .frame(height: 190)

                        ForEach(bandStats) { stat in
                            LabeledContent("Canal \(stat.channel)") {
                                Text("\(stat.networkCount) redes · \(Int(stat.averageRSSI.rounded())) dBm")
                            }
                        }
                    }
                }
            }

            Section("Interpretación") {
                Text("La recomendación pondera cantidad, intensidad y solapamiento de canales. Confirma el resultado con varias mediciones antes de modificar un punto de acceso.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }
}

private struct CoveragePoint: Identifiable {
    let record: DetectionRecord
    let coordinate: CLLocationCoordinate2D
    var id: UUID { record.id }
}

struct SurveyCoverageMapView: View {
    @Environment(AppTheme.self) private var appTheme
    let records: [DetectionRecord]
    let title: String
    @State private var position: MapCameraPosition = .automatic

    private var points: [CoveragePoint] {
        records.compactMap { record in
            record.coordinate.map { CoveragePoint(record: record, coordinate: $0) }
        }
    }

    var body: some View {
        Group {
            if points.isEmpty {
                ContentUnavailableView("Sin puntos con ubicación", systemImage: "map")
            } else {
                Map(position: $position) {
                    ForEach(points) { point in
                        Annotation(point.record.displayName, coordinate: point.coordinate) {
                            Circle()
                                .fill(signalColor(point.record.rssi).opacity(0.50))
                                .stroke(.white.opacity(0.8), lineWidth: 1)
                                .frame(width: 26, height: 26)
                        }
                    }
                }
                .mapStyle(.standard)
            }
        }
        .navigationTitle(title)
    }

    private func signalColor(_ rssi: Int) -> Color {
        rssi >= -60 ? appTheme.strongSignal : (rssi >= -80 ? appTheme.mediumSignal : appTheme.weakSignal)
    }
}

struct FloorPlanSurveyView: View {
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext
    let project: SurveyProject
    let records: [DetectionRecord]
    @State private var selectedRecordID: UUID?

    private var selectedRecord: DetectionRecord? {
        records.first { $0.id == selectedRecordID }
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Medición a colocar", selection: $selectedRecordID) {
                Text("Selecciona una observación").tag(UUID?.none)
                ForEach(records) { record in
                    Text("\(record.displayName) · \(record.rssi) dBm").tag(Optional(record.id))
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            if let data = project.floorPlanData, let image = UIImage(data: data) {
                GeometryReader { geometry in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        ForEach(records.filter(\.hasFloorPlanPosition)) { record in
                            if let x = record.floorPlanX, let y = record.floorPlanY {
                                VStack(spacing: 2) {
                                    Circle()
                                        .fill(signalColor(record.rssi))
                                        .frame(width: 22, height: 22)
                                    Text("\(record.rssi)")
                                        .font(.caption2.bold())
                                        .padding(2)
                                        .background(.regularMaterial, in: Capsule())
                                }
                                .position(x: x * geometry.size.width, y: y * geometry.size.height)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            guard let selectedRecord else { return }
                            selectedRecord.floorPlanX = min(1, max(0, value.location.x / geometry.size.width))
                            selectedRecord.floorPlanY = min(1, max(0, value.location.y / geometry.size.height))
                            project.updatedAt = .now
                            try? modelContext.save()
                        }
                    )
                }
            } else {
                ContentUnavailableView("Plano no disponible", systemImage: "photo")
            }

            Text(selectedRecord == nil ? "Selecciona una observación y toca su posición en el plano." : "Toca el plano para colocar o mover la medición seleccionada.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .navigationTitle("Plano de \(project.name)")
    }

    private func signalColor(_ rssi: Int) -> Color {
        rssi >= -60 ? appTheme.strongSignal : (rssi >= -80 ? appTheme.mediumSignal : appTheme.weakSignal)
    }
}
