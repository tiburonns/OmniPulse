# Seguridad y privacidad

## Principios

1. **Consentimiento y contexto**: usar el sistema únicamente en ubicaciones, redes y equipos propios o autorizados.
2. **Minimización**: no almacenar tráfico, credenciales ni MAC/BSSID en claro.
3. **Acción explícita**: el escaneo no guarda automáticamente; cada registro lo inicia la persona usuaria.
4. **Control local**: los datos permanecen en el dispositivo y existe borrado completo.
5. **Transparencia**: indicar origen, momento y precisión de ubicación de cada registro.
6. **Exportación consciente**: la exportación CSV requiere una acción directa y el selector del sistema para elegir destino.

## Límites de plataforma

- El iPhone ve anuncios BLE; no es un monitor de tráfico ni un escáner Wi-Fi general.
- RSSI fluctúa por obstáculos, orientación y hardware; no usarlo para afirmar una ubicación exacta.
- El firmware de ejemplo enumera redes visibles y anuncios BLE, no clientes asociados a una red ni paquetes.

## Requisitos antes de usar un ESP32 fuera de laboratorio

- Autenticar el sensor y cifrar el canal BLE con emparejamiento apropiado.
- Rotar el identificador de sesión y no reutilizar seudónimos entre despliegues.
- Agregar límites de frecuencia, indicadores visibles de captura y actualización de firmware firmada.
- Definir una política de retención, respuesta ante borrado y revisión legal según jurisdicción.
