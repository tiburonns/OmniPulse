# Protocolo del sensor ESP32

**[English](ESP32_PROTOCOL.en.md) · Español**

El sensor anuncia el servicio BLE `7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A101` y publica observaciones JSON UTF-8 en `...A102`.

Las características OTA experimentales `...A103` y `...A104` existen en el código pero permanecen desactivadas en builds distribuidas. SHA-256 verifica bytes transferidos, no la procedencia del firmware; producción sigue bloqueada hasta contar con firma y anti-rollback.

La app actual filtra por el UUID OmniPulse, se suscribe a notificaciones, valida payloads v1 y deja las observaciones pendientes de revisión antes de importarlas.

## Reglas v1

- `version` es obligatorio y actualmente vale 1.
- Nombre de sensor, firmware y hardware son diagnósticos opcionales.
- `kind` admite `wifiNetwork` y `bluetoothLE`.
- Los identificadores son seudónimos por sesión; no deben exponer BSSID/MAC en claro.
- RSSI es aproximado y no representa distancia precisa.
- Canal/frecuencia/ancho son mediciones Wi-Fi opcionales.
- El firmware ESP32 actual no afirma medir 6 GHz.
- El iPhone puede añadir su ubicación autorizada cuando se confirma la importación.

## Análisis espectral

OmniPulse conserva canal/frecuencia/ancho cuando están disponibles, separa números de canal iguales entre bandas, excluye DFS potencial por defecto en 5 GHz y sólo genera recomendaciones de 6 GHz cuando existen observaciones reales de esa banda.
