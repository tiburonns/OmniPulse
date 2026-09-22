# Security and privacy

**[Español](SECURITY.md) · English**

1. Use only on spaces, networks, and equipment you own or are authorized to inspect.
2. Do not store captured traffic, credentials, or clear MAC/BSSID identifiers.
3. Persist observations only through explicit product flows.
4. Keep history local and deletable.
5. Preserve source/time/location-accuracy context.
6. Keep CSV/PDF export user-initiated.

iPhone observes BLE advertisements; it is not a packet monitor or general-purpose Wi-Fi scanner. RSSI is not precise distance.

Before ESP32 deployment outside a lab, add appropriate BLE authentication/encryption, device authorization, visible capture indicators, signed firmware update, and a documented retention/deletion policy.
