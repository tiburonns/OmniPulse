# Validación de entrega

## Verificado el 18 de agosto de 2026

- Los `Info.plist` y `source.json` son válidos.
- La compilación de iOS para simulador terminó correctamente.
- La compilación de macOS terminó correctamente.
- La compilación de watchOS para simulador terminó correctamente.
- Las 10 pruebas de `OmniPulseTests` pasaron sin fallos en iPhone 17 con iOS 26.5.
- El firmware ESP8266 1.1.0 compiló correctamente para `d1_mini` y `nodemcuv2`.
- El firmware ESP32 1.4.0 compiló correctamente para ESP32, ESP32-CAM, ESP32-S3, XIAO ESP32S3 y ESP32-C5; los binarios resultantes están incluidos como recursos de la app.
- Los binarios de firmware actualizados están incluidos en los recursos de la aplicación.
- La búsqueda automatizada no encontró perfiles de aprovisionamiento, certificados, claves privadas, credenciales ni identificadores del equipo de desarrollo.
- Los reportes de cierre del iPhone localizaron el fallo de AltStore 2.2.1 en `ldid::Allocate` al firmar la arquitectura Watch `arm64_32` incluida en la IPA 1.0.
- La IPA 1.0.1 para instalación lateral contiene solo `Payload/OmniPulse.app`, un ejecutable iOS `arm64`, y no contiene `Watch/`, `_CodeSignature`, perfiles de aprovisionamiento ni `__MACOSX`.
- `OmniPulse-AltStore-v1.0.1.ipa` pesa 5,703,531 bytes y su SHA-256 es `f3eff7171b4096649097f419297040d901cfcbd53476df934d138a1700ae45aa`.

## Cómo repetir la validación

Requisitos: Xcode 16 o posterior, XcodeGen y un simulador iOS 17+.

```sh
cd OmniPulse
xcodegen generate
xcodebuild -project OmniPulse.xcodeproj -scheme OmniPulse \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:OmniPulseTests test
```

También puede ejecutarse el flujo de GitHub Actions incluido en `.github/workflows/ios.yml` para generar y compilar el proyecto en un runner macOS.

La IPA específica para AltStore/Sideloadly se genera y valida con:

```sh
./script/build_altstore_ipa.sh
```

Esta variante omite únicamente la app complementaria Watch del paquete lateral. El esquema completo `OmniPulse` conserva su dependencia de `OmniPulseWatch` para Xcode, TestFlight y App Store.

## Prueba en iPhone

1. Instalar la app y conceder permiso Bluetooth; conceder ubicación solo al usar el botón de geolocalización.
2. Iniciar y detener una exploración BLE; guardar una detección y verificarla en Historial y Mapa.
3. Exportar el historial CSV y confirmar que el selector del sistema permite elegir destino.
4. Comprobar el borrado por retención y el borrado total.
5. En iOS 18+, probar los atajos "Iniciar escaneo OmniPulse", "Abrir historial OmniPulse" y "Abrir mapa OmniPulse".

## Prueba con Apple Watch

Esta sección requiere hardware real y una instalación firmada del target completo de Xcode; la IPA pública de AltStore no incluye el companion watchOS.

1. Instalar OmniPulse desde Xcode en un iPhone emparejado con un Apple Watch compatible.
2. Confirmar que el companion se instala y recibe un snapshot inicial del iPhone.
3. Iniciar y detener el escaneo desde el reloj y verificar el cambio en el iPhone.
4. Activar y desactivar **Vehículo** desde el reloj y confirmar el modo correspondiente en el iPhone.
5. Con detecciones presentes, usar **Guardar lote** y verificar que aparecen en el historial del iPhone sin duplicados.
6. Abrir una detección reciente en el reloj y comprobar nombre, origen, RSSI, hora y ubicación cuando exista.
7. Cambiar el idioma del Apple Watch entre español e inglés y confirmar que controles, estados y placeholders se localizan en el reloj.
8. Alejar temporalmente el reloj del iPhone, enviar un comando, volver a ponerlos en alcance y comprobar la entrega diferida mediante WatchConnectivity.

Pass: el companion controla únicamente las acciones documentadas, conserva la sincronización con el iPhone, no intenta escanear Wi-Fi directamente y no muestra estados fijos en un idioma incorrecto.

## Prueba con ESP32

1. Compilar y cargar `firmware/esp32-omnipulse` con PlatformIO.
2. Encender el ESP32 en un entorno autorizado de laboratorio y conectar desde Ajustes de sensor.
3. Iniciar el escaneo del sensor, recibir el lote de observaciones y pulsar **Importar lote**.
4. Confirmar que no se muestran ni se persisten direcciones MAC/BSSID en texto claro; solo se importan identificadores seudonimizados.

Use las funciones de exploración únicamente en dispositivos y redes propios o con autorización expresa. Revise `SECURITY.md` y `docs/PRIVACY.md` antes de distribuir modificaciones.
