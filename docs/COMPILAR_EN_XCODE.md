# Clonar, compilar e instalar OmniPulse con Xcode

Esta guía instala OmniPulse directamente desde su código fuente. No necesitas una membresía de pago para probarla en tu propio iPhone: Xcode permite usar un Apple Account gratuito como **Personal Team**. Apple limita ese método y el perfil suele vencer después de 7 días, por lo que tendrás que volver a compilar e instalar la app periódicamente.

## Requisitos

- Una Mac compatible con Xcode 16 o posterior.
- Un iPhone con iOS 17 o posterior.
- Un cable USB para la primera conexión. Después puedes habilitar la conexión inalámbrica desde Xcode.
- Un Apple Account agregado a Xcode.
- [Homebrew](https://brew.sh/) para instalar XcodeGen.
- Aproximadamente 15 GB libres para Xcode, sus componentes y la compilación.

## 1. Preparar Xcode

1. Instala Xcode desde la Mac App Store y ábrelo al menos una vez.
2. Acepta la licencia e instala los componentes adicionales que solicite.
3. En Xcode abre **Xcode > Settings > Accounts**.
4. Pulsa **+**, elige **Apple Account** e inicia sesión.

No compartas tu contraseña, códigos de verificación, certificados ni perfiles de aprovisionamiento. Xcode administra la firma en tu Mac.

## 2. Clonar el repositorio

### Opción A: desde Xcode

1. En la pantalla inicial de Xcode pulsa **Clone Git Repository…**. Si ya tienes un proyecto abierto, usa **Integrate > Clone…**.
2. Pega esta URL:

   ```text
   https://github.com/tiburonns/OmniPulse.git
   ```

3. Pulsa **Clone**, elige una carpeta en tu Mac y espera a que termine.
4. Cuando Xcode pregunte qué archivo abrir, puedes cerrar esa ventana: el proyecto se genera en el siguiente paso.

### Opción B: desde Terminal

Abre **Terminal** y ejecuta:

```bash
cd ~/Documents
git clone https://github.com/tiburonns/OmniPulse.git
cd OmniPulse
```

## 3. Instalar XcodeGen y generar el proyecto

El archivo `OmniPulse.xcodeproj` no se guarda en GitHub. Se genera de forma reproducible desde `project.yml`.

En Terminal ejecuta:

```bash
brew install xcodegen
cd ~/Documents/OmniPulse
xcodegen generate --spec project.yml
open OmniPulse.xcodeproj
```

Si clonaste el repositorio en otra ubicación, escribe `cd ` —con un espacio— y arrastra la carpeta **OmniPulse** desde Finder hasta Terminal. Presiona Return y continúa con los dos últimos comandos.

## 4. Usar identificadores de aplicación propios

Cada cuenta debe usar identificadores únicos para que Apple pueda registrar la app.

1. Cierra `OmniPulse.xcodeproj`.
2. Abre `project.yml` con un editor de texto.
3. Reemplaza todas las apariciones de:

   ```text
   com.tiburonns.OmniPulse
   ```

   por un identificador propio, por ejemplo:

   ```text
   com.tunombre.OmniPulse
   ```

   Usa únicamente letras, números, guiones y puntos; no uses espacios ni acentos.
4. Guarda el archivo y vuelve a generar el proyecto:

   ```bash
   xcodegen generate --spec project.yml
   open OmniPulse.xcodeproj
   ```

El reemplazo también ajusta los identificadores de Apple Watch y pruebas. Haz este cambio en `project.yml`, no solamente en la interfaz de Xcode, porque volver a ejecutar XcodeGen reemplaza el proyecto generado.

## 5. Configurar la firma

1. En Xcode selecciona el icono azul **OmniPulse** del navegador de archivos.
2. En **TARGETS**, selecciona **OmniPulse**.
3. Abre **Signing & Capabilities**.
4. Activa **Automatically manage signing**.
5. En **Team**, selecciona tu nombre o tu **Personal Team**.
6. Repite los pasos para el target **OmniPulseWatch**.

Si también quieres compilar la aplicación para Mac, selecciona **OmniPulseMac** y asigna el mismo equipo.

## 6. Preparar el iPhone

1. Conecta el iPhone a la Mac, desbloquéalo y pulsa **Confiar** cuando ambos dispositivos lo soliciten.
2. En Xcode abre **Window > Devices and Simulators** y espera a que el iPhone termine de prepararse.
3. Si iOS lo solicita, activa **Ajustes > Privacidad y seguridad > Modo de desarrollador**.
4. Reinicia el iPhone y confirma que deseas activar el modo de desarrollador.

## 7. Compilar e instalar

1. En la barra superior de Xcode selecciona el esquema **OmniPulse**.
2. A su derecha selecciona tu iPhone como destino, no un simulador.
3. Pulsa el botón **Run** ▶ o presiona `Command + R`.
4. Espera a que Xcode compile, firme e instale OmniPulse.
5. En el iPhone concede los permisos de Bluetooth, red local y ubicación cuando las funciones correspondientes los necesiten.

Las funciones BLE y la comunicación con sensores deben probarse en un iPhone físico; el simulador no reproduce el hardware Bluetooth real.

## Actualizar una copia existente

En Terminal, dentro de la carpeta del repositorio, ejecuta:

```bash
git pull --ff-only
xcodegen generate --spec project.yml
open OmniPulse.xcodeproj
```

Si modificaste el código, guarda o confirma tus cambios antes de ejecutar `git pull`.

## Problemas frecuentes

### “Signing requires a development team”

Selecciona tu equipo en **Signing & Capabilities** tanto para **OmniPulse** como para **OmniPulseWatch**.

### “Bundle identifier is already in use”

El identificador no es único. Cambia `com.tunombre.OmniPulse` por otro valor en `project.yml`, vuelve a ejecutar XcodeGen y abre otra vez el proyecto.

### El iPhone no aparece como destino

Desbloquéalo, confirma **Confiar**, usa un cable que transmita datos y revisa **Window > Devices and Simulators**. Verifica también que la versión de Xcode sea compatible con el iOS instalado.

### La app dejó de abrir después de varios días

Con un Personal Team gratuito, Apple indica que los perfiles de aprovisionamiento vencen a los 7 días. Conecta el iPhone y vuelve a ejecutar la app desde Xcode. Una membresía de Apple Developer elimina esa limitación de siete días para este flujo de firma.

### XcodeGen borró un ajuste

Los cambios estructurales y de compilación persistentes deben hacerse en `project.yml`. El archivo `.xcodeproj` es generado y no forma parte del repositorio.

## Referencias de Apple

- [Ejecutar una app en un dispositivo físico](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)
- [Activar el modo de desarrollador](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
- [Comparar una cuenta gratuita y Apple Developer Program](https://developer.apple.com/support/compare-memberships/)
