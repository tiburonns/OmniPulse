import Foundation

struct FirmwarePackage: Identifiable, Hashable, Sendable {
    let id: String
    let boardName: String
    let resourceName: String
    let version: String
    let supportedBands: String
    let hardwareTokens: [String]

    func bundledURL(in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: resourceName, withExtension: "bin")
    }
}

enum FirmwareCatalog {
    static let currentVersion = "1.3.0"

    static let packages: [FirmwarePackage] = [
        FirmwarePackage(
            id: "esp32-c5",
            boardName: "ESP32-C5 DevKitC-1",
            resourceName: "OmniPulse-ESP32C5",
            version: currentVersion,
            supportedBands: "2.4 y 5 GHz",
            hardwareTokens: ["ESP32-C5", "esp32-c5"]
        ),
        FirmwarePackage(
            id: "xiao-s3",
            boardName: "XIAO ESP32S3 / Sense",
            resourceName: "OmniPulse-XIAO-ESP32S3",
            version: currentVersion,
            supportedBands: "2.4 GHz",
            hardwareTokens: ["XIAO-ESP32S3", "XIAO ESP32S3", "XIAO ESP32S3 Sense"]
        ),
        FirmwarePackage(
            id: "esp32-s3",
            boardName: "ESP32-S3",
            resourceName: "OmniPulse-ESP32S3",
            version: currentVersion,
            supportedBands: "2.4 GHz",
            hardwareTokens: ["ESP32-S3", "ESP32S3"]
        ),
        FirmwarePackage(
            id: "esp32-cam",
            boardName: "ESP32-CAM",
            resourceName: "OmniPulse-ESP32CAM",
            version: currentVersion,
            supportedBands: "2.4 GHz",
            hardwareTokens: ["ESP32-CAM", "AI-Thinker"]
        ),
        FirmwarePackage(
            id: "esp32",
            boardName: "ESP32 DevKit y compatibles",
            resourceName: "OmniPulse-ESP32",
            version: currentVersion,
            supportedBands: "2.4 GHz",
            hardwareTokens: ["ESP32", "DevKit", "NodeMCU", "WEMOS", "M5Stack"]
        )
    ]

    static func package(for hardware: String?) -> FirmwarePackage? {
        guard let hardware else { return nil }
        return packages.first { package in
            package.hardwareTokens.contains { hardware.localizedCaseInsensitiveContains($0) }
        }
    }

    static func isUpdateAvailable(installedVersion: String?, package: FirmwarePackage) -> Bool {
        guard let installedVersion else { return true }
        return installedVersion.compare(package.version, options: .numeric) == .orderedAscending
    }
}
