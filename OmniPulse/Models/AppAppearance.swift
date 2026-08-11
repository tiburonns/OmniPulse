import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system: "Sistema"
        case .light: "Claro"
        case .dark: "Oscuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppAccent: String, CaseIterable, Identifiable {
    case indigo
    case blue
    case teal
    case green
    case orange
    case pink
    case purple

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .indigo: "Índigo"
        case .blue: "Azul"
        case .teal: "Turquesa"
        case .green: "Verde"
        case .orange: "Naranja"
        case .pink: "Rosa"
        case .purple: "Morado"
        }
    }

    var color: Color {
        switch self {
        case .indigo: .indigo
        case .blue: .blue
        case .teal: .teal
        case .green: .green
        case .orange: .orange
        case .pink: .pink
        case .purple: .purple
        }
    }
}

enum AppThemePreset: String, CaseIterable, Identifiable {
    case system
    case ocean
    case forest
    case sunset
    case cyber
    case lavender
    case graphite
    case custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system: "Clásico"
        case .ocean: "Océano"
        case .forest: "Bosque"
        case .sunset: "Atardecer"
        case .cyber: "Cyber"
        case .lavender: "Lavanda"
        case .graphite: "Grafito"
        case .custom: "Personalizado"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .ocean: "water.waves"
        case .forest: "leaf.fill"
        case .sunset: "sun.horizon.fill"
        case .cyber: "bolt.fill"
        case .lavender: "camera.macro"
        case .graphite: "circle.hexagongrid.fill"
        case .custom: "paintpalette.fill"
        }
    }

    var palette: ThemePalette? {
        switch self {
        case .system:
            nil
        case .ocean:
            ThemePalette(
                accent: "36C5F0", background: "071A2B", surface: "102F47",
                primaryText: "F5FBFF", secondaryText: "9EC7D9", success: "4ADE80",
                warning: "FBBF24", strongSignal: "2DD4BF", mediumSignal: "FBBF24", weakSignal: "7895A5"
            )
        case .forest:
            ThemePalette(
                accent: "68D391", background: "10251B", surface: "1B3A2A",
                primaryText: "F2FFF6", secondaryText: "A9CCB6", success: "68D391",
                warning: "F6C453", strongSignal: "68D391", mediumSignal: "F6C453", weakSignal: "82998A"
            )
        case .sunset:
            ThemePalette(
                accent: "E85D3F", background: "FFF4E8", surface: "FFE1C7",
                primaryText: "402218", secondaryText: "805E50", success: "358A52",
                warning: "D97706", strongSignal: "358A52", mediumSignal: "D97706", weakSignal: "9A8177"
            )
        case .cyber:
            ThemePalette(
                accent: "00E5FF", background: "070A12", surface: "151927",
                primaryText: "F5F7FF", secondaryText: "9BA4C5", success: "35F28B",
                warning: "FFE45E", strongSignal: "35F28B", mediumSignal: "FFE45E", weakSignal: "69708A"
            )
        case .lavender:
            ThemePalette(
                accent: "7C5CE7", background: "F5F0FF", surface: "E7DDFB",
                primaryText: "2D2341", secondaryText: "74658E", success: "2F9B75",
                warning: "CC7A22", strongSignal: "2F9B75", mediumSignal: "CC7A22", weakSignal: "948AA6"
            )
        case .graphite:
            ThemePalette(
                accent: "A9B4C2", background: "121417", surface: "24282D",
                primaryText: "F5F7FA", secondaryText: "AEB5BE", success: "55C58A",
                warning: "E9B44C", strongSignal: "55C58A", mediumSignal: "E9B44C", weakSignal: "7B838D"
            )
        case .custom:
            nil
        }
    }
}

struct ThemePalette: Codable, Equatable, Sendable {
    var accent: String
    var background: String
    var surface: String
    var primaryText: String
    var secondaryText: String
    var success: String
    var warning: String
    var strongSignal: String
    var mediumSignal: String
    var weakSignal: String

