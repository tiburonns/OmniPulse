# OmniPulse

Aplicación universal para iPhone, iPad, Mac y Apple Watch que registra descubrimientos Bluetooth Low Energy (BLE), analiza redes Wi-Fi mediante sensores autorizados y conserva la ubicación de cada observación.

> **Versión actual de desarrollo en `main`: 1.2.2 (build 6).** La última versión distribuida sigue siendo 1.2.0 hasta publicar una nueva release.

[Descargar OmniPulse 1.2.0](https://github.com/tiburonns/OmniPulse/releases/tag/v1.2.0) · [Fuente para AltStore](https://raw.githubusercontent.com/tiburonns/OmniPulse/main/source.json) · [Instalar con AltStore/Sideloadly](docs/ALTSTORE.md) · [Compilar e instalar con Xcode](docs/COMPILAR_EN_XCODE.md)

## Funciones principales

- Escaneo BLE desde el iPhone con CoreBluetooth.
- Ubicación bajo permiso `When In Use` con CoreLocation.
- Historial local con SwiftData, mapa geográfico y planos de planta.
- Proyectos de levantamiento con análisis espectral por frecuencia/ancho y recomendaciones conservadoras para 2.4/5/6 GHz; 6 GHz requiere una fuente capaz de reportar esa banda.
- Informes PDF y exportación CSV iniciados por la persona usuaria.
- Identificación BLE de fabricantes, categorías, iBeacon y Eddystone.
- Conexión simultánea con hasta ocho sensores ESP32. La OTA BLE experimental está desactivada en las compilaciones distribuidas hasta incorporar firma y anti-rollback.
- Soporte Wi-Fi local para NodeMCU ESP8266, Wemos/LOLIN D1 mini y placas similares.
- Firmware incluido para ESP32, ESP32-CAM, ESP32-S3, XIAO ESP32S3/Sense, ESP32-C5, ESP8266 y D1 mini. Los perfiles actuales no afirman escaneo 6 GHz; el ESP32-C5 aporta datos de 5 GHz cuando el entorno/hardware los expone.
- Apariencia automática, seis temas oscuros, ocho temas claros y editor de paleta personalizada.
- Atajos de Siri (iOS 18+) para abrir Escanear, Historial o Mapa.

El firmware no inspecciona tráfico, no intenta descifrar redes ni transmite direcciones MAC en claro. Los identificadores de anuncios BLE se vuelven seudónimos efímeros por sesión. Úsalo únicamente en espacios, redes y dispositivos que administres o para los que tengas autorización.

## Requisitos

- macOS con Xcode 16 o posterior.
- iOS 17 o posterior en un iPhone físico para las pruebas de Bluetooth y ubicación.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) para generar el proyecto Xcode desde `project.yml`.

## Abrir la app en Xcode

Consulta la [guía completa para clonar, firmar e instalar OmniPulse en un iPhone](docs/COMPILAR_EN_XCODE.md), incluida la configuración para cuentas gratuitas.

```bash
brew install xcodegen
cd OmniPulse
xcodegen generate --spec project.yml
open OmniPulse.xcodeproj
```

Selecciona un equipo de firma y cambia `PRODUCT_BUNDLE_IDENTIFIER` en `project.yml` si el identificador `com.tiburonns.OmniPulse` no está disponible. Después de modificar archivos, vuelve a ejecutar `xcodegen generate`.

El repositorio no contiene un Team ID, certificados ni perfiles. Cada persona debe seleccionar su propio equipo de desarrollo en Xcode.

## AltStore y Sideloadly

La IPA pública es una variante para iPhone/iPad sin el paquete complementario de Apple Watch. Esto evita un cierre de AltStore 2.2.1 al firmar ejecutables `arm64_32`. La aplicación completa para iPhone + Apple Watch permanece disponible al compilar con Xcode y para una futura distribución mediante TestFlight o App Store.

Consulta la [guía de instalación y diagnóstico](docs/ALTSTORE.md). El paquete público se genera de forma reproducible con `script/build_altstore_ipa.sh` y se distribuye sin certificados, perfiles ni Team ID.

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

## Privacidad, seguridad y licencia

Consulta [Privacidad](docs/PRIVACY.md), [Seguridad](SECURITY.md) y [Licencia](LICENSE). El código se publica para inspección y evaluación; no se concede permiso general para redistribuirlo o comercializar derivados.
