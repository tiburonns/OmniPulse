# Validación de entrega

## Verificado el 10 de agosto de 2026

- Los `Info.plist` y `source.json` son válidos.
- La compilación de iOS para simulador terminó correctamente.
- La compilación de macOS terminó correctamente.
- La compilación de watchOS para simulador terminó correctamente.
- Las 10 pruebas de `OmniPulseTests` pasaron sin fallos en iPhone 17 con iOS 26.5.
- El firmware ESP8266 1.1.0 compiló correctamente para `d1_mini` y `nodemcuv2`.
- Los binarios de firmware actualizados están incluidos en los recursos de la aplicación.
- La búsqueda automatizada no encontró perfiles de aprovisionamiento, certificados, claves privadas, credenciales ni identificadores del equipo de desarrollo.

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

## Prueba en iPhone

1. Instalar la app y conceder permiso Bluetooth; conceder ubicación solo al usar el botón de geolocalización.
2. Iniciar y detener una exploración BLE; guardar una detección y verificarla en Historial y Mapa.
3. Exportar el historial CSV y confirmar que el selector del sistema permite elegir destino.
4. Comprobar el borrado por retención y el borrado total.
5. En iOS 18+, probar los atajos "Iniciar escaneo OmniPulse", "Abrir historial OmniPulse" y "Abrir mapa OmniPulse".

## Prueba con ESP32

1. Compilar y cargar `firmware/esp32-omnipulse` con PlatformIO.
2. Encender el ESP32 en un entorno autorizado de laboratorio y conectar desde Ajustes de sensor.
3. Iniciar el escaneo del sensor, recibir el lote de observaciones y pulsar **Importar lote**.
4. Confirmar que no se muestran ni se persisten direcciones MAC/BSSID en texto claro; solo se importan identificadores seudonimizados.

Use las funciones de exploración únicamente en dispositivos y redes propios o con autorización expresa. Revise `SECURITY.md` y `docs/PRIVACY.md` antes de distribuir modificaciones.
