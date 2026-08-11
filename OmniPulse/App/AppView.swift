import SwiftUI

enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case scan
    case history
    case map
    case projects
    case guides
    case settings

    var id: String { rawValue }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .scan:
            ScanHubView()
        case .history:
            HistoryView()
        case .map:
            DetectionMapView()
        case .projects:
            SurveyProjectsView()
        case .guides:
            GuidesView()
        case .settings:
            SettingsView()
        }
    }

    @ViewBuilder
    var label: some View {
        switch self {
        case .scan:
            Label("Escanear", systemImage: "dot.radiowaves.left.and.right")
        case .history:
            Label("Historial", systemImage: "clock.arrow.circlepath")
        case .map:
            Label("Mapa", systemImage: "map")
        case .projects:
            Label("Proyectos", systemImage: "folder")
        case .guides:
            Label("Guías", systemImage: "book.closed")
        case .settings:
            Label("Ajustes", systemImage: "gearshape")
        }
    }
}

struct AppView: View {
    @Environment(AppNavigation.self) private var appNavigation
    @Environment(AppTheme.self) private var appTheme
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearanceMode.system.rawValue

    private var selectedAppearance: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        @Bindable var appNavigation = appNavigation

        TabView(selection: $appNavigation.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tab.makeContentView()
                }
                .tabItem { tab.label }
                .tag(tab)
            }
        }
        .tint(appTheme.accent)
        .foregroundStyle(appTheme.primaryText)
        .preferredColorScheme(selectedAppearance.colorScheme ?? appTheme.suggestedColorScheme)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appTheme.background.ignoresSafeArea())
    }
}

#Preview {
    AppView()
        .environment(BluetoothScanner())
        .environment(LocationService())
        .environment(NativeWiFiService())
        .environment(SensorBridge())
        .environment(AppTheme())
        .environment(AppNavigation())
        .modelContainer(for: [DetectionRecord.self, SurveyProject.self], inMemory: true)
}
