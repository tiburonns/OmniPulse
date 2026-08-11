import SwiftData
import SwiftUI

@main
@MainActor
struct OmniPulseMacApp: App {
    @State private var bluetoothScanner: BluetoothScanner
    @State private var locationService: LocationService
    @State private var sensorBridge: SensorBridge
    @State private var appTheme = AppTheme()

    init() {
        let locationService = LocationService()
        let bluetoothScanner = BluetoothScanner()
        let sensorBridge = SensorBridge()
        bluetoothScanner.useLocationProvider { [weak locationService] in
            locationService?.freshLocation()
        }
        sensorBridge.useLocationProvider { [weak locationService] in
            locationService?.freshLocation()
        }
        _bluetoothScanner = State(initialValue: bluetoothScanner)
        _locationService = State(initialValue: locationService)
        _sensorBridge = State(initialValue: sensorBridge)
    }

    var body: some Scene {
        WindowGroup {
            MacRootView()
                .environment(bluetoothScanner)
                .environment(locationService)
                .environment(sensorBridge)
                .environment(appTheme)
        }
        .defaultSize(width: 1120, height: 760)
        .modelContainer(for: [DetectionRecord.self, SurveyProject.self])

        Settings {
            MacSettingsView()
                .environment(appTheme)
                .frame(width: 520, height: 560)
        }
    }
}
