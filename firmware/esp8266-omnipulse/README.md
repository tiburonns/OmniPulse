# Firmware OmniPulse para ESP8266

Este firmware convierte módulos ESP8266 en sensores Wi-Fi de 2.4 GHz para OmniPulse. Incluye perfiles para NodeMCU ESP8266, Wemos/LOLIN D1 mini, D1 mini Lite/Pro y ESP-01 con 1 MB.

El ESP8266 no tiene Bluetooth. Al arrancar crea una red `OmniPulse-8266-XXXX`. La contraseña es `omniXXXX`, donde `XXXX` son los cuatro caracteres finales de la red, respetando mayúsculas; por ejemplo, `OmniPulse-8266-A1B2` usa `omniA1B2`. Conecta el iPhone a esa red y usa **Escanear → Wi-Fi → Leer ESP8266 / D1 mini**. La app solicita el lote por `http://192.168.4.1/scan`.

```sh
cd firmware/esp8266-omnipulse
pio run -e d1_mini
pio run -e d1_mini -t upload
```

Para NodeMCU sustituye `d1_mini` por `nodemcuv2`. Estas placas solo escanean Wi-Fi 2.4 GHz; no pueden escanear BLE ni recibir la actualización OTA BLE de los ESP32.
