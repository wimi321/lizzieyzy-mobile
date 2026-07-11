#!/usr/bin/env python3
"""Verify Pub/native license policy and emit the complete release notices."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Any

import sbom


ROOT = Path(__file__).resolve().parents[1]
NOTICE = ROOT / "docs" / "THIRD_PARTY_NOTICES.md"
ROOT_LICENSE = ROOT / "LICENSE"
COCOAPODS_LICENSES = ROOT / "assets" / "legal" / "cocoapods_third_party_licenses.txt"
MAVEN_LICENSES = ROOT / "assets" / "legal" / "maven_third_party_licenses.txt"
BRIDGE_LICENSE = (
    ROOT
    / "tool"
    / "katago_bridge"
    / "LICENSES"
    / "websockets-BSD-3-Clause.txt"
)
ALLOWED = {"Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "ISC", "MIT", "Zlib"}


def fail(message: str) -> None:
    raise sbom.SbomError(message)


def pub_graph() -> dict[str, Any]:
    return sbom.run_json(["flutter", "pub", "deps", "--json"])


def notice_rows(text: str) -> dict[str, tuple[str, str]]:
    rows: dict[str, tuple[str, str]] = {}
    for line in text.splitlines():
        if not line.startswith("| `"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 4 or not cells[0].startswith("`"):
            continue
        name = cells[0].strip("`")
        rows[name] = (cells[1], cells[3])
    return rows


def license_file(root: Path) -> Path | None:
    for filename in sbom.LICENSE_FILES:
        candidate = root / filename
        if candidate.is_file():
            return candidate
    return None


def verify(output: Path | None) -> None:
    if "Mozilla Public License Version 2.0" not in ROOT_LICENSE.read_text(
        "utf-8", errors="replace"
    ):
        fail("repository LICENSE is not the declared MPL-2.0 text")
    notice = NOTICE.read_text("utf-8")
    rows = notice_rows(notice)
    lock = sbom.parse_pub_lock()
    roots = sbom.package_roots()
    graph = pub_graph()
    packages = graph.get("packages")
    root_name = graph.get("root")
    if not isinstance(packages, list) or not isinstance(root_name, str):
        fail("dart pub deps returned invalid root/packages metadata")
    by_name = {
        entry["name"]: entry
        for entry in packages
        if isinstance(entry, dict) and isinstance(entry.get("name"), str)
    }
    root = by_name.get(root_name)
    if root is None or not isinstance(root.get("directDependencies"), list):
        fail("dart pub deps did not identify direct runtime dependencies")

    direct_hosted: list[str] = []
    for name in root["directDependencies"]:
        entry = by_name.get(name)
        if entry is None or entry.get("source") != "hosted":
            continue
        direct_hosted.append(name)
        locked = lock.get(name)
        if locked is None:
            fail(f"direct dependency {name} is absent from pubspec.lock")
        row = rows.get(name)
        if row is None:
            fail(f"direct runtime dependency {name} is missing from THIRD_PARTY_NOTICES")
        declared_version, declared_license = row
        if declared_version != locked.get("version"):
            fail(
                f"THIRD_PARTY_NOTICES version drift for {name}: "
                f"{declared_version!r} != {locked.get('version')!r}"
            )
        expression, _ = sbom.package_license(name, roots)
        if expression is None or expression not in declared_license:
            fail(
                f"THIRD_PARTY_NOTICES license drift for {name}: "
                f"detected {expression!r}, row={declared_license!r}"
            )

    bridge_components = sbom.parse_python_lock()
    for component in bridge_components:
        row = rows.get(component["name"])
        if row is None:
            fail(
                f"desktop bridge dependency {component['name']} is missing from "
                "THIRD_PARTY_NOTICES"
            )
        declared_version, declared_license = row
        expression = component["licenses"][0]["expression"]
        if declared_version != component["version"] or expression not in declared_license:
            fail(
                f"THIRD_PARTY_NOTICES drift for desktop bridge dependency "
                f"{component['name']}"
            )

    resolved: list[tuple[str, str, str, Path, str]] = []
    for name, locked in sorted(lock.items()):
        if locked.get("source") != "hosted":
            continue
        root_path = roots.get(name)
        if root_path is None:
            fail(f"resolved hosted package {name} is absent from package_config.json")
        path = license_file(root_path)
        if path is None:
            fail(f"resolved hosted package {name} has no LICENSE/COPYING file")
        text = path.read_text("utf-8", errors="replace")
        identifiers = sbom.license_ids(text)
        if not identifiers:
            fail(f"cannot classify license text for hosted package {name}")
        unsupported = set(identifiers) - ALLOWED
        if unsupported:
            fail(f"hosted package {name} has unapproved licenses: {sorted(unsupported)}")
        expression = " AND ".join(identifiers)
        resolved.append((name, locked.get("version", "unknown"), expression, path, text))

    required_notice_fragments = (
        "com.google.mlkit:text-recognition:16.0.1",
        "GoogleMLKit/TextRecognition",
        "MLKitVision",
        "https://developers.google.com/ml-kit/terms",
        "不由 Google",
    )
    for fragment in required_notice_fragments:
        if fragment not in notice:
            fail(f"THIRD_PARTY_NOTICES is missing the ML Kit boundary: {fragment}")

    native_assets = (
        (
            COCOAPODS_LICENSES,
            (
                "LizzieYZY Mobile CocoaPods licenses and notices",
                "GoogleMLKit | podspec SHA-1",
                "## MLKitCommon",
                "## google_mlkit_text_recognition",
            ),
        ),
        (
            MAVEN_LICENSES,
            (
                "LizzieYZY Mobile resolved Maven licenses and notices",
                "com.google.mlkit:text-recognition:16.0.1",
                "LicenseRef-Android-SDK-Terms",
                "LicenseRef-ML-Kit-Terms",
                "third_party_licenses.txt",
            ),
        ),
    )
    for path, fragments in native_assets:
        if not path.is_file():
            fail(f"generated native legal asset is missing: {path.relative_to(ROOT)}")
        text = path.read_text("utf-8", errors="strict")
        for fragment in fragments:
            if fragment not in text:
                fail(f"{path.relative_to(ROOT)} is incomplete: missing {fragment}")

    if "google_mlkit_text_recognition" in direct_hosted:
        pod_lock = (ROOT / "ios" / "Podfile.lock").read_text("utf-8")
        for pod in ("GoogleMLKit/TextRecognition", "MLKitVision"):
            if pod not in pod_lock:
                fail(f"ios/Podfile.lock does not resolve required native pod {pod}")
        plugin_root = roots["google_mlkit_text_recognition"]
        android_build = (plugin_root / "android" / "build.gradle").read_text("utf-8")
        if "com.google.mlkit:text-recognition:16.0.1" not in android_build:
            fail("the resolved ML Kit plugin changed its Android native artifact")

    if output is not None:
        output.parent.mkdir(parents=True, exist_ok=True)
        chunks = [
            "LizzieYZY Mobile complete resolved third-party licenses and notices\n",
            "Generated from Pub, CocoaPods, Maven, and the Python bridge lock.\n",
        ]
        # Flutter SDK packages share the SDK-level LICENSE. Resolve it from the
        # package root instead of embedding a machine path in the artifact.
        flutter_root = roots.get("flutter")
        if flutter_root is None:
            fail("Flutter package root is missing from package_config.json")
        sdk_license = flutter_root.parents[1] / "LICENSE"
        if not sdk_license.is_file():
            fail("Flutter SDK LICENSE is missing")
        chunks.extend(
            [
                "\n" + "=" * 78 + "\n",
                "Flutter SDK | BSD-3-Clause\n",
                "=" * 78 + "\n",
                sdk_license.read_text("utf-8", errors="replace").rstrip() + "\n",
            ]
        )
        for name, version, expression, _, text in resolved:
            chunks.extend(
                [
                    "\n" + "=" * 78 + "\n",
                    f"{name} {version} | {expression}\n",
                    "=" * 78 + "\n",
                    text.rstrip() + "\n",
                ]
            )
        chunks.extend(
            [
                "\n" + "=" * 78 + "\n",
                "websockets 16.0 | BSD-3-Clause | desktop bridge only\n",
                "=" * 78 + "\n",
                BRIDGE_LICENSE.read_text("utf-8", errors="strict").rstrip() + "\n",
            ]
        )
        for title, path in (
            ("CocoaPods native dependencies", COCOAPODS_LICENSES),
            ("Android Maven native dependencies", MAVEN_LICENSES),
        ):
            chunks.extend(
                [
                    "\n" + "#" * 78 + "\n",
                    f"{title}\n",
                    "#" * 78 + "\n",
                    path.read_text("utf-8", errors="strict").rstrip() + "\n",
                ]
            )
        output.write_text("".join(chunks), "utf-8")

    print(
        f"License policy verified: {len(direct_hosted)} direct runtime and "
        f"{len(resolved)} resolved hosted packages; "
        f"{len(bridge_components)} locked Python bridge package."
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        verify(args.output)
    except (OSError, subprocess.CalledProcessError, sbom.SbomError) as error:
        print(f"license verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
