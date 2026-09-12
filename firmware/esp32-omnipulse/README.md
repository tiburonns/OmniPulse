# Sensor OmniPulse para ESP32

Firmware 1.4 para ESP32, ESP32-S3, ESP32-C5 y Seeed Studio XIAO ESP32S3/Sense. Anuncia un servicio BLE y envía notificaciones JSON v1 con una observación por mensaje, tiempo encendido y memoria libre para diagnóstico. Hace escaneos activos de redes Wi-Fi visibles y anuncios BLE; no captura tráfico, no intenta asociarse a redes y no transmite BSSID/MAC en claro.

## Requisitos

- PlatformIO Core o la extensión PlatformIO IDE.
- Una placa con Wi-Fi de 2.4 GHz y Bluetooth Low Energy.
- Perfiles incluidos: ESP32 DevKit/DevKitC, AI-Thinker ESP32-CAM, ESP32-S3 DevKitC-1, Seeed Studio XIAO ESP32S3/Sense y otras placas indicadas en `platformio.ini`.
- Antena 2.4 GHz conectada en XIAO ESP32S3/Sense para obtener alcance útil.
- ESP32-C5 DevKitC-1 para observar redes de 2.4 y 5 GHz.

## Construir y cargar

```bash
cd firmware/esp32-omnipulse
pio run
pio run -t upload
pio device monitor
```

Para elegir una placa concreta:

```bash
pio run -e esp32dev
pio run -e esp32cam
pio run -e esp32-s3-devkitc-1
pio run -e seeed_xiao_esp32s3
pio run -e esp32-c5-devkitc-1
```

Agrega `-t upload` al comando elegido para cargar el firmware. XIAO ESP32S3 y XIAO ESP32S3 Sense comparten el mismo identificador de PlatformIO; la cámara y el micrófono de la edición Sense no son necesarios para OmniPulse.

Los perfiles ESP32-C3 incluidos ya pasan la compilación. ESP32-C5 utiliza la plataforma pioarduino con Arduino Core 3.x. ESP32-C6 dispone de Wi-Fi y BLE, pero permanece como compatible por arquitectura hasta validar el mismo protocolo. ESP32-S2 y XIAO nRF52840 Sense no cumplen simultáneamente los requisitos de Wi-Fi y BLE. ESP8266 y D1 mini sí están soportados mediante el firmware separado `firmware/esp8266-omnipulse`, usando Wi-Fi local en lugar de BLE.

## Actualización OTA

La primera instalación de la versión 1.4.0 se realiza por USB. A partir de ella, OmniPulse descubre dos características BLE adicionales, verifica el binario con SHA-256 y puede instalar futuras versiones desde la pantalla de detalle del sensor. Una imagen nueva queda pendiente durante 30 segundos: solo se confirma si BLE, el escáner y la memoria están saludables; de lo contrario el bootloader vuelve automáticamente a la imagen anterior. Mantén una alimentación estable durante la transferencia.

## Seguridad antes de uso real

Esta muestra no habilita emparejamiento ni una lista de dispositivos autorizados. Úsala solo en laboratorio. Antes de desplegarla, implementa autenticación BLE, cifrado, un indicador físico de captura, actualización de firmware segura y las medidas de `../../docs/SECURITY.md`.
