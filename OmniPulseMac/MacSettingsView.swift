import SwiftUI

struct MacSettingsView: View {
    @Environment(AppTheme.self) private var appTheme
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @State private var customPalette = ThemePalette.defaultCustom

    private var selectedAppearance: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        Form {
            Section("Apariencia") {
                Picker("Modo", selection: $appearanceMode) {
                    ForEach(AppAppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Tema", selection: presetBinding) {
                    ForEach(AppThemePreset.allCases) { preset in
                        Label(preset.title, systemImage: preset.systemImage)
                            .tag(preset)
                    }
                }

                MacThemePreviewCard(
                    accent: appTheme.accent,
                    background: appTheme.background,
                    surface: appTheme.surface,
                    primaryText: appTheme.primaryText,
                    secondaryText: appTheme.secondaryText,
                    success: appTheme.success,
                    warning: appTheme.warning
                )

                Text("Los cambios de modo y tema se aplican inmediatamente a todas las ventanas.")
                    .font(.caption)
                    .foregroundStyle(appTheme.secondaryText)
            }

            Section("Tema personalizado") {
                if appTheme.selectedPreset != .custom {
                    Button("Usar y editar mi tema", systemImage: "paintpalette.fill") {
                        customPalette = appTheme.customPalette
                        appTheme.select(.custom)
                    }
                } else {
                    colorGrid

                    HStack {
                        Label("Vista previa en vivo", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(appTheme.success)
                        Spacer()
                        Button("Restaurar colores", role: .destructive) {
                            customPalette = .defaultCustom
                            appTheme.saveCustom(customPalette)
                        }
                    }
                }
            }

            Section {
                Button("Restaurar apariencia") {
                    appearanceMode = AppAppearanceMode.system.rawValue
                    UserDefaults.standard.set(AppAccent.indigo.rawValue, forKey: "accentColor")
                    appTheme.select(.system)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
        .padding()
        .navigationTitle("Apariencia")
        .tint(appTheme.accent)
        .foregroundStyle(appTheme.primaryText)
        .preferredColorScheme(selectedAppearance.colorScheme ?? appTheme.suggestedColorScheme)
        .onAppear { customPalette = appTheme.customPalette }
        .onChange(of: appTheme.customPalette) { _, palette in
            if palette != customPalette {
                customPalette = palette
            }
        }
    }

    private var colorGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 12) {
            GridRow {
                themeColor("Principal", \.accent)
                themeColor("Fondo", \.background)
            }
            GridRow {
                themeColor("Superficie", \.surface)
                themeColor("Texto", \.primaryText)
            }
            GridRow {
                themeColor("Texto secundario", \.secondaryText)
                themeColor("Correcto", \.success)
            }
            GridRow {
                themeColor("Advertencia", \.warning)
                themeColor("Señal fuerte", \.strongSignal)
            }
            GridRow {
                themeColor("Señal media", \.mediumSignal)
                themeColor("Señal débil", \.weakSignal)
            }
        }
    }

    private var presetBinding: Binding<AppThemePreset> {
        Binding(
            get: { appTheme.selectedPreset },
            set: { preset in
                if preset == .custom {
                    customPalette = appTheme.customPalette
                }
                appTheme.select(preset)
            }
        )
    }

    private func themeColor(
        _ title: LocalizedStringKey,
        _ keyPath: WritableKeyPath<ThemePalette, String>
    ) -> some View {
        ColorPicker(title, selection: Binding(
            get: { Color(hex: customPalette[keyPath: keyPath]) ?? .clear },
            set: { color in
                customPalette[keyPath: keyPath] = color.hexString
                appTheme.saveCustom(customPalette)
            }
        ), supportsOpacity: false)
        .frame(minWidth: 190)
    }
}

private struct MacThemePreviewCard: View {
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
            Text("Fondo, superficies, texto, controles y estados.")
                .font(.caption)
                .foregroundStyle(secondaryText)

            HStack(spacing: 8) {
                colorSample(accent)
                colorSample(success)
                colorSample(warning)
            }
        }
        .padding(16)
        .background(surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.35), lineWidth: 1)
        }
        .padding(.vertical, 4)
        .listRowBackground(background)
    }

    private func colorSample(_ color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(height: 7)
    }
}
