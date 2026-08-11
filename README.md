# OmniPulse

Aplicación universal para iPhone, iPad, Mac y Apple Watch que registra descubrimientos Bluetooth Low Energy (BLE), analiza redes Wi-Fi mediante sensores autorizados y conserva la ubicación de cada observación.

## Funciones principales

- Escaneo BLE desde el iPhone con CoreBluetooth.
- Ubicación bajo permiso `When In Use` con CoreLocation.
- Historial local con SwiftData, mapa geográfico y planos de planta.
- Proyectos de levantamiento, análisis y recomendación de canales de 2.4/5 GHz.
- Informes PDF y exportación CSV iniciados por la persona usuaria.
- Identificación BLE de fabricantes, categorías, iBeacon y Eddystone.
- Conexión simultánea con hasta ocho sensores ESP32 y actualización OTA por BLE.
- Soporte Wi-Fi local para NodeMCU ESP8266, Wemos/LOLIN D1 mini y placas similares.
- Firmware incluido para ESP32, ESP32-CAM, ESP32-S3, XIAO ESP32S3/Sense, ESP32-C5, ESP8266 y D1 mini.
- Temas del sistema, temas incluidos y editor de paleta personalizada.
- Atajos de Siri (iOS 18+) para abrir Escanear, Historial o Mapa.

El firmware no inspecciona tráfico, no intenta descifrar redes ni transmite direcciones MAC en claro. Los identificadores de anuncios BLE se vuelven seudónimos efímeros por sesión. Úsalo únicamente en espacios, redes y dispositivos que administres o para los que tengas autorización.

## Requisitos

- macOS con Xcode 16 o posterior.
- iOS 17 o posterior en un iPhone físico para las pruebas de Bluetooth y ubicación.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) para generar el proyecto Xcode desde `project.yml`.

## Abrir la app en Xcode

```bash
brew install xcodegen
cd OmniPulse
xcodegen generate --spec project.yml
open OmniPulse.xcodeproj
```

Selecciona un equipo de firma y cambia `PRODUCT_BUNDLE_IDENTIFIER` en `project.yml` si el identificador `com.tiburonns.OmniPulse` no está disponible. Después de modificar archivos, vuelve a ejecutar `xcodegen generate`.

## Estructura

```text
OmniPulse/                 App SwiftUI
OmniPulseTests/            Pruebas unitarias básicas
docs/                      Arquitectura, modelo local, protocolo y seguridad
firmware/esp32-omnipulse/  Proyecto PlatformIO del sensor
firmware/esp8266-omnipulse/ Proyecto PlatformIO para NodeMCU y D1 mini
project.yml                Fuente reproducible del .xcodeproj
```

## Estado de integración

La app realiza descubrimiento BLE, persistencia local, conexión GATT con sensores ESP32 y recepción HTTP local desde ESP8266. Cada lote se muestra para revisión antes de importarse. Las versiones iOS, macOS y watchOS forman parte del mismo proyecto reproducible de XcodeGen. Todas las funciones son gratuitas y no existe plan de pago ni suscripción.
