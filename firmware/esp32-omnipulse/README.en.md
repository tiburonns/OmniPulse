# OmniPulse sensor for ESP32

**[Español](README.md) · English**

Firmware 1.4 for ESP32, ESP32-S3, ESP32-C5, and Seeed Studio XIAO ESP32S3/Sense. It advertises the OmniPulse BLE service and sends JSON v1 observations with uptime/free-memory diagnostics. It scans visible Wi-Fi networks and BLE advertisements; it does not capture traffic, associate with networks, or transmit clear BSSID/MAC addresses.

Build with PlatformIO:

```bash
cd firmware/esp32-omnipulse
pio run
pio run -t upload
pio device monitor
```

Included environments cover ESP32 DevKit/DevKitC, ESP32-CAM, ESP32-S3, XIAO ESP32S3/Sense, ESP32-C5 and additional profiles listed in `platformio.ini`.

The code contains an experimental BLE OTA path with SHA-256 transfer verification and rollback-oriented boot validation, but distributed OmniPulse builds keep OTA disabled until signed firmware and anti-rollback are production-ready.

Before real deployment, add BLE authentication/encryption, device authorization, a physical capture indicator, signed firmware update, and the controls documented in `../../docs/SECURITY.en.md`.
