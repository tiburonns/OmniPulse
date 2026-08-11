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

@available(iOS 26.0, *)
struct OpenOmniPulseDestinationIntent: AppIntent {
    static let title: LocalizedStringResource = "Abrir sección de OmniPulse"
    static let description = IntentDescription("Abre Escanear, Historial o Mapa en OmniPulse.")
    static let supportedModes: IntentModes = [.foreground]

    @Parameter(title: "Sección", default: .scan)
    var destination: OmniPulseDestination

    @Dependency
    private var appNavigation: AppNavigation

    static var parameterSummary: some ParameterSummary {
        Summary("Abrir \(\.$destination) en OmniPulse")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        appNavigation.selectedTab = destination.appTab
        return .result(dialog: "Abriendo \(destination.displayName) en OmniPulse.")
    }
}

@available(iOS 26.0, *)
struct OmniPulseShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .blue }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: open(OmniPulseDestination.scan),
            phrases: [
                "Abrir escáner en \(.applicationName)",
                "Escanear dispositivos con \(.applicationName)"
            ],
            shortTitle: "Abrir escáner",
            systemImageName: "dot.radiowaves.left.and.right"
        )

        AppShortcut(
            intent: open(OmniPulseDestination.history),
            phrases: [
                "Abrir historial de \(.applicationName)",
                "Mostrar detecciones en \(.applicationName)"
            ],
            shortTitle: "Abrir historial",
            systemImageName: "clock.arrow.circlepath"
        )

        AppShortcut(
            intent: open(OmniPulseDestination.map),
            phrases: [
                "Abrir mapa de \(.applicationName)",
                "Mostrar mapa en \(.applicationName)"
            ],
            shortTitle: "Abrir mapa",
            systemImageName: "map"
        )
    }

    private static func open(_ destination: OmniPulseDestination) -> OpenOmniPulseDestinationIntent {
        var intent = OpenOmniPulseDestinationIntent()
        intent.destination = destination
        return intent
    }
}
