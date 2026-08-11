# Base de datos local

`DetectionRecord` es el único modelo SwiftData persistente de la primera fase.

| Campo | Tipo | Uso |
| --- | --- | --- |
| `id` | UUID | Identidad de un evento guardado. |
| `deviceIdentifier` | String | Identificador BLE del sistema o seudónimo efímero del sensor. |
| `deviceName` | String | Nombre anunciado o etiqueta segura de origen. |
| `transport` | String | `BLE`, `ESP32 BLE` o `Wi-Fi` (red visible). |
| `source` | String | Origen: iPhone o ESP32. |
| `rssi` | Int | Intensidad de señal recibida, no distancia exacta. |
| `seenAt` | Date | Momento de la observación. |
| `latitude` / `longitude` | Double? | Instantánea de ubicación opcional al guardar. |
| `horizontalAccuracy` | Double? | Precisión reportada por Core Location. |

## Retención

- Los datos viven solo en el contenedor SwiftData de la app.
- No hay sincronización iCloud, analítica ni exportación activa en esta base.
- La pantalla Ajustes permite borrar el historial completo.
- Antes de habilitar exportación, se debe incorporar un selector de rango, vista previa y advertencia de contenido sensible.

## Migraciones

Las próximas versiones deben añadir un `SchemaMigrationPlan` antes de cambiar o eliminar campos persistentes. No se debe reutilizar `deviceIdentifier` como clave única: una misma fuente puede producir varias observaciones legítimas a lo largo del tiempo.
