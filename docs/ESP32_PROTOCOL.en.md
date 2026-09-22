# ESP32 sensor protocol

**[Español](ESP32_PROTOCOL.md) · English**

The sensor advertises BLE service `7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A101` and publishes UTF-8 JSON observations on characteristic `...A102`.

Experimental OTA characteristics `...A103` and `...A104` exist in code but remain disabled in distributed builds. SHA-256 verifies transferred bytes, not firmware provenance; production OTA remains gated on signing and anti-rollback.

The current app filters for the OmniPulse service UUID, subscribes to notifications, validates v1 payloads, and stages observations for review before import.

## v1 rules

- `version` is required and currently equals 1.
- Sensor name, firmware version, and hardware are optional diagnostics.
- Observation `kind` supports `wifiNetwork` and `bluetoothLE`.
- Identifiers are per-session pseudonyms and must not expose clear BSSID/MAC.
- RSSI is approximate and must not be interpreted as precise distance.
- Channel/frequency/channel width are optional Wi-Fi measurements.
- Current ESP32 firmware does not claim 6 GHz measurement.
- The iPhone may add its own authorized location when import is confirmed.

## Spectrum analysis

OmniPulse preserves channel/frequency/width when available, separates identical channel numbers across bands, excludes potential DFS channels by default in 5 GHz, and only produces 6 GHz recommendations when 6 GHz observations actually exist.
