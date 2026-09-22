# Local database

**[Español](DATABASE.md) · English**

`DetectionRecord` is the SwiftData model for each saved observation. The current schema stores basic signal data plus optional Wi-Fi, project, floor-plan, BLE, and sensor metadata.

Important fields include identity/name, transport/source, RSSI, Wi-Fi channel/frequency/width, observation time, optional location and accuracy, project/floor-plan coordinates, interpreted BLE metadata, advertisement interval, and sensor identity/hardware/firmware.

## Retention and export

- History remains local to OmniPulse's SwiftData container.
- There is no iCloud history sync or OmniPulse history backend.
- Retention can be bounded by age and maximum record count.
- Settings can delete history.
- CSV exports and PDF reports are generated only after an explicit user action and are handed to the system destination/share flow.
- Exported files may contain sensitive radio/location information and should be reviewed before sharing.

## Migrations

Incompatible persistent-model changes should introduce a `SchemaMigrationPlan` before fields are removed or reinterpreted. Do not use `deviceIdentifier` as a unique history key; the same source can legitimately produce multiple observations over time.
