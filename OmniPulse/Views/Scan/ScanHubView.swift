import SwiftData
import SwiftUI

private enum PrimaryScanType: String, CaseIterable, Identifiable {
    case iPhoneBLE
    case espWiFi
    case espBLE

    var id: String { rawValue }

    var title: String {
        switch self {
        case .iPhoneBLE: "BLE iPhone"
        case .espWiFi: "Wi-Fi ESP32"
        case .espBLE: "BLE ESP32"
        }
    }

    var icon: String {
        switch self {
        case .iPhoneBLE, .espBLE: "dot.radiowaves.left.and.right"
        case .espWiFi: "wifi"
        }
    }
}

struct ScanHubView: View {
    @Environment(AppTheme.self) private var appTheme
    @AppStorage("primaryScanType") private var primaryScanType = PrimaryScanType.iPhoneBLE.rawValue
    @AppStorage("activeSurveyProjectID") private var activeProjectID = ""
    @Query(sort: \SurveyProject.updatedAt, order: .reverse) private var projects: [SurveyProject]

    private var activeProject: SurveyProject? {
        guard let id = UUID(uuidString: activeProjectID) else { return nil }
        return projects.first { $0.id == id }
    }

    private var selection: PrimaryScanType {
        if primaryScanType == "wifi" { return .espWiFi }
        return PrimaryScanType(rawValue: primaryScanType) ?? .iPhoneBLE
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tipo de escaneo", selection: $primaryScanType) {
                ForEach(PrimaryScanType.allCases) { type in
                    Label(type.title, systemImage: type.icon)
                        .tag(type.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)

            if let activeProject {
                Label("Guardando en \(activeProject.name)", systemImage: "folder.fill.badge.checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(appTheme.success)
                    .padding(.bottom, 8)
            }

            Divider()

            switch selection {
            case .iPhoneBLE:
                ScanView()
            case .espWiFi:
                SensorImportView(observationFilter: .wifiNetwork)
            case .espBLE:
                SensorImportView(observationFilter: .bluetoothLE)
            }
        }
        .background(appTheme.background)
        .onAppear {
            if primaryScanType == "wifi" {
                primaryScanType = PrimaryScanType.espWiFi.rawValue
            } else if primaryScanType == "bluetooth" {
                primaryScanType = PrimaryScanType.iPhoneBLE.rawValue
            }
        }
    }
}
