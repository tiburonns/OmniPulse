# OmniPulse 1.2.0

- Calibrate RSSI independently for every ESP sensor with a persistent ±20 dB correction.
- See live sensor health, observation count, uptime, free memory, signal, hardware, and firmware.
- Enforce local history retention by both age and maximum record count at launch and after imports.
- ESP32 firmware 1.4.0 reports health data and confirms a new OTA image only after a healthy 30-second boot; failed validation triggers automatic rollback.
- AltStore and Sideloadly community distribution remain supported alongside direct Xcode installation.
