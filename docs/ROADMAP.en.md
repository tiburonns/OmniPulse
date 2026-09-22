# Roadmap

**[Español](ROADMAP.md) · English**

## Local foundation

- [x] SwiftUI Scan, History, Map, and Settings.
- [x] Foreground iPhone BLE scanning.
- [x] Optional location and local SwiftData persistence.
- [x] Saved-observation map.
- [x] ESP32 contract and firmware.

## Authorized sensors

- [x] ESP32 discovery/connection by service UUID.
- [x] GATT notification subscription and JSON v1 validation.
- [x] Pre-import review.
- [ ] Complete physical acceptance across ESP32 variants and permission states.

## Daily utility

- [x] Spectrum analysis with frequency/channel width and conservative DFS handling.
- [x] Search/source filters.
- [x] Explicit CSV export and PDF reports.
- [x] Configurable retention.
- [ ] User-justified geofences/local alerts.

## Apple surfaces

- [ ] WidgetKit aggregate statistics.
- [x] App Intents for Scan/History/Map navigation.
- [x] Apple Watch companion for iPhone scan controls and recent detections.
- [x] Native macOS companion surfaces.

## Release gates

Physical iPhone testing, reviewed permission copy, privacy review, battery evaluation, deletion/retention tests, and physical sensor/Watch acceptance remain required before broader distribution.
