import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    private enum DeletionRequest {
        case all
        case expired

        var title: String {
            switch self {
            case .all:
                "¿Borrar todo el historial local?"
            case .expired:
                "¿Eliminar los registros fuera de la retención?"
            }
        }

        var confirmationTitle: String {
            switch self {
            case .all:
                "Borrar todo"
            case .expired:
                "Eliminar registros caducados"
            }
        }
    }

    @Environment(BluetoothScanner.self) private var scanner
    @Environment(LocationService.self) private var locationService
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var records: [DetectionRecord]

    @AppStorage("retentionDays") private var retentionDays = 90
    @State private var deletionRequest: DeletionRequest?

    private var applicationLanguageName: String {
        let code = Bundle.main.preferredLocalizations.first ?? Locale.current.language.languageCode?.identifier ?? "es"
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? "Sistema"
    }

    private var expiredRecords: [DetectionRecord] {
        guard retentionDays > 0 else { return [] }
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: .now) ?? .distantPast
        return records.filter { $0.seenAt < cutoff }
    }

    var body: some View {
        Form {
            Section("Estado") {
                LabeledContent("Bluetooth", value: scanner.status.title)
                LabeledContent("Ubicación", value: locationService.statusDescription)
                Button("Actualizar ubicación") {
                    locationService.requestCurrentLocation()
                }
            }

            Section("Datos locales") {
                LabeledContent("Registros guardados", value: "\(records.count)")
                Button("Borrar todo el historial", role: .destructive) {
                    deletionRequest = .all
                }
                .disabled(records.isEmpty)
            }

            Section("Retención") {
                Picker("Conservar registros", selection: $retentionDays) {
                    Text("Sin límite").tag(0)
                    Text("7 días").tag(7)
                    Text("30 días").tag(30)
                    Text("90 días").tag(90)
                    Text("1 año").tag(365)
                }

                if retentionDays == 0 {
                    Text("OmniPulse no eliminará registros por antigüedad.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Hay \(expiredRecords.count) registros fuera de los últimos \(retentionDays) días.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Eliminar registros caducados", role: .destructive) {
                        deletionRequest = .expired
                    }
                    .disabled(expiredRecords.isEmpty)
                }
            }

            Section("Privacidad") {
                NavigationLink("Cómo maneja OmniPulse los datos") {
                    PrivacyDetailView()
                }
                Text("El escaneo no guarda automáticamente. La app solo persiste una observación cuando eliges Guardar.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Ayuda") {
                NavigationLink("Guías de uso y flasheo") {
                    GuidesView()
                }
                NavigationLink("Sugerencias y comentarios") {
                    FeedbackView()
                }
            }

            Section("Idioma") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    LabeledContent("Idioma de la aplicación", value: applicationLanguageName)
                }
                Text("Elige Idioma en los ajustes de iOS de OmniPulse. La aplicación se abrirá nuevamente con el idioma seleccionado.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            AppearanceSettingsSection()
        }
        .navigationTitle("Ajustes")
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
        .confirmationDialog(
            deletionRequest?.title ?? "",
            isPresented: Binding(
                get: { deletionRequest != nil },
                set: { if !$0 { deletionRequest = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let deletionRequest {
                Button(deletionRequest.confirmationTitle, role: .destructive) {
                    delete(request: deletionRequest)
                }
            }
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
    }

    private func delete(request: DeletionRequest) {
        let targets: [DetectionRecord]
        switch request {
        case .all:
            targets = records
        case .expired:
            targets = expiredRecords
        }

        for record in targets {
            modelContext.delete(record)
        }
        try? modelContext.save()
        deletionRequest = nil
    }
}

private struct AppearanceSettingsSection: View {
    @Environment(AppTheme.self) private var appTheme
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue

    var body: some View {
        Section("Apariencia") {
            Picker("Modo", selection: $appearanceMode) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)

            Picker("Tema", selection: themeSelection) {
                ForEach(AppThemePreset.allCases) { preset in
                    Label {
                        Text(preset.title)
                    } icon: {
                        Image(systemName: preset == appTheme.selectedPreset ? "checkmark.circle.fill" : preset.systemImage)
                            .foregroundStyle(previewColor(for: preset))
                    }
                    .tag(preset)
                }
            }

            ThemePreviewCard(
                accent: appTheme.accent,
                background: appTheme.background,
                surface: appTheme.surface,
                primaryText: appTheme.primaryText,
                secondaryText: appTheme.secondaryText,
                success: appTheme.success,
                warning: appTheme.warning
            )

            NavigationLink {
                CustomThemeEditorView()
            } label: {
                Label(
                    appTheme.selectedPreset == .custom ? "Editar mi tema" : "Crear mi tema",
                    systemImage: "paintpalette.fill"
                )
            }

            Button("Restaurar apariencia") {
                appearanceMode = AppAppearanceMode.system.rawValue
                UserDefaults.standard.set(AppAccent.indigo.rawValue, forKey: "accentColor")
                appTheme.select(.system)
            }
        }
    }

    private var themeSelection: Binding<AppThemePreset> {
        Binding(
            get: { appTheme.selectedPreset },
            set: { appTheme.select($0) }
        )
    }

    private func previewColor(for preset: AppThemePreset) -> Color {
        if preset == .system { return .indigo }
        let palette = preset == .custom ? appTheme.customPalette : preset.palette
        return palette.flatMap { Color(hex: $0.accent) } ?? .indigo
    }
}

private struct CustomThemeEditorView: View {
    @Environment(AppTheme.self) private var appTheme
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ThemePalette.defaultCustom

    var body: some View {
        Form {
            Section("Vista previa") {
                ThemePreviewCard(
                    accent: color(\.accent),
                    background: color(\.background),
                    surface: color(\.surface),
                    primaryText: color(\.primaryText),
                    secondaryText: color(\.secondaryText),
                    success: color(\.success),
                    warning: color(\.warning)
                )
            }

            ThemeColorSection(
                title: "Estructura",
                colors: [
                    ThemeColorControl(title: "Color principal", systemImage: "paintbrush.fill", keyPath: \.accent),
                    ThemeColorControl(title: "Fondo", systemImage: "rectangle.fill", keyPath: \.background),
                    ThemeColorControl(title: "Tarjetas y superficies", systemImage: "rectangle.inset.filled", keyPath: \.surface)
                ],
                draft: $draft
            )

            ThemeColorSection(
                title: "Texto y estados",
                colors: [
                    ThemeColorControl(title: "Texto principal", systemImage: "textformat", keyPath: \.primaryText),
                    ThemeColorControl(title: "Texto secundario", systemImage: "textformat.size.smaller", keyPath: \.secondaryText),
                    ThemeColorControl(title: "Conectado y correcto", systemImage: "checkmark.circle.fill", keyPath: \.success),
                    ThemeColorControl(title: "Advertencias", systemImage: "exclamationmark.triangle.fill", keyPath: \.warning)
                ],
                draft: $draft
            )

            ThemeColorSection(
                title: "Intensidad de señal",
                colors: [
                    ThemeColorControl(title: "Señal fuerte", systemImage: "wifi", keyPath: \.strongSignal),
                    ThemeColorControl(title: "Señal media", systemImage: "wifi", keyPath: \.mediumSignal),
                    ThemeColorControl(title: "Señal débil", systemImage: "wifi.exclamationmark", keyPath: \.weakSignal)
                ],
                draft: $draft
            )

            Section {
                Button("Restaurar colores personalizados", role: .destructive) {
                    draft = .defaultCustom
                }
            }
        }
        .navigationTitle("Mi tema")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(color(\.background))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Guardar") {
                    appTheme.saveCustom(draft)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            draft = appTheme.customPalette
        }
    }

    private func color(_ keyPath: KeyPath<ThemePalette, String>) -> Color {
        Color(hex: draft[keyPath: keyPath]) ?? .clear
    }
}

private struct ThemeColorControl {
    let title: LocalizedStringKey
    let systemImage: String
    let keyPath: WritableKeyPath<ThemePalette, String>
}

private struct ThemeColorSection: View {
    let title: LocalizedStringKey
    let colors: [ThemeColorControl]
    @Binding var draft: ThemePalette

    var body: some View {
        Section(title) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, control in
                ColorPicker(selection: binding(for: control.keyPath), supportsOpacity: false) {
                    Label(control.title, systemImage: control.systemImage)
                }
            }
        }
    }

    private func binding(for keyPath: WritableKeyPath<ThemePalette, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: draft[keyPath: keyPath]) ?? .clear },
            set: { draft[keyPath: keyPath] = $0.hexString }
        )
    }
}

