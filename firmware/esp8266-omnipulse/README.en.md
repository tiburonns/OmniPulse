# OmniPulse firmware for ESP8266

**[Español](README.md) · English**

This firmware turns ESP8266 modules into 2.4 GHz Wi-Fi sensors for OmniPulse. Included profiles cover NodeMCU ESP8266, Wemos/LOLIN D1 mini, D1 mini Lite/Pro, and ESP-01 1 MB.

ESP8266 has no Bluetooth. At startup it creates `OmniPulse-8266-XXXX`; the password is `omniXXXX`, preserving the final four SSID characters' case. Connect the iPhone to that network and use **Scan → Wi-Fi → Read ESP8266 / D1 mini**. OmniPulse fetches the batch from `http://192.168.4.1/scan`.

```sh
cd firmware/esp8266-omnipulse
pio run -e d1_mini
pio run -e d1_mini -t upload
```

Use `nodemcuv2` for NodeMCU. These boards scan only 2.4 GHz Wi-Fi; they cannot scan BLE or use the ESP32 BLE OTA path.
