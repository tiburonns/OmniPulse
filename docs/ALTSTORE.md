# Instalar OmniPulse con AltStore o Sideloadly

## Descarga recomendada

Descarga `OmniPulse-AltStore-v1.2.0.ipa` desde la [versión 1.2.0 de GitHub](https://github.com/tiburonns/OmniPulse/releases/tag/v1.2.0), o agrega esta fuente a AltStore:

```text
https://raw.githubusercontent.com/tiburonns/OmniPulse/main/source.json
```

La IPA no contiene un Apple ID, Team ID, certificado ni perfil de aprovisionamiento. AltStore o Sideloadly la firma localmente con la cuenta elegida por quien la instala.

## Por qué la versión 1.0 cerraba AltStore

La IPA 1.0 incluía la aplicación complementaria de Apple Watch. Su ejecutable contiene la arquitectura `arm64_32`. AltStore 2.2.1 usa una versión de su firmador que no reconoce esa arquitectura y termina accediendo a un valor nulo dentro de `ldid::Allocate`; el resultado es `EXC_BAD_ACCESS` mientras firma, antes de comenzar la instalación.

Desde la versión 1.0.1, la IPA conserva toda la aplicación del iPhone y excluye únicamente `Payload/OmniPulse.app/Watch` del paquete para instalación lateral. La app de Apple Watch no se elimina del proyecto y sigue incluida al compilar el esquema completo en Xcode o al distribuir mediante TestFlight/App Store.

## Instalar desde AltStore

1. Elimina de Descargas cualquier copia de `OmniPulse-Unsigned-v1.0.ipa` para no seleccionar el archivo anterior por accidente.
2. Abre AltStore, agrega la fuente indicada arriba e instala OmniPulse 1.2.0. También puedes descargar la IPA y abrirla con AltStore.
3. Mantén AltServer disponible y el iPhone conectado a la misma red o por USB durante la firma e instalación.
4. Con una cuenta gratuita, recuerda renovar la firma antes de que termine su periodo de siete días.

## Instalar desde Sideloadly

1. Conecta el iPhone al Mac y confirma **Confiar en este ordenador**.
2. Abre Sideloadly y selecciona `OmniPulse-AltStore-v1.2.0.ipa`.
3. Selecciona tu dispositivo y tu Apple ID, inicia la instalación y completa cualquier verificación solicitada por Apple.

## Generar la IPA compatible

Ejecuta estos comandos en Terminal desde la raíz del repositorio:

```sh
brew install xcodegen
./script/build_altstore_ipa.sh
```

El script compila el destino iOS en Release sin firma, comprueba que sea la versión esperada, excluye el paquete Watch, verifica que no existan perfiles o firmas y crea la IPA dentro de `dist/`.

Para obtener la app completa de iPhone y Apple Watch, no uses esa IPA: abre `OmniPulse.xcodeproj` y compila el esquema `OmniPulse` con tu propio equipo de desarrollo, siguiendo [Compilar en Xcode](COMPILAR_EN_XCODE.md).

## Si AltStore todavía se cierra

- Confirma que el nombre del archivo sea `OmniPulse-AltStore-v1.2.0.ipa` y no la IPA 1.0.
- Reinicia AltStore después de borrar la descarga anterior.
- Actualiza AltStore y AltServer a la versión más reciente disponible.
- Verifica que exista espacio libre suficiente en el iPhone y el Mac.
- Si persiste, exporta el reporte de cierre de AltStore desde **Ajustes > Privacidad y seguridad > Análisis y mejoras > Datos de análisis** para comparar la traza.
