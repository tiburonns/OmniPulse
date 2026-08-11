import SwiftUI

struct MacFirmwareView: View {
    @Environment(AppTheme.self) private var appTheme

    private let firmwares = [
        ("ESP32 DevKit", "OmniPulse-ESP32"),
        ("ESP32-CAM", "OmniPulse-ESP32CAM"),
        ("ESP32-S3", "OmniPulse-ESP32S3"),
        ("XIAO ESP32S3 / Sense", "OmniPulse-XIAO-ESP32S3"),
        ("ESP32-C5 DevKitC-1 (2.4/5 GHz)", "OmniPulse-ESP32C5"),
        ("NodeMCU ESP8266 (2.4 GHz)", "OmniPulse-ESP8266"),
        ("Wemos / LOLIN D1 mini (2.4 GHz)", "OmniPulse-D1Mini")
    ]

    var body: some View {
        List {
            Section("Firmware incluido") {
                ForEach(firmwares, id: \.1) { board, filename in
                    HStack {
                        Image(systemName: "memorychip.fill")
                            .foregroundStyle(appTheme.accent)
                        VStack(alignment: .leading) {
                            Text(board)
                            Text("\(filename).bin")
                                .font(.caption.monospaced())
                                .foregroundStyle(appTheme.secondaryText)
                        }
                        Spacer()
                        if let url = Bundle.main.url(forResource: filename, withExtension: "bin") {
                            ShareLink(item: url) { Label("Guardar", systemImage: "square.and.arrow.down") }
                        }
                    }
                }
            }
            Section("Flasheo") {
                Text("Conecta la placa por USB, abre Terminal y usa esptool o PlatformIO. La aplicación conserva los binarios para compartirlos o guardarlos en la Mac.")
                Text("Después de instalar por USB el firmware 1.3.0, las siguientes versiones pueden enviarse por Bluetooth desde el detalle del sensor conectado.")
                    .foregroundStyle(appTheme.secondaryText)
            }
        }
        .navigationTitle("Firmware de sensores")
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }
}
