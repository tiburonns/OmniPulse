# OmniPulse 1.2.2 — Preflight de TestFlight

OmniPulse debe pasar los jobs `apple` y `firmware` de la rama protegida antes de crear un Archive.

## Gate automatizado

El job Apple valida contrato de release, proyecto reproducible XcodeGen, tests iOS, builds **Release** de iOS/iPhoneOS, macOS y watchOS, además de la IPA/metadata de AltStore. El job firmware compila los perfiles distribuidos de ESP32, ESP8266 y ESP32-C5.

## Pruebas físicas pendientes

- BLE real en iPhone: iniciar/detener scan, guardar detecciones e inspeccionar historial/mapa.
- Ubicación When In Use y ruta de permiso denegado.
- Conectar los ESP32/ESP8266 soportados y verificar importación de lotes.
- Confirmar que MAC/BSSID no se muestran ni persisten en claro.
- Watch companion: instalación, WatchConnectivity, start/stop, Vehicle, Guardar lote y entrega diferida.
- Exportar CSV/PDF.
- Atajos de Siri en iOS 18+.
- Sistema / English / Español en iPhone y Watch.

## Archive

1. Merge sólo con `apple` y `firmware` verdes.
2. Ejecuta XcodeGen 2.46.0 y confirma que no cambia el proyecto.
3. Abre `OmniPulse.xcodeproj`.
4. Selecciona tu Team de Apple Developer.
5. Verifica los bundle IDs de iOS y Watch.
6. Product > Archive sobre Generic iOS Device.
7. Organizer > Validate App.
8. Sube a App Store Connect e inicia Internal Testing.

OmniPulse no implementa cifrado criptográfico propio en la app; el plist declara que no usa cifrado no exento. El networking de sistema sigue usando las protecciones provistas por las plataformas donde correspondan.
