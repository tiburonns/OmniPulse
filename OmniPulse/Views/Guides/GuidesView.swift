import SwiftUI

struct GuidesView: View {
    @Environment(AppTheme.self) private var appTheme
    var body: some View {
        List {
            Section("Primeros pasos") {
                NavigationLink("Escanear Bluetooth con el iPhone") {
                    GuideDetailView(
                        title: "Escaneo Bluetooth",
                        steps: [
                            "Abre Escanear y elige Bluetooth.",
                            "Pulsa Iniciar escaneo BLE y acepta el permiso de Bluetooth.",
                            "Usa Detección para mantener el orden inicial o Vehículo para ordenar por señal.",
                            "Guarda únicamente las observaciones que quieras conservar."
                        ]
                    )
                }
                NavigationLink("Escanear Wi-Fi con un ESP32") {
                    GuideDetailView(
                        title: "Escaneo Wi-Fi",
                        steps: [
                            "Carga el firmware OmniPulse en una placa compatible.",
                            "Alimenta el ESP32 y abre Escanear → Wi-Fi.",
                            "Pulsa Buscar sensor ESP32 y espera la conexión Bluetooth.",
                            "Abre cada lote recibido y pulsa Importar para guardarlo."
                        ]
                    )
                }
                NavigationLink("Escanear Wi-Fi con ESP8266 / D1 mini") {
                    GuideDetailView(
                        title: "ESP8266 por Wi-Fi local",
                        steps: [
                            "Carga el firmware OmniPulse ESP8266 en la placa.",
                            "En Ajustes del iPhone conéctate a OmniPulse-8266-XXXX. La contraseña es omniXXXX usando los cuatro caracteres finales de la red.",
                            "Abre OmniPulse → Escanear → Wi-Fi y pulsa Leer ESP8266 / D1 mini.",
                            "Guarda el lote recibido. La placa solo detecta redes de 2.4 GHz y no puede escanear BLE."
                        ]
                    )
                }
            }

            Section("Flashear firmware") {
                NavigationLink("XIAO ESP32S3 / Sense") {
                    FlashGuideView(
                        boardName: "XIAO ESP32S3 / Sense",
                        environment: "seeed_xiao_esp32s3",
                        chip: "esp32s3",
                        firmwareName: "OmniPulse-XIAO-ESP32S3",
                        bootInstructions: "Mantén BOOT, conecta el USB-C y suelta BOOT. También puedes mantener BOOT, pulsar RESET y soltar BOOT."
                    )
                }
                NavigationLink("ESP32-S3 DevKitC-1") {
                    FlashGuideView(
                        boardName: "ESP32-S3 DevKitC-1",
                        environment: "esp32-s3-devkitc-1",
                        chip: "esp32s3",
                        firmwareName: "OmniPulse-ESP32S3",
                        bootInstructions: "Mantén BOOT, pulsa EN/RESET y suelta BOOT cuando comience la conexión."
                    )
                }
                NavigationLink("ESP32 DevKit / DevKitC") {
                    FlashGuideView(
                        boardName: "ESP32 DevKit / DevKitC",
                        environment: "esp32dev",
                        chip: "esp32",
                        firmwareName: "OmniPulse-ESP32",
                        bootInstructions: "Normalmente PlatformIO reinicia la placa. Si falla, mantén BOOT durante Connecting y suéltalo al iniciar la escritura."
                    )
                }
                NavigationLink("AI-Thinker ESP32-CAM") {
                    FlashGuideView(
                        boardName: "AI-Thinker ESP32-CAM",
                        environment: "esp32cam",
                        chip: "esp32",
                        firmwareName: "OmniPulse-ESP32CAM",
                        bootInstructions: "Conecta GPIO0 a GND y pulsa RESET para entrar al modo de carga. Cuando termine, desconecta GPIO0 de GND y vuelve a pulsar RESET. Si usas una base ESP32-CAM-MB, normalmente los botones IO0 y RESET realizan estos pasos."
                    )
                }
                NavigationLink("Wemos / LOLIN D1 mini") {
                    FlashGuideView(
                        boardName: "Wemos / LOLIN D1 mini (ESP8266)",
                        environment: "d1_mini",
                        chip: "esp8266",
                        firmwareName: "OmniPulse-D1Mini",
                        bootInstructions: "Conecta el D1 mini por USB con un cable de datos. Normalmente PlatformIO controla el modo de carga automáticamente.",
                        sourceFolder: "esp8266-omnipulse"
                    )
                }
                NavigationLink("NodeMCU ESP8266") {
                    FlashGuideView(
                        boardName: "NodeMCU ESP8266",
                        environment: "nodemcuv2",
                        chip: "esp8266",
                        firmwareName: "OmniPulse-ESP8266",
                        bootInstructions: "Conecta la placa por USB. Si no entra en carga, mantén FLASH, pulsa RESET, suelta RESET y después suelta FLASH.",
                        sourceFolder: "esp8266-omnipulse"
                    )
                }
                NavigationLink("¿Se puede flashear desde el iPhone?") {
                    IPhoneFlashingGuideView()
                }
            }

            Section("Participa") {
                NavigationLink("Sugerencias y comentarios") {
                    FeedbackView()
                }
            }
        }
        .navigationTitle("Guías")
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }
}

