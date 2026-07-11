#!/usr/bin/env python3
"""Validate the reviewed Gradle distribution and dependency hash lock."""

from __future__ import annotations

import hashlib
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WRAPPER = ROOT / "android" / "gradle" / "wrapper" / "gradle-wrapper.properties"
METADATA = ROOT / "android" / "gradle" / "verification-metadata.xml"
WRAPPER_INTEGRITY = (
    ROOT / "android" / "gradle" / "wrapper" / "gradle-wrapper-integrity.json"
)
NAMESPACE = "https://schema.gradle.org/dependency-verification"
EXPECTED_WRAPPER = {
    "distributionUrl": "https\\://services.gradle.org/distributions/gradle-8.13-all.zip",
    "distributionSha256Sum": "fba8464465835e74f7270bbf43d6d8a8d7709ab0a43ce1aa3323f73e9aa0c612",
}
EXPECTED_WRAPPER_FILES = {
    "android/gradlew",
    "android/gradlew.bat",
    "android/gradle/wrapper/gradle-wrapper.jar",
    "android/gradle/wrapper/gradle-wrapper.properties",
}


def fail(message: str) -> None:
    raise RuntimeError(message)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_wrapper_files() -> None:
    manifest = json.loads(WRAPPER_INTEGRITY.read_text("utf-8"))
    if manifest.get("schemaVersion") != 1:
        fail("Gradle wrapper integrity manifest must use schemaVersion 1")
    distribution = manifest.get("distribution")
    if distribution != {
        "url": EXPECTED_WRAPPER["distributionUrl"].replace("\\:", ":"),
        "sha256": EXPECTED_WRAPPER["distributionSha256Sum"],
    }:
        fail("Gradle wrapper integrity manifest has an unreviewed distribution")
    entries = manifest.get("files")
    if not isinstance(entries, list):
        fail("Gradle wrapper integrity manifest files must be an array")
    paths: set[str] = set()
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get("path"), str):
            fail("Gradle wrapper integrity manifest contains an invalid entry")
        relative = entry["path"]
        if relative in paths:
            fail(f"Gradle wrapper integrity manifest repeats {relative}")
        paths.add(relative)
        path = ROOT / relative
        if not path.is_file() or path.is_symlink():
            fail(f"Gradle wrapper file is missing or unsafe: {relative}")
        digest = entry.get("sha256")
        if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
            fail(f"Gradle wrapper file has an invalid digest: {relative}")
        if sha256_file(path) != digest:
            fail(f"Gradle wrapper file digest changed: {relative}")
        if path.stat().st_size != entry.get("bytes"):
            fail(f"Gradle wrapper file size changed: {relative}")
        executable = bool(path.stat().st_mode & 0o111)
        if executable != entry.get("executable"):
            fail(f"Gradle wrapper executable mode changed: {relative}")
    if paths != EXPECTED_WRAPPER_FILES:
        fail(f"Gradle wrapper file set changed: {sorted(paths)}")


def main() -> int:
    try:
        verify_wrapper_files()
        properties = {}
        for line in WRAPPER.read_text("utf-8").splitlines():
            if "=" in line:
                name, value = line.split("=", 1)
                properties[name] = value
        for name, expected in EXPECTED_WRAPPER.items():
            if properties.get(name) != expected:
                fail(f"unreviewed Gradle wrapper {name}: {properties.get(name)!r}")

        tree = ET.parse(METADATA)
        root = tree.getroot()
        namespace = f"{{{NAMESPACE}}}"
        if root.tag != namespace + "verification-metadata":
            fail("unexpected Gradle verification metadata namespace")
        configuration = root.find(namespace + "configuration")
        if configuration is None:
            fail("Gradle verification metadata has no configuration")
        verify_metadata = configuration.find(namespace + "verify-metadata")
        if verify_metadata is None or verify_metadata.text != "true":
            fail("Gradle metadata verification must remain enabled")
        if configuration.find(namespace + "trusted-artifacts") is not None:
            fail("broad trusted-artifacts bypasses are forbidden")
        if configuration.find(namespace + "ignored-keys") is not None:
            fail("ignored dependency-signing keys are forbidden")

        components = root.findall(f"{namespace}components/{namespace}component")
        if len(components) < 100:
            fail("Gradle dependency hash lock is unexpectedly incomplete")
        coordinates: set[tuple[str, str, str]] = set()
        artifact_count = 0
        for component in components:
            coordinate = (
                component.get("group", ""),
                component.get("name", ""),
                component.get("version", ""),
            )
            if not all(coordinate) or coordinate in coordinates:
                fail(f"invalid or duplicate Gradle component: {coordinate}")
            coordinates.add(coordinate)
            artifacts = component.findall(namespace + "artifact")
            if not artifacts:
                fail(f"Gradle component has no verified artifacts: {coordinate}")
            for artifact in artifacts:
                artifact_count += 1
                hashes = artifact.findall(namespace + "sha256")
                if not hashes:
                    fail(f"Gradle artifact has no SHA-256: {coordinate}")
                for digest in hashes:
                    if re.fullmatch(r"[0-9a-f]{64}", digest.get("value", "")) is None:
                        fail(f"Gradle artifact has an invalid SHA-256: {coordinate}")

        required = {
            ("com.google.mlkit", "text-recognition", "16.0.1"),
            ("io.flutter", "flutter_embedding_release", "1.0.0-425cfb54d01a9472b3e81d9e76fd63a4a44cfbcb"),
        }
        missing = required - coordinates
        if missing:
            fail(f"Gradle dependency hash lock omits release-critical modules: {missing}")
    except (OSError, json.JSONDecodeError, ET.ParseError, RuntimeError) as error:
        print(f"Gradle integrity verification failed: {error}", file=sys.stderr)
        return 1
    print(
        f"Verified Gradle 8.13 distribution and {artifact_count} dependency artifacts."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
