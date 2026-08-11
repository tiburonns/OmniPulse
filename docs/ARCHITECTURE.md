# Arquitectura

## Objetivo

OmniPulse registra observaciones de radio cercanas de forma local, explícita y trazable. La primera versión trata al iPhone como central BLE y fuente de ubicación. Un ESP32 opcional amplía la cobertura mediante observaciones agregadas, sin convertir al teléfono en un escáner Wi-Fi de bajo nivel.

```text
iPhone
  CoreBluetooth ──> BluetoothScanner ─┐
  CoreLocation ──> LocationService ───┼─> SwiftUI ─> SwiftData ─> Historial / Mapa
  Sensor ESP32 ──> JSON sobre BLE ────┘
```

## Capas

| Capa | Responsabilidad |
| --- | --- |
| `Services` | Controla permisos y APIs del sistema. No escribe vistas ni depende de SwiftData. |
| `Models` | Tipos de descubrimiento, registro persistente y contrato del sensor. |
| `Views` | Presenta estado y pide acciones explícitas: iniciar escaneo, guardar y borrar. |
| `firmware` | Produce lotes JSON compatibles con el contrato documentado. |

## Decisiones

- **iOS 17 mínimo**: permite usar `@Observable` y SwiftData sin capas de compatibilidad.
- **Modelo local**: las detecciones no se suben a ningún servicio en esta base.
- **Ubicación cuando la persona guarda**: el escaneo no inicia GPS automáticamente. El permiso se solicita al pedirlo desde una acción relevante.
- **BLE del iPhone en primer plano**: se evita declarar modos de segundo plano hasta tener un caso de producto probado y una justificación de batería/privacidad.
- **Wi-Fi solo por sensor**: iOS no ofrece un escaneo general de redes/dispositivos Wi-Fi a apps comunes; el ESP32 envía resultados agregados mediante el contrato.

## Extensiones previstas

1. Geocercas y alertas locales, con su propio consentimiento.
2. WidgetKit, App Intents y watchOS sobre el mismo almacén mediante App Groups, solo después de diseñar migraciones y retención.
