# OmniPulse

[Español](README.md) · **English**

OmniPulse is a universal app for iPhone, iPad, Mac, and Apple Watch that records Bluetooth Low Energy (BLE) discoveries, analyzes Wi-Fi networks through authorized external sensors, and stores the location associated with each observation.

[Download OmniPulse 1.0.1](https://github.com/tiburonns/OmniPulse/releases/tag/v1.0.1) · [AltStore source](https://raw.githubusercontent.com/tiburonns/OmniPulse/main/source.json) · [Install with AltStore/Sideloadly](docs/ALTSTORE.md) · [Build and install with Xcode](docs/COMPILAR_EN_XCODE.md)

## Project goals and use cases

OmniPulse is a local-first toolkit for observing and documenting radio signals in spaces, networks, and devices that you own or are authorized to assess.

Its primary use case is **Wi-Fi site surveying and coverage/channel analysis**. ESP32 and ESP8266 boards act as external survey sensors, collect nearby Wi-Fi measurements, and send reviewable batches to the Apple app. OmniPulse can then organize those measurements into projects, associate them with geographic locations or floor plans, analyze 2.4/5 GHz channel usage, and generate reports.

**BLE discovery and location mapping are also major parts of the project**, rather than secondary extras. The app can discover nearby BLE advertisements directly through CoreBluetooth, identify common manufacturer and beacon formats, preserve observations in a local history, and place them on maps or floor plans. BLE is also used to connect to compatible ESP32 sensors, receive scan batches, and perform sensor firmware updates.

OmniPulse is not intended for packet interception or offensive security work. The firmware does not decrypt networks, inspect payload traffic, inject packets, or transmit raw MAC addresses.

## Main features

- BLE scanning on iPhone through CoreBluetooth.
- Optional location association using CoreLocation with When In Use permission.
- Local SwiftData history, geographic maps, and floor plans.
- Survey projects with 2.4/5 GHz channel analysis and recommendations.
- User-initiated PDF reports and CSV exports.
- BLE manufacturer, category, iBeacon, and Eddystone identification.
- Simultaneous connections to up to eight ESP32 sensors and BLE OTA updates.
- Local Wi-Fi support for NodeMCU ESP8266, Wemos/LOLIN D1 mini, and similar boards.
- Included firmware for ESP32, ESP32-CAM, ESP32-S3, XIAO ESP32S3/Sense, ESP32-C5, ESP8266, and D1 mini.
- System themes, bundled themes, and a custom palette editor.
- Siri Shortcuts on iOS 18+ for opening Scan, History, or Map.

BLE advertisement identifiers are converted into ephemeral per-session pseudonyms. Use OmniPulse only in spaces, networks, and devices that you administer or have permission to survey.

## Requirements

- macOS with Xcode 16 or later.
- iOS 17 or later on a physical iPhone for Bluetooth and location testing.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`.

## Open the app in Xcode

See the [complete Spanish-language guide for cloning, signing, and installing OmniPulse on an iPhone](docs/COMPILAR_EN_XCODE.md), including setup for free Apple developer accounts.

```bash
brew install xcodegen
cd OmniPulse
xcodegen generate --spec project.yml
open OmniPulse.xcodeproj
```

Select your own signing team and change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` if `com.tiburonns.OmniPulse` is not available. Run `xcodegen generate` again after changing project files.

The repository does not include a Team ID, certificates, or provisioning profiles. Each developer must select their own development team.

## AltStore and Sideloadly

The public IPA is an iPhone/iPad variant without the Apple Watch companion bundle. This avoids a signing crash in AltStore 2.2.1 caused by the watchOS `arm64_32` executable. The complete iPhone + Apple Watch version remains available when building from Xcode and for future TestFlight or App Store distribution.

See the [installation and troubleshooting guide](docs/ALTSTORE.md). The public package is built reproducibly with `script/build_altstore_ipa.sh` and is distributed without certificates, provisioning profiles, or a Team ID.

## Repository layout

```text
OmniPulse/                  SwiftUI app
OmniPulseTests/             Basic unit tests
docs/                       Architecture, local data model, protocol, and security
firmware/esp32-omnipulse/   PlatformIO ESP32 sensor project
firmware/esp8266-omnipulse/ PlatformIO project for NodeMCU and D1 mini
project.yml                 Reproducible XcodeGen project definition
```

## Integration status

The app supports BLE discovery, local persistence, GATT connections to ESP32 sensors, and local HTTP reception from ESP8266 sensors. Every imported scan batch is presented for review first. The iOS, macOS, and watchOS targets are part of the same reproducible XcodeGen project. All functionality is free, with no paid plan or subscription.

## Privacy, security, and license

See [Privacy](docs/PRIVACY.md), [Security](SECURITY.md), and [License](LICENSE). The source code is published for inspection and evaluation; no general permission is granted to redistribute it or commercialize derivative works.
