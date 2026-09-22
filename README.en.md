# OmniPulse

**English · [Español](README.md)**

OmniPulse is a universal iPhone, iPad, Mac, and Apple Watch application for recording nearby Bluetooth Low Energy (BLE) discoveries, analyzing Wi-Fi observations supplied by authorized sensors, and keeping the location associated with each saved observation.

> **Current development version on `main`: 1.2.2 (build 6).** The latest distributed release remains 1.2.0 until a newer release is published.

[Download OmniPulse 1.2.0](https://github.com/tiburonns/OmniPulse/releases/tag/v1.2.0) · [AltStore source](https://raw.githubusercontent.com/tiburonns/OmniPulse/main/source.json) · [Install with AltStore/Sideloadly](docs/ALTSTORE.en.md) · [Build and install with Xcode](docs/COMPILAR_EN_XCODE.en.md)

## Main features

- BLE scanning on iPhone with CoreBluetooth.
- Optional `When In Use` location through CoreLocation.
- Local SwiftData history, geographic map, and floor plans.
- Survey projects with spectrum analysis by frequency/channel width and conservative 2.4/5/6 GHz recommendations. 6 GHz analysis requires a source that can actually report that band.
- User-initiated PDF reports and CSV export.
- BLE manufacturer/category identification plus iBeacon and Eddystone recognition.
- Up to eight simultaneous ESP32 sensor connections. Experimental BLE OTA remains disabled in distributed builds until signed firmware and anti-rollback are production-ready.
- Local Wi-Fi support for NodeMCU ESP8266, Wemos/LOLIN D1 mini, and similar boards.
- Bundled firmware for ESP32, ESP32-CAM, ESP32-S3, XIAO ESP32S3/Sense, ESP32-C5, ESP8266, and D1 mini. Current profiles do not claim 6 GHz scanning; ESP32-C5 can contribute 5 GHz observations when the environment/hardware exposes them.
- Native macOS and Apple Watch companions in the same XcodeGen project. watchOS can start/stop iPhone scanning, toggle Vehicle mode, save the current batch, and inspect recent detections.
- Automatic appearance, six dark themes, eight light themes, and a custom palette editor.
- Siri shortcuts on iOS 18+ for opening Scan, History, or Map.

The firmware does not inspect traffic, decrypt networks, or transmit MAC addresses in clear text. BLE advertisement identifiers are converted into per-session ephemeral pseudonyms. Use OmniPulse only on spaces, networks, and devices you manage or are authorized to inspect.

## Requirements

- macOS with Xcode 16 or later.
- iOS 17 or later on a physical iPhone for Bluetooth and location testing.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the project from `project.yml`.

## Build

```bash
brew install xcodegen
cd OmniPulse
xcodegen generate --spec project.yml
open OmniPulse.xcodeproj
```

Select your own development team and use a unique bundle identifier when signing. No Team ID, certificate, or provisioning profile is committed to this repository.

## AltStore and Sideloadly

The public IPA is an iPhone/iPad sideloading variant without the Apple Watch companion bundle. This avoids the AltStore 2.2.1 signing crash on the Watch `arm64_32` executable. The complete iPhone + Apple Watch product remains available when building with Xcode and for future TestFlight/App Store distribution.

See [AltStore/Sideloadly](docs/ALTSTORE.en.md) and [Xcode installation](docs/COMPILAR_EN_XCODE.en.md).

## Current integration status

The app performs BLE discovery, local persistence, GATT communication with ESP32 sensors, and local HTTP ingestion from ESP8266 sensors. Every received batch is presented for review before import. iOS, macOS, and watchOS targets are generated from the same XcodeGen project.

Hardware-dependent Bluetooth, location, sensor, and Apple Watch paths require real-device acceptance. CI validates reproducible build/test paths but does not replace physical testing.

All features are free; there is no paid plan or subscription.

## Privacy, security, and license

See [Privacy](docs/PRIVACY.en.md), [Security](SECURITY.en.md), and [License](LICENSE).
