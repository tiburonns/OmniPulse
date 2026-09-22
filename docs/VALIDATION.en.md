# Delivery validation

**[Español](VALIDATION.md) · English**

OmniPulse uses CI for reproducible Xcode generation/builds/tests and firmware validation where runners/toolchains support it. CI does **not** prove Bluetooth, location, ESP sensor, Apple Watch, or real-world radio behavior; those require signed physical-device acceptance.

## Automated path

```sh
xcodegen generate
xcodebuild -project OmniPulse.xcodeproj -scheme OmniPulse \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:OmniPulseTests test
./script/build_altstore_ipa.sh
```

## Physical iPhone acceptance

- Start/stop BLE scanning and persist a detection.
- Verify History/Map.
- Export CSV/PDF and verify the system destination flow.
- Verify retention and full deletion.
- Exercise App Intents on iOS 18+.

## Sensor acceptance

Build/flash the firmware in an authorized lab, connect from OmniPulse, receive/review/import a batch, and confirm that clear MAC/BSSID values are not displayed or persisted.

## Apple Watch acceptance

Install the complete signed iPhone + Watch scheme, verify WatchConnectivity, start/stop iPhone scanning, toggle Vehicle mode, save a current batch, and inspect recent detections.
