# Protocolo del sensor ESP32

## Transporte inicial

El sensor anuncia el servicio BLE `7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A101` y publica lotes UTF-8 JSON por notificación en la característica `7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A102`.

El código contiene un transporte OTA experimental en las características `7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A103` y `7D3B6D4E-1A7F-4A43-87D2-7E4D4D50A104`, pero está desactivado en las compilaciones distribuidas. Solo puede exponerse en una compilación explícita de laboratorio con `OMNIPULSE_ENABLE_LAB_OTA=1`, sobre un enlace BLE cifrado y autenticado. SHA-256 verifica la transferencia, no la procedencia del firmware; no se habilitará en producción hasta añadir firma, anti-rollback y recuperación.

La app futura debe filtrar por el UUID de servicio, suscribirse a notificaciones y rechazar cargas que no cumplan este contrato. Los lotes se envían solo tras una conexión iniciada por la persona usuaria.

## Esquema v1

```json
{
  "version": 1,
  "sensorID": "omnipulse-7a3c",
  "sensorName": "OmniPulse 7a3c",
  "firmwareVersion": "1.2.0",
  "hardware": "ESP32-S3",
  "capturedAt": "2026-08-07T21:15:00Z",
  "observations": [
    {
      "kind": "wifiNetwork",
      "identifier": "wifi-b3e2a11c",
      "name": "Red visible",
      "rssi": -63,
      "channel": 6,
      "frequencyMHz": 2437,
      "channelWidthMHz": 20,
      "seenAt": "2026-08-07T21:14:59Z"
    }
  ]
}
```

## Reglas

- `version` es obligatorio y actualmente vale `1`.
- `sensorName`, `firmwareVersion` y `hardware` son metadatos opcionales para identificar y diagnosticar el sensor.
- `kind` admite `wifiNetwork` y `bluetoothLE`.
- `identifier` es un seudónimo por sesión; no contiene BSSID ni MAC en claro.
- `name` puede omitirse cuando revelar SSID/nombre anunciado no sea necesario.
- `rssi` es un entero en dBm aproximado; no representa una distancia fiable.
- `channel` es opcional y contiene el canal primario de una observación Wi-Fi.
- `frequencyMHz` es opcional y contiene la frecuencia central observada en MHz. OmniPulse la prefiere para distinguir correctamente bandas que reutilizan números de canal, especialmente 6 GHz.
- `channelWidthMHz` es opcional y, cuando el hardware puede medirlo de forma fiable, admite 20, 40, 80, 160 o 320 MHz.
- Los perfiles ESP8266 publican frecuencia de 2.4 GHz derivada del canal. Los perfiles ESP32 publican 2.4 GHz y el ESP32-C5 puede aportar también 5 GHz. El firmware actual no afirma medir 6 GHz.
- `capturedAt` y `seenAt` son opcionales: el firmware de laboratorio no tiene reloj confiable y el iPhone deberá registrar el momento de recepción.
- El iPhone añade su propia ubicación al momento de que la persona confirme la importación.

## Evolución

Un cambio incompatible requiere una versión nueva. Añadir claves opcionales es compatible si los clientes desconocidos las ignoran. No se aceptan campos de tráfico capturado, credenciales, direcciones MAC o identificadores permanentes sin revisión de privacidad y consentimiento específico.


## Análisis espectral en la app

OmniPulse conserva `channel`, `frequencyMHz` y `channelWidthMHz` en el historial. El analizador usa la frecuencia y el ancho disponibles para estimar solapamiento espectral, mantiene separados canales con el mismo número en bandas distintas y recomienda canales de 2.4, 5 o 6 GHz sólo cuando existen muestras de esa banda.

En 5 GHz, los canales que pueden requerir DFS se excluyen de las recomendaciones por defecto. En 6 GHz se priorizan Preferred Scanning Channels (PSC), pero la disponibilidad real depende de la región, del punto de acceso y del hardware cliente. La recomendación es una ayuda de levantamiento, no una afirmación de disponibilidad regulatoria.
