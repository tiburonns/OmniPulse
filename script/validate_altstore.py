#!/usr/bin/env python3
import json
import plistlib
import sys
import zipfile
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: validate_altstore.py <ipa> <source.json>")

ipa_path = Path(sys.argv[1])
source_path = Path(sys.argv[2])

with zipfile.ZipFile(ipa_path) as archive:
    names = archive.namelist()
    info_path = next(
        name for name in names
        if name.startswith("Payload/") and name.endswith(".app/Info.plist")
    )
    info = plistlib.loads(archive.read(info_path))

    forbidden = [
        name for name in names
        if "/Watch/" in name
        or name.endswith("/Watch")
        or "_CodeSignature/" in name
        or name.endswith("embedded.mobileprovision")
        or name.startswith("__MACOSX/")
    ]
    if forbidden:
        raise SystemExit(f"IPA contains forbidden files: {forbidden[:5]}")

source = json.loads(source_path.read_text(encoding="utf-8"))
app = source["apps"][0]
versions = app.get("versions", [])
if not versions:
    raise SystemExit("AltStore source has no versions")

latest = versions[0]
version = str(info["CFBundleShortVersionString"])
build = str(info["CFBundleVersion"])
bundle_id = str(info["CFBundleIdentifier"])
min_os = str(info.get("MinimumOSVersion", "17.0"))
expected_url = (
    "https://github.com/tiburonns/OmniPulse/releases/download/"
    f"v{version}/OmniPulse-AltStore-v{version}.ipa"
)

checks = {
    "bundleIdentifier": (app.get("bundleIdentifier"), bundle_id),
    "version": (latest.get("version"), version),
    "buildVersion": (latest.get("buildVersion"), build),
    "minOSVersion": (latest.get("minOSVersion"), min_os),
    "downloadURL": (latest.get("downloadURL"), expected_url),
}

for name, (actual, expected) in checks.items():
    if str(actual) != expected:
        raise SystemExit(f"{name} mismatch: {actual!r} != {expected!r}")

if int(latest.get("size", 0)) != ipa_path.stat().st_size:
    raise SystemExit("IPA byte size does not match AltStore source")

actual_privacy = {
    key: value
    for key, value in info.items()
    if key.endswith("UsageDescription") and isinstance(value, str)
}
if latest.get("privacy", {}) != actual_privacy:
    raise SystemExit("AltStore privacy declarations do not match Info.plist")

if latest.get("entitlements", []) != []:
    raise SystemExit("Unsigned AltStore build must not declare custom entitlements")

print(f"PASS: OmniPulse {version} ({build}) IPA and AltStore source agree")
