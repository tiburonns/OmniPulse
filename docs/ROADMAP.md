# Roadmap

## Fase 1 — Base local (incluida)

- [x] Navegación SwiftUI: Escanear, Historial, Mapa y Ajustes.
- [x] Escaneo BLE en primer plano desde iPhone.
- [x] Ubicación opcional y persistencia local SwiftData.
- [x] Mapa de observaciones guardadas.
- [x] Contrato y firmware inicial ESP32.

## Fase 2 — Sensor autorizado

- [x] Descubrir y conectar el ESP32 por UUID de servicio.
- [x] Suscribirse a notificaciones GATT y validar JSON v1.
- [x] Vista de preimportación: origen, número de observaciones y ubicación que se guardará.
- [ ] Pruebas con ESP32 DevKitC y diversos estados de permiso.

## Fase 3 — Utilidad diaria

- [x] Análisis espectral con frecuencia/ancho de canal, separación 2.4/5/6 GHz y recomendaciones conservadoras ante DFS.
- [x] Filtros por fuente y búsqueda de texto.
- [x] Exportación CSV bajo acción explícita.
- [x] Retención configurable y borrado de registros caducados.
- [ ] Geocercas y alertas locales justificadas por el usuario.

## Fase 4 — Superficies Apple

- [ ] WidgetKit con estadísticas locales agregadas.
- [x] App Intents: abrir Escanear, Historial y Mapa, sin revelar información sensible en Siri.
- [x] Companion watchOS para controles y snapshots del iPhone, sin escaneo Wi-Fi directo desde el reloj.

## Criterios de salida

Antes de publicar: pruebas en iPhone real, texto de permisos revisado, política de privacidad, evaluación de batería, revisión legal local y prueba de borrado de datos.
