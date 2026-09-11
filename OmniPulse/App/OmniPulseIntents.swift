import AppIntents

@available(iOS 18.0, *)
enum OmniPulseDestination: String, AppEnum {
    case scan
    case history
    case map

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Sección de OmniPulse"
    static let caseDisplayRepresentations: [OmniPulseDestination: DisplayRepresentation] = [
        .scan: "Escanear",
        .history: "Historial",
        .map: "Mapa"
    ]

    var appTab: AppTab {
        switch self {
        case .scan:
            .scan
        case .history:
            .history
        case .map:
            .map
        }
    }

    var displayName: String {
        switch self {
        case .scan:
            "Escanear"
        case .history:
            "Historial"
        case .map:
            "Mapa"
        }
    }
}

@available(iOS 18.0, *)
struct OpenOmniPulseDestinationIntent: AppIntent {
    static let title: LocalizedStringResource = "Abrir sección de OmniPulse"
    static let description = IntentDescription("Abre Escanear, Historial o Mapa en OmniPulse.")
    static let openAppWhenRun = true

    @Parameter(title: "Sección", default: .scan)
    var destination: OmniPulseDestination

    @Dependency
    private var appNavigation: AppNavigation

    init() {}

    init(destination: OmniPulseDestination) {
        self.destination = destination
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Abrir \(\.$destination) en OmniPulse")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        appNavigation.selectedTab = destination.appTab
        return .result(dialog: "Abriendo \(destination.displayName) en OmniPulse.")
    }
}

@available(iOS 18.0, *)
struct OmniPulseShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .blue }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenOmniPulseDestinationIntent(destination: .scan),
            phrases: [
                "Abrir escáner en \(.applicationName)",
                "Escanear dispositivos con \(.applicationName)"
            ],
            shortTitle: "Abrir escáner",
            systemImageName: "dot.radiowaves.left.and.right"
        )

        AppShortcut(
            intent: OpenOmniPulseDestinationIntent(destination: .history),
            phrases: [
                "Abrir historial de \(.applicationName)",
                "Mostrar detecciones en \(.applicationName)"
            ],
            shortTitle: "Abrir historial",
            systemImageName: "clock.arrow.circlepath"
        )

        AppShortcut(
            intent: OpenOmniPulseDestinationIntent(destination: .map),
            phrases: [
                "Abrir mapa de \(.applicationName)",
                "Mostrar mapa en \(.applicationName)"
            ],
            shortTitle: "Abrir mapa",
            systemImageName: "map"
        )
    }

}