    static let defaultCustom = ThemePalette(
        accent: "5856D6", background: "F2F2F7", surface: "FFFFFF",
        primaryText: "151518", secondaryText: "6D6D72", success: "30B86B",
        warning: "F59E0B", strongSignal: "22A65A", mediumSignal: "E88B00", weakSignal: "8E8E93"
    )
}

@MainActor
@Observable
final class AppTheme {
    private enum Keys {
        static let preset = "appThemePreset"
        static let customPalette = "customThemePalette"
    }

    var selectedPreset: AppThemePreset {
        didSet { defaults.set(selectedPreset.rawValue, forKey: Keys.preset) }
    }

    var customPalette: ThemePalette {
        didSet {
            if let data = try? JSONEncoder().encode(customPalette) {
                defaults.set(data, forKey: Keys.customPalette)
            }
        }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedPreset = AppThemePreset(rawValue: defaults.string(forKey: Keys.preset) ?? "") ?? .system
        if let data = defaults.data(forKey: Keys.customPalette),
           let palette = try? JSONDecoder().decode(ThemePalette.self, from: data) {
            customPalette = palette
        } else {
            var palette = ThemePalette.defaultCustom
            if let legacyAccent = AppAccent(rawValue: defaults.string(forKey: "accentColor") ?? "") {
                palette.accent = legacyAccent.color.hexString
            }
            customPalette = palette
        }
    }

    var activePalette: ThemePalette? {
        selectedPreset == .custom ? customPalette : selectedPreset.palette
    }

    var accent: Color {
        if selectedPreset == .system,
           let legacyAccent = AppAccent(rawValue: defaults.string(forKey: "accentColor") ?? "") {
            return legacyAccent.color
        }
        return color(\.accent, fallback: .indigo)
    }

    var background: Color {
        selectedPreset == .system ? Self.systemBackground : color(\.background, fallback: Self.systemBackground)
    }

    var surface: Color {
        selectedPreset == .system ? Self.systemSurface : color(\.surface, fallback: Self.systemSurface)
    }

    var primaryText: Color { selectedPreset == .system ? .primary : color(\.primaryText, fallback: .primary) }
    var secondaryText: Color { selectedPreset == .system ? .secondary : color(\.secondaryText, fallback: .secondary) }
    var success: Color { selectedPreset == .system ? .green : color(\.success, fallback: .green) }
    var warning: Color { selectedPreset == .system ? .orange : color(\.warning, fallback: .orange) }
    var strongSignal: Color { selectedPreset == .system ? .green : color(\.strongSignal, fallback: .green) }
    var mediumSignal: Color { selectedPreset == .system ? .orange : color(\.mediumSignal, fallback: .orange) }
    var weakSignal: Color { selectedPreset == .system ? .secondary : color(\.weakSignal, fallback: .secondary) }

    var suggestedColorScheme: ColorScheme? {
        guard let backgroundHex = activePalette?.background,
              let value = UInt64(backgroundHex, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance < 0.5 ? .dark : .light
    }

    func select(_ preset: AppThemePreset) {
        selectedPreset = preset
    }

    func saveCustom(_ palette: ThemePalette) {
        customPalette = palette
        selectedPreset = .custom
    }

    func resetCustom() {
        customPalette = .defaultCustom
    }

    private func color(_ keyPath: KeyPath<ThemePalette, String>, fallback: Color) -> Color {
        guard let activePalette else { return fallback }
        return Color(hex: activePalette[keyPath: keyPath]) ?? fallback
    }

    private static var systemBackground: Color {
#if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
#else
        Color(nsColor: .windowBackgroundColor)
#endif
    }

    private static var systemSurface: Color {
#if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
#else
        Color(nsColor: .controlBackgroundColor)
#endif
    }
}

extension Color {
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var hexString: String {
#if canImport(UIKit)
        let color = UIColor(self)
#else
        guard let color = NSColor(self).usingColorSpace(.deviceRGB) else { return "5856D6" }
#endif
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
#if canImport(UIKit)
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return "5856D6" }
#else
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
#endif
        return String(format: "%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