private struct GuideDetailView: View {
    @Environment(AppTheme.self) private var appTheme
    let title: String
    let steps: [String]

    var body: some View {
        List {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(appTheme.accent, in: Circle())
                    Text(step)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }
}

private struct FlashGuideView: View {
    @Environment(AppTheme.self) private var appTheme
    let boardName: String
    let environment: String
    let chip: String
    let firmwareName: String
    let bootInstructions: String
    var sourceFolder = "esp32-omnipulse"

    private var buildCommand: String { "pio run -e \(environment)" }
    private var uploadCommand: String { "pio run -e \(environment) -t upload" }
    private var firmwareURL: URL? { Bundle.main.url(forResource: firmwareName, withExtension: "bin") }
    private var binaryUploadCommand: String {
        "python3 -m esptool --chip \(chip) --port /dev/cu.usbmodemXXXX write_flash 0x0 \(firmwareName).bin"
    }

    var body: some View {
        List {
            Section("Opción rápida: firmware incluido") {
                if let firmwareURL {
                    ShareLink(item: firmwareURL) {
                        Label("Guardar o compartir \(firmwareName).bin", systemImage: "square.and.arrow.down")
                    }
                } else {
                    Label("Firmware no encontrado en esta compilación", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(appTheme.warning)
                }

                Text("En el iPhone, guarda el archivo en Archivos o envíalo a tu Mac con AirDrop. En la Mac abre Terminal, entra a la carpeta donde lo guardaste y ejecuta:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                commandRow("Abrir Descargas", command: "cd ~/Downloads")
                commandRow("Instalar esptool una vez", command: "python3 -m pip install esptool")
                commandRow("Flashear el archivo", command: binaryUploadCommand)
                Text("Sustituye /dev/cu.usbmodemXXXX por el puerto que muestre tu placa.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Opción desarrollador: compilar desde GitHub") {
                commandRow("Descargar el proyecto", command: "git clone https://github.com/tiburonns/OmniPulse.git")
                commandRow("Entrar a la carpeta del firmware", command: "cd OmniPulse/firmware/\(sourceFolder)")
                Text("Estos comandos se ejecutan en Terminal en una Mac, PC o Linux.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Necesitas para compilar") {
                Label("Mac, PC o Linux con PlatformIO", systemImage: "laptopcomputer")
                Label("Cable USB de datos", systemImage: "cable.connector")
                Label("Proyecto firmware/esp32-omnipulse", systemImage: "folder")
            }

            Section("Modo de carga") {
                Text(bootInstructions)
            }

            Section("Comandos desde la carpeta del firmware") {
                commandRow("Compilar", command: buildCommand)
                commandRow("Flashear", command: uploadCommand)
            }

            Section("Después") {
                if chip == "esp8266" {
                    Text("Pulsa RESET y conecta el iPhone a OmniPulse-8266-XXXX. Usa omniXXXX como contraseña, tomando XXXX del final de la red, y elige Escanear → Wi-Fi → Leer ESP8266 / D1 mini.")
                } else {
                    Text("Pulsa RESET una vez, abre OmniPulse y elige Escanear → Wi-Fi → Buscar sensor ESP32.")
                }
            }

            Section {
                Text("Flashear reemplaza el firmware actual de la placa. En XIAO Sense y ESP32-CAM también sustituye temporalmente el firmware de cámara de fábrica.")
                    .foregroundStyle(appTheme.warning)
            }
        }
        .navigationTitle(boardName)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(appTheme.background)
    }

    private func commandRow(_ label: String, command: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.headline)
            Text(command)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
        }
    }
}

private struct IPhoneFlashingGuideView: View {
    var body: some View {
        List {
            Section("USB-C") {
                Text("OmniPulse no puede flashear directamente un ESP32 por el USB-C del iPhone. iOS no ofrece a una app común acceso al puerto serie USB genérico que usa esptool.")
            }
            Section("Alternativa recomendada") {
                Text("El flasheo de las compilaciones distribuidas se realiza por USB desde Mac, PC o Linux. La OTA por Bluetooth permanece desactivada hasta incorporar firma de firmware, anti-rollback y recuperación segura.")
            }
        }
        .navigationTitle("Flasheo desde iPhone")
        .navigationBarTitleDisplayMode(.inline)
    }
}
