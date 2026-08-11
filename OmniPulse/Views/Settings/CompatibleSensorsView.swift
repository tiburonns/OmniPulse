import SwiftUI

private struct SupportedSensor: Identifiable {
    let id: String
    let name: String
    let detail: String
    let systemImage: String
}

struct CompatibleSensorsView: View {
    @Environment(AppTheme.self) private var appTheme
    private let includedProfiles = [
        SupportedSensor(
            id: "esp32dev",
            name: "ESP32 DevKit / DevKitC",
            detail: "Perfil PlatformIO: esp32dev",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "esp32cam",
            name: "AI-Thinker ESP32-CAM",
            detail: "Perfil PlatformIO: esp32cam; OmniPulse no utiliza la cámara.",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(id: "nodemcu-32s", name: "NodeMCU-32S", detail: "Perfil PlatformIO: nodemcu-32s", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "wemos-d1-mini32", name: "WEMOS D1 Mini ESP32", detail: "Perfil PlatformIO: wemos_d1_mini32", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "m5stack-atom", name: "M5Stack ATOM Lite / Matrix", detail: "Perfil PlatformIO: m5stack-atom", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "firebeetle2-esp32e", name: "DFRobot FireBeetle 2 ESP32-E", detail: "Perfil PlatformIO: dfrobot_firebeetle2_esp32e", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "lilygo-t-display", name: "LilyGO T-Display", detail: "Perfil PlatformIO: lilygo-t-display", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "arduino-nano-esp32", name: "Arduino Nano ESP32", detail: "Perfil PlatformIO: arduino_nano_esp32", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "esp32thing-plus", name: "SparkFun ESP32 Thing Plus", detail: "Perfil PlatformIO: esp32thing_plus", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "adafruit-feather-esp32-v2", name: "Adafruit Feather ESP32 V2", detail: "Perfil PlatformIO: adafruit_feather_esp32_v2", systemImage: "checkmark.seal.fill"),
        SupportedSensor(
            id: "esp32-s3-devkitc-1",
            name: "ESP32-S3 DevKitC-1",
            detail: "Perfil PlatformIO: esp32-s3-devkitc-1",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "seeed-xiao-esp32s3",
            name: "Seeed Studio XIAO ESP32S3",
            detail: "Perfil PlatformIO: seeed_xiao_esp32s3",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "seeed-xiao-esp32s3-sense",
            name: "Seeed Studio XIAO ESP32S3 Sense",
            detail: "Usa el perfil seeed_xiao_esp32s3; conecta su antena externa.",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "esp32-c3-devkitm-1",
            name: "ESP32-C3 DevKitM-1",
            detail: "Perfil: esp32-c3-devkitm-1",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "esp32-c5-devkitc-1",
            name: "ESP32-C5 DevKitC-1",
            detail: "Perfil: esp32-c5-devkitc-1; escaneo Wi-Fi de 2.4 y 5 GHz.",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "seeed-xiao-esp32c3",
            name: "Seeed Studio XIAO ESP32C3",
            detail: "Perfil: seeed_xiao_esp32c3",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "adafruit-feather-esp32s3",
            name: "Adafruit Feather ESP32-S3",
            detail: "Perfil: adafruit_feather_esp32s3",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "lilygo-t-display-s3",
            name: "LilyGO T-Display-S3",
            detail: "Perfil: lilygo-t-display-s3",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "m5stack-atoms3",
            name: "M5Stack AtomS3",
            detail: "Perfil: m5stack-atoms3",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "m5stack-cores3",
            name: "M5Stack CoreS3",
            detail: "Perfil: m5stack-cores3",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(
            id: "unexpected-maker-feathers3",
            name: "Unexpected Maker FeatherS3",
            detail: "Perfil: um_feathers3",
            systemImage: "checkmark.seal.fill"
        ),
        SupportedSensor(id: "esp8266-nodemcu", name: "NodeMCU ESP8266", detail: "Perfil: nodemcuv2; Wi-Fi 2.4 GHz por red local, sin BLE.", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "wemos-d1-mini-8266", name: "Wemos / LOLIN D1 mini", detail: "Perfil: d1_mini; Wi-Fi 2.4 GHz por red local, sin BLE.", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "wemos-d1-mini-lite", name: "Wemos D1 mini Lite", detail: "Perfil: d1_mini_lite; Wi-Fi 2.4 GHz, sin BLE.", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "wemos-d1-mini-pro", name: "Wemos D1 mini Pro", detail: "Perfil: d1_mini_pro; Wi-Fi 2.4 GHz, sin BLE.", systemImage: "checkmark.seal.fill"),
        SupportedSensor(id: "esp-01-1m", name: "ESP-01 / ESP-01S (1 MB)", detail: "Perfil: esp01_1m; requiere adaptador USB-serie y alimentación estable de 3.3 V.", systemImage: "checkmark.seal.fill")
    ]

    private let architectureCompatible = [
        SupportedSensor(id: "esp32-c6-devkitc-1", name: "ESP32-C6 DevKitC-1", detail: "Hardware apto; requiere una versión de Arduino/PlatformIO con soporte C6.", systemImage: "clock.badge.exclamationmark.fill"),
        SupportedSensor(id: "seeed-xiao-esp32c6", name: "Seeed Studio XIAO ESP32C6", detail: "Hardware apto; perfil pendiente en la versión fijada del firmware.", systemImage: "clock.badge.exclamationmark.fill"),
        SupportedSensor(id: "other-esp32", name: "Otras placas ESP32", detail: "Requieren Wi-Fi, BLE y un perfil PlatformIO adecuado.", systemImage: "wrench.and.screwdriver.fill")
    ]

    var body: some View {
        List {
            Section("Perfiles incluidos") {
                ForEach(includedProfiles) { sensor in
                    sensorRow(sensor, color: appTheme.success)
                }
            }

            Section("Compatibles por arquitectura") {
                ForEach(architectureCompatible) { sensor in
                    sensorRow(sensor, color: appTheme.warning)
                }
            }

            Section("No compatibles") {
                Label("ESP32-S2: no tiene Bluetooth", systemImage: "xmark.circle.fill")
                Label("XIAO nRF52840 Sense: no tiene Wi-Fi", systemImage: "xmark.circle.fill")
            }
            .foregroundStyle(.secondary)

            Section("Requisito") {
                Text("La placa debe ejecutar el firmware OmniPulse. Los ESP32 se conectan por BLE; ESP8266, NodeMCU y D1 mini crean una red Wi-Fi local para entregar sus lotes. Tener una placa compatible no basta sin cargar el firmware correspondiente.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Compatibilidad")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }

    private func sensorRow(_ sensor: SupportedSensor, color: Color) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(sensor.name)
                Text(sensor.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: sensor.systemImage)
                .foregroundStyle(color)
        }
    }
}
