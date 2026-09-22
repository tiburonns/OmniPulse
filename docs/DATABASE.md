# Base de datos local

**[English](DATABASE.en.md) · Español**

`DetectionRecord` es el modelo SwiftData persistente de cada observación guardada. El esquema actual conserva identidad/nombre, transporte/origen, RSSI, canal/frecuencia/ancho Wi-Fi, fecha, ubicación opcional, proyecto/plano, metadatos BLE y procedencia/versión del sensor.

## Retención y exportación

- El historial vive localmente dentro del contenedor SwiftData de OmniPulse.
- No existe sincronización iCloud ni un backend de OmniPulse para el historial.
- La retención puede limitarse por antigüedad y número máximo de registros.
- Ajustes permite borrar el historial.
- La exportación CSV y los informes PDF se generan únicamente mediante una acción explícita de la persona usuaria y se entregan al flujo del sistema para elegir destino.
- Los archivos exportados pueden contener información sensible de radio y ubicación; deben revisarse antes de compartirlos.

## Migraciones

Los cambios incompatibles del esquema persistente deben introducir un `SchemaMigrationPlan` antes de eliminar o reinterpretar campos. `deviceIdentifier` no debe usarse como clave única de historial: una misma fuente puede producir múltiples observaciones legítimas.
