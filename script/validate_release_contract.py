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

print(f"PASS: OmniPulse main {version} (build {build}); published AltStore {published}")
