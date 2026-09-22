# Architecture

**[Español](ARCHITECTURE.md) · English**

## Goal

OmniPulse records nearby radio observations locally and traceably. The iPhone is the BLE central and optional location source. ESP32/ESP8266 sensors extend coverage with aggregated observations without turning the phone into a low-level Wi-Fi scanner.

```text
iPhone
  CoreBluetooth ──> BluetoothScanner ─┐
  CoreLocation ──> LocationService ───┼─> SwiftUI ─> SwiftData ─> History / Map
  ESP32 sensor ───> JSON over BLE ────┤
  ESP8266 ────────> JSON over HTTP ───┘
                         │
                         ├─> macOS companion
                         └─> WatchConnectivity ─> Apple Watch
```

## Layers

- `Services`: permissions, radio, connectivity, exports, and platform APIs.
- `Models`: discovery data, persistence, projects, and sensor contracts.
- `Views`: UI and explicit user actions.
- `OmniPulseMac`: native macOS scan/history/map/projects/firmware/settings surfaces.
- `OmniPulseWatch`: remote controls and recent-detection summaries.
- `firmware`: sensor implementations matching the documented contracts.

## Design decisions

- iOS 17 minimum for SwiftData and modern observation.
- Local-first history; no OmniPulse cloud backend.
- Location only under system permission and only in flows that need it.
- iPhone BLE scanning is not presented as desktop-style continuous background monitoring.
- Wi-Fi observations come through authorized sensors because ordinary iOS apps do not expose a general desktop-equivalent Wi-Fi scan API.
- CSV/PDF export is user-initiated.
- App Intents, macOS, and watchOS are part of the current codebase.

## Follow-ups

- Harden signed firmware/anti-rollback before enabling BLE OTA in distributed builds.
- Add WidgetKit only after shared-storage, retention, and privacy rules are defined.
- Keep physical BLE/location/sensor/WatchConnectivity acceptance as a separate release gate from CI.
