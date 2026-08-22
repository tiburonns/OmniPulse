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

enum AppThemeCategory: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dark: "Modo oscuro"
        case .light: "Modo claro"
        }
    }

    var systemImage: String {
        switch self {
        case .dark: "moon.fill"
        case .light: "sun.max.fill"
        }
    }
}

enum AppThemePreset: String, CaseIterable, Identifiable {
    case system
    case dark
    case slate
    case moonlight
    case midnight
    case ember
    case nord
    case light
    case indigo
    case sunshine
    case ocean
    case forest
    case rose
    case lavender
    case monochrome
    case custom

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system: "Automático"
        case .dark: "Dark"
        case .slate: "Slate"
        case .moonlight: "Moonlight"
        case .midnight: "Midnight"
        case .ember: "Ember"
        case .nord: "Nord"
        case .light: "Light"
        case .indigo: "Indigo"
        case .sunshine: "Sunshine"
        case .ocean: "Ocean"
        case .forest: "Forest"
        case .rose: "Rose"
        case .lavender: "Lavender"
        case .monochrome: "Monochrome"
        case .custom: "Personalizado"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .dark: "moon.fill"
        case .slate: "square.stack.3d.up.fill"
        case .moonlight: "moon.stars.fill"
        case .midnight: "moon.zzz.fill"
        case .ember: "flame.fill"
        case .nord: "mountain.2.fill"
        case .light: "sun.max.fill"
        case .indigo: "wand.and.stars"
        case .sunshine: "sun.horizon.fill"
        case .ocean: "water.waves"
        case .forest: "leaf.fill"
        case .rose: "camera.macro"
        case .lavender: "camera.macro.circle.fill"
        case .monochrome: "circle.lefthalf.filled"
        case .custom: "paintpalette.fill"
        }
    }

    static let darkPresets: [AppThemePreset] = [
        .dark, .slate, .moonlight, .midnight, .ember, .nord
    ]

    static let lightPresets: [AppThemePreset] = [
        .light, .indigo, .sunshine, .ocean, .forest, .rose, .lavender, .monochrome
    ]

    var category: AppThemeCategory? {
        if Self.darkPresets.contains(self) { return .dark }
        if Self.lightPresets.contains(self) { return .light }
        return nil
    }

    var appearanceMode: AppAppearanceMode? {
        if self == .system { return .system }
        switch category {
        case .dark: return .dark
        case .light: return .light
        case nil: return nil
        }
    }

    static func restored(from storedValue: String?) -> AppThemePreset {
        if let storedValue, let preset = AppThemePreset(rawValue: storedValue) {
            return preset
        }
        switch storedValue {
        case "sunset": return .sunshine
        case "cyber": return .midnight
        case "graphite": return .slate
        default: return .system
        }
    }

    var palette: ThemePalette? {
        switch self {
        case .system:
            nil
        case .dark:
            ThemePalette(
                accent: "0A84FF", background: "0B0D10", surface: "1C1F24",
                primaryText: "F7F8FA", secondaryText: "A9ADB5", success: "30D158",
                warning: "FF9F0A", strongSignal: "30D158", mediumSignal: "FF9F0A", weakSignal: "74777E"
            )
        case .slate:
            ThemePalette(
                accent: "94A3B8", background: "0F172A", surface: "1E293B",
                primaryText: "F8FAFC", secondaryText: "CBD5E1", success: "4ADE80",
                warning: "FBBF24", strongSignal: "4ADE80", mediumSignal: "FBBF24", weakSignal: "64748B"
            )
        case .moonlight:
            ThemePalette(
                accent: "C4B5FD", background: "151226", surface: "25203D",
                primaryText: "F8F7FF", secondaryText: "BCB7D4", success: "6EE7B7",
                warning: "FCD34D", strongSignal: "67E8F9", mediumSignal: "FCD34D", weakSignal: "77718F"
            )
        case .midnight:
            ThemePalette(
                accent: "22D3EE", background: "030712", surface: "111827",
                primaryText: "F9FAFB", secondaryText: "9CA3AF", success: "34D399",
                warning: "FBBF24", strongSignal: "22D3EE", mediumSignal: "FBBF24", weakSignal: "6B7280"
            )
        case .ember:
            ThemePalette(
                accent: "FF6B35", background: "1A0D0A", surface: "351A12",
                primaryText: "FFF7ED", secondaryText: "D9B8A8", success: "4ADE80",
                warning: "FBBF24", strongSignal: "FF7A45", mediumSignal: "FBBF24", weakSignal: "8C6A5D"
            )
        case .nord:
            ThemePalette(
                accent: "88C0D0", background: "2E3440", surface: "3B4252",
                primaryText: "ECEFF4", secondaryText: "D8DEE9", success: "A3BE8C",
                warning: "EBCB8B", strongSignal: "8FBCBB", mediumSignal: "D08770", weakSignal: "7B88A1"
            )
        case .light:
            ThemePalette(
                accent: "007AFF", background: "F2F2F7", surface: "FFFFFF",
                primaryText: "111114", secondaryText: "636366", success: "248A3D",
                warning: "B95F00", strongSignal: "248A3D", mediumSignal: "B95F00", weakSignal: "8E8E93"
            )
        case .indigo:
            ThemePalette(
                accent: "5856D6", background: "F5F5FF", surface: "FFFFFF",
                primaryText: "1F1D3A", secondaryText: "67628A", success: "248A3D",
                warning: "B75D00", strongSignal: "3A7D44", mediumSignal: "B75D00", weakSignal: "8D89A6"
            )
        case .sunshine:
            ThemePalette(
                accent: "F59E0B", background: "FFF8E1", surface: "FFFDF5",
                primaryText: "3D2C05", secondaryText: "7C6829", success: "2F855A",
                warning: "C96A00", strongSignal: "2F855A", mediumSignal: "C96A00", weakSignal: "9A8A5E"
            )
        case .ocean:
            ThemePalette(
                accent: "0077B6", background: "ECF8FC", surface: "FFFFFF",
                primaryText: "0B2C3D", secondaryText: "4A7184", success: "16865F",
                warning: "B96800", strongSignal: "0088A9", mediumSignal: "B96800", weakSignal: "7895A5"
            )
        case .forest:
            ThemePalette(
                accent: "2F855A", background: "EFF8F1", surface: "FFFFFF",
                primaryText: "183B25", secondaryText: "587563", success: "228B4E",
                warning: "B96D00", strongSignal: "228B4E", mediumSignal: "B96D00", weakSignal: "82998A"
            )
        case .rose:
            ThemePalette(
                accent: "E11D48", background: "FFF1F4", surface: "FFFFFF",
                primaryText: "4A1321", secondaryText: "8D5965", success: "2E8B57",
                warning: "B86800", strongSignal: "2E8B57", mediumSignal: "B86800", weakSignal: "A4848C"
            )
        case .lavender:
            ThemePalette(
                accent: "7C5CE7", background: "F5F0FF", surface: "E7DDFB",
                primaryText: "2D2341", secondaryText: "74658E", success: "2F9B75",
                warning: "CC7A22", strongSignal: "2F9B75", mediumSignal: "CC7A22", weakSignal: "948AA6"
            )
        case .monochrome:
            ThemePalette(
                accent: "3A3A3C", background: "F2F2F2", surface: "FFFFFF",
                primaryText: "111111", secondaryText: "686868", success: "3A3A3C",
                warning: "626264", strongSignal: "2C2C2E", mediumSignal: "686868", weakSignal: "9A9A9E"
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
        selectedPreset = AppThemePreset.restored(from: defaults.string(forKey: Keys.preset))
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
