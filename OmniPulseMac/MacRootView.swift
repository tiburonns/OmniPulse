import SwiftUI

private enum MacSection: String, CaseIterable, Identifiable {
    case scan
    case history
    case map
    case projects
    case firmware
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scan: "Escanear"
        case .history: "Historial"
        case .map: "Mapa"
        case .projects: "Proyectos"
        case .firmware: "Firmware"
        case .settings: "Apariencia"
        }
    }

    var systemImage: String {
        switch self {
        case .scan: "dot.radiowaves.left.and.right"
        case .history: "clock.arrow.circlepath"
        case .map: "map"
        case .projects: "folder"
        case .firmware: "memorychip"
        case .settings: "paintpalette"
        }
    }
}

struct MacRootView: View {
    @Environment(AppTheme.self) private var appTheme
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue
    @State private var selection: MacSection? = .scan

    private var selectedAppearance: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        NavigationSplitView {
            List(MacSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("OmniPulse")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
            .scrollContentBackground(.hidden)
            .background(appTheme.surface)
        } detail: {
            Group {
                switch selection ?? .scan {
                case .scan: MacScannerView()
                case .history: MacHistoryView()
                case .map: MacMapView()
                case .projects: MacProjectsView()
                case .firmware: MacFirmwareView()
                case .settings: MacSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(appTheme.background)
        }
        .tint(appTheme.accent)
        .foregroundStyle(appTheme.primaryText)
        .preferredColorScheme(selectedAppearance.colorScheme ?? appTheme.suggestedColorScheme)
        .background(appTheme.background)
    }
}
