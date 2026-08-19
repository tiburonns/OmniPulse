#!/usr/bin/env bash
set -euo pipefail

APP_NAME="OmniPulse"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-$ROOT_DIR/dist}"
DERIVED_DATA="$(mktemp -d "${TMPDIR:-/tmp}/OmniPulse-AltStore-DerivedData.XXXXXX")"
PACKAGE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/OmniPulse-AltStore-Package.XXXXXX")"

cleanup() {
  case "$DERIVED_DATA" in
    "${TMPDIR:-/tmp}"/OmniPulse-AltStore-DerivedData.*) /bin/rm -rf -- "$DERIVED_DATA" ;;
  esac
  case "$PACKAGE_ROOT" in
    "${TMPDIR:-/tmp}"/OmniPulse-AltStore-Package.*) /bin/rm -rf -- "$PACKAGE_ROOT" ;;
  esac
}
trap cleanup EXIT

command -v xcodegen >/dev/null || {
  echo "Falta XcodeGen. Instálalo con: brew install xcodegen" >&2
  exit 1
}

cd "$ROOT_DIR"
xcodegen generate --spec project.yml
xcodebuild \
  -project OmniPulse.xcodeproj \
  -scheme OmniPulse \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

APP_BUNDLE="$DERIVED_DATA/Build/Products/Release-iphoneos/$APP_NAME.app"
if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "No se encontró la aplicación compilada: $APP_BUNDLE" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Info.plist")"
BUILD_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_BUNDLE/Info.plist")"
MAIN_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_BUNDLE/Info.plist")"

mkdir -p "$PACKAGE_ROOT/Payload" "$OUTPUT_DIR"
/usr/bin/ditto "$APP_BUNDLE" "$PACKAGE_ROOT/Payload/$APP_NAME.app"

WATCH_BUNDLE="$PACKAGE_ROOT/Payload/$APP_NAME.app/Watch"
if [[ -d "$WATCH_BUNDLE" ]]; then
  mv "$WATCH_BUNDLE" "$PACKAGE_ROOT/Excluded-Watch"
fi

if [[ -d "$PACKAGE_ROOT/Payload/$APP_NAME.app/Watch" ]]; then
  echo "No se pudo excluir el paquete de Apple Watch." >&2
  exit 1
fi

if find "$PACKAGE_ROOT/Payload" \( -name '_CodeSignature' -o -name 'embedded.mobileprovision' \) -print -quit | grep -q .; then
  echo "El paquete contiene una firma o perfil y no se publicará." >&2
  exit 1
fi

ARCHITECTURES="$(lipo -archs "$PACKAGE_ROOT/Payload/$APP_NAME.app/$MAIN_EXECUTABLE")"
if [[ " $ARCHITECTURES " != *" arm64 "* ]]; then
  echo "El ejecutable iOS no contiene arm64: $ARCHITECTURES" >&2
  exit 1
fi

OUTPUT_FILE="$OUTPUT_DIR/OmniPulse-AltStore-v$VERSION.ipa"
if [[ -e "$OUTPUT_FILE" ]]; then
  echo "El archivo ya existe; muévelo o elimínalo antes de repetir: $OUTPUT_FILE" >&2
  exit 1
fi

(
  cd "$PACKAGE_ROOT"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry "$OUTPUT_FILE" Payload
)

if unzip -Z1 "$OUTPUT_FILE" | grep -Eq '(^|/)Watch/|_CodeSignature|embedded\.mobileprovision|^__MACOSX/'; then
  echo "La validación final encontró contenido no permitido en la IPA." >&2
  exit 1
fi

echo "IPA compatible con AltStore creada correctamente."
echo "Versión: $VERSION ($BUILD_VERSION)"
echo "Arquitecturas iOS: $ARCHITECTURES"
echo "Archivo: $OUTPUT_FILE"
shasum -a 256 "$OUTPUT_FILE"
