# Arquitectura

**[English](ARCHITECTURE.en.md) · Español**

## Objetivo

OmniPulse registra observaciones de radio cercanas de forma local y trazable. El iPhone funciona como central BLE y fuente opcional de ubicación. Sensores ESP32/ESP8266 amplían la cobertura con observaciones agregadas.

```text
iPhone
  CoreBluetooth ──> BluetoothScanner ─┐
  CoreLocation ──> LocationService ───┼─> SwiftUI ─> SwiftData ─> Historial / Mapa
  ESP32 ─────────> JSON sobre BLE ────┤
  ESP8266 ───────> JSON sobre HTTP ───┘
                         │
                         ├─> companion macOS
                         └─> WatchConnectivity ─> Apple Watch
```

## Capas

- `Services`: permisos, radio, conectividad, exportación y APIs del sistema.
- `Models`: descubrimientos, persistencia, proyectos y contratos.
- `Views`: presentación y acciones explícitas.
- `OmniPulseMac`: superficies nativas de macOS.
- `OmniPulseWatch`: controles remotos y resumen de detecciones.
- `firmware`: implementaciones de sensores.

## Decisiones

- iOS 17 mínimo.
- Historial local por defecto; sin backend de OmniPulse.
- Ubicación bajo permisos del sistema y sólo donde el flujo la requiere.
- El escaneo BLE del iPhone no se presenta como monitor continuo de escritorio cuando iOS suspende la app.
- Wi-Fi mediante sensores autorizados.
- Exportación CSV/PDF iniciada por la persona.
- App Intents, macOS y watchOS ya forman parte de la base actual.

## Pendientes

- Endurecer firma/anti-rollback antes de habilitar OTA BLE en builds distribuidas.
- Añadir WidgetKit después de definir almacenamiento compartido, retención y privacidad.
- Mantener BLE, ubicación, sensores y WatchConnectivity como gate de hardware independiente de CI.