private struct ThemePreviewCard: View {
    let accent: Color
    let background: Color
    let surface: Color
    let primaryText: Color
    let secondaryText: Color
    let success: Color
    let warning: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("OmniPulse", systemImage: "wave.3.right.circle.fill")
                    .font(.headline)
                    .foregroundStyle(accent)
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(success)
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(warning)
            }

            Text("Vista previa del tema")
                .foregroundStyle(primaryText)
            Text("Fondo, superficie, texto, controles y estados.")
                .font(.caption)
                .foregroundStyle(secondaryText)

            HStack(spacing: 6) {
                ForEach([accent, success, warning], id: \.description) { color in
                    Capsule()
                        .fill(color)
                        .frame(height: 7)
                }
            }
        }
        .padding()
        .background(surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.vertical, 4)
        .listRowBackground(background)
    }
}

struct PrivacyDetailView: View {
    var body: some View {
        List {
            Section("Lo que registra esta base") {
                Label("Anuncios Bluetooth Low Energy visibles", systemImage: "dot.radiowaves.left.and.right")
                Label("Señal RSSI aproximada", systemImage: "antenna.radiowaves.left.and.right")
                Label("Ubicación solo al guardar, si está autorizada", systemImage: "location")
            }

            Section("Lo que no hace") {
                Label("No captura tráfico de red", systemImage: "xmark.shield")
                Label("No obtiene credenciales ni MAC en claro", systemImage: "key.slash")
                Label("No envía datos a un servidor", systemImage: "icloud.slash")
            }

            Section("Tu control") {
                Text("Puedes guardar sin ubicación y borrar todo el historial desde Ajustes. Usa el sistema únicamente en entornos y equipos autorizados.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacidad")
        .navigationBarTitleDisplayMode(.inline)
    }
}
