#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "project.yml").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
source = json.loads((ROOT / "source.json").read_text(encoding="utf-8"))

versions = re.findall(r'CFBundleShortVersionString:\s*"([0-9.]+)"', project)
builds = re.findall(r'CFBundleVersion:\s*"([0-9]+)"', project)
if not versions or len(set(versions)) != 1:
    raise SystemExit(f"version contract failed: target versions diverge: {versions}")
if not builds or len(set(builds)) != 1:
    raise SystemExit(f"version contract failed: target builds diverge: {builds}")

version = versions[0]
build = builds[0]

# The committed Info.plists are generated artifacts, but they are also used by
# people who clone the repository before running XcodeGen. Keep them aligned
# with project.yml so a checkout never advertises a stale build.
import plistlib
for relative in [
    "OmniPulse/Resources/Info.plist",
    "OmniPulseMac/Info.plist",
    "OmniPulseWatch/Info.plist",
]:
    with (ROOT / relative).open("rb") as handle:
        info = plistlib.load(handle)
    if str(info.get("CFBundleShortVersionString")) != version:
        raise SystemExit(
            f"version contract failed: {relative} has "
            f"{info.get('CFBundleShortVersionString')} instead of {version}"
        )
    if str(info.get("CFBundleVersion")) != build:
        raise SystemExit(
            f"version contract failed: {relative} has build "
            f"{info.get('CFBundleVersion')} instead of {build}"
        )

required_permission_keys = [
    "NSBluetoothAlwaysUsageDescription",
    "NSBluetoothPeripheralUsageDescription",
    "NSLocalNetworkUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSLocationUsageDescription",
]
for locale in ("en", "es"):
    path = ROOT / "OmniPulse" / "Resources" / f"{locale}.lproj" / "InfoPlist.strings"
    if not path.exists():
        raise SystemExit(f"localization contract failed: missing {path.relative_to(ROOT)}")
    localized = path.read_text(encoding="utf-8")
    for key in required_permission_keys:
        if f'"{key}"' not in localized:
            raise SystemExit(
                f"localization contract failed: {path.relative_to(ROOT)} missing {key}"
            )

watch_snapshot = (ROOT / "Shared/WatchSnapshot.swift").read_text(encoding="utf-8")
watch_view = (ROOT / "OmniPulseWatch/WatchRootView.swift").read_text(encoding="utf-8")
roadmap = (ROOT / "docs/ROADMAP.md").read_text(encoding="utf-8")

for token in ["WatchSensorConnectionState", "connectionState", "fallbackName"]:
    if token not in watch_snapshot:
        raise SystemExit(f"watchOS contract failed: shared snapshot missing {token}")

if "watchLocalized" not in watch_view:
    raise SystemExit(
        "watchOS localization contract failed: WatchRootView is not localizing runtime copy"
    )

if "- [x] Companion watchOS" not in roadmap:
    raise SystemExit(
        "watchOS documentation contract failed: roadmap does not reflect the implemented companion"
    )

watch_localization_keys = ["Escaneando","Escaneo detenido","Detener","Iniciar","Guardar lote","Recientes (%lld)","Las detecciones del iPhone aparecerán aquí.","Actualizar","Origen","Señal","Visto","Conectando con el iPhone","Conexión con iPhone no disponible","Comando en espera del iPhone","Actualizado","Conectado al iPhone","Esperando al iPhone","%lld ESP32 conectados","Listo para conectar","Buscando sensor","Conectando a %@","Conectado a %@","Bluetooth no disponible","No se pudo conectar","Dispositivo sin nombre"]
for locale in ("en", "es"):
    localized = (
        ROOT / "OmniPulse" / "Resources" / f"{locale}.lproj" / "Localizable.strings"
    ).read_text(encoding="utf-8")
    for key in watch_localization_keys:
        if f'"{key}" =' not in localized:
            raise SystemExit(
                f"watchOS localization contract failed: {locale} missing {key}"
            )

expected = f"**Versión actual de desarrollo en `main`: {version} (build {build}).**"
if expected not in readme:
    raise SystemExit("version contract failed: README development version is stale")

app = source["apps"][0]
published_versions = app.get("versions", [])
if not published_versions:
    raise SystemExit("release contract failed: AltStore source has no versions")

seen = set()
for item in published_versions:
    item_version = item["version"]
    if item_version in seen:
        raise SystemExit(f"release contract failed: duplicate version {item_version}")
    seen.add(item_version)
    expected_prefix = (
        "https://github.com/tiburonns/OmniPulse/releases/download/"
        f"v{item_version}/"
    )
    if not item.get("downloadURL", "").startswith(expected_prefix):
        raise SystemExit(f"release contract failed: unexpected URL for {item_version}")
    if int(item.get("size", 0)) <= 0:
        raise SystemExit(f"release contract failed: invalid size for {item_version}")

def semver(value):
    return tuple(int(part) for part in value.split("."))

published = published_versions[0]["version"]
if semver(published) > semver(version):
    raise SystemExit(f"release contract failed: published {published} is newer than main {version}")

if "DEVELOPMENT_TEAM" in project:
    raise SystemExit("build contract failed: project.yml must not hardcode an Apple team")

analyzer = (ROOT / "OmniPulse/Services/WiFiChannelAnalyzer.swift").read_text(encoding="utf-8")
payload = (ROOT / "OmniPulse/Models/SensorPayload.swift").read_text(encoding="utf-8")
detection = (ROOT / "OmniPulse/Models/DetectionRecord.swift").read_text(encoding="utf-8")
protocol_doc = (ROOT / "docs/ESP32_PROTOCOL.md").read_text(encoding="utf-8")

required_analyzer_tokens = [
    'case six = "6 GHz"',
    "includePotentialDFS",
    "sixGHzPSCCandidates",
    "channelWidthMHz",
    "frequencyMHz",
]
for token in required_analyzer_tokens:
    if token not in analyzer:
        raise SystemExit(f"Wi-Fi analysis contract failed: missing {token}")

for token in ["frequencyMHz", "channelWidthMHz"]:
    if token not in payload:
        raise SystemExit(f"sensor payload contract failed: missing {token}")

for token in ["wifiFrequencyMHz", "wifiChannelWidthMHz"]:
    if token not in detection:
        raise SystemExit(f"history contract failed: missing {token}")

for token in ["frequencyMHz", "channelWidthMHz", "6 GHz", "DFS"]:
    if token not in protocol_doc:
        raise SystemExit(f"protocol documentation contract failed: missing {token}")

print(f"PASS: OmniPulse main {version} (build {build}); published AltStore {published}; advanced Wi-Fi contract present")
