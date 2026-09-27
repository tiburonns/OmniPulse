# OmniPulse 1.2.2 — TestFlight preflight

OmniPulse should pass both protected-branch jobs, `apple` and `firmware`, before creating an Archive.

## Automated gate

The Apple job validates the release contract, reproducible XcodeGen project, iOS tests, **Release** iOS/iPhoneOS, macOS and watchOS builds, plus the AltStore IPA/metadata path. The firmware job builds the distributed ESP32, ESP8266 and ESP32-C5 profiles.

## Remaining physical gates

- Real iPhone BLE scan/start/stop and persistence into History/Map.
- When-In-Use location and denied-permission paths.
- Connect supported ESP32/ESP8266 hardware and import batches.
- Confirm clear MAC/BSSID values are neither displayed nor persisted.
- Watch companion installation, WatchConnectivity, start/stop, Vehicle, Save batch, and delayed delivery.
- CSV/PDF export.
- Siri Shortcuts on iOS 18+.
- System / English / Español on iPhone and Watch.

## Archive

1. Merge only with `apple` and `firmware` green.
2. Run XcodeGen 2.46.0 and confirm the generated project is unchanged.
3. Open `OmniPulse.xcodeproj`.
4. Select the paid Apple Developer Team.
5. Confirm iOS and Watch bundle identifiers.
6. Product > Archive for Generic iOS Device.
7. Organizer > Validate App.
8. Upload to App Store Connect and start Internal Testing.

OmniPulse does not implement its own cryptographic encryption in the app; its plist declares no non-exempt encryption. System networking protections remain platform-provided where applicable.
