#!/usr/bin/env python3
"""Read-only integrity check for Visual Benchmark v1."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
BENCHMARK_ROOT = REPOSITORY_ROOT / "design" / "visual-benchmarks" / "v1"
MANIFEST_PATH = BENCHMARK_ROOT / "manifest.json"
CHECKSUMS_PATH = BENCHMARK_ROOT / "checksums.sha256"
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
CHECKSUM_LINE_PATTERN = re.compile(r"^([0-9a-f]{64})  ([^\r\n]+)$")
IMAGE_DIRECTORIES = ("north-star", "screens", "implementation")


class VerificationError(RuntimeError):
    """Raised when a benchmark invariant is broken."""


def fail(message: str) -> None:
    raise VerificationError(message)


def require_mapping(value: Any, location: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(f"{location} must be a JSON object")
    return value


def require_list(value: Any, location: str) -> list[Any]:
    if not isinstance(value, list):
        fail(f"{location} must be a JSON array")
    return value


def require_string(value: Any, location: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{location} must be a non-empty string")
    return value


def safe_image_path(relative_name: str, location: str) -> Path:
    relative = Path(relative_name)
    if relative.is_absolute() or ".." in relative.parts:
        fail(f"{location} contains an unsafe path: {relative_name}")
    if relative.suffix.lower() != ".png":
        fail(f"{location} must reference a PNG: {relative_name}")
    if not relative.parts or relative.parts[0] not in IMAGE_DIRECTORIES:
        fail(f"{location} is outside the registered image directories")
    resolved = (BENCHMARK_ROOT / relative).resolve()
    try:
        resolved.relative_to(BENCHMARK_ROOT.resolve())
    except ValueError:
        fail(f"{location} escapes the benchmark directory")
    return resolved


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def register_entry(
    entry: Any,
    location: str,
    registered: dict[str, str],
) -> dict[str, Any]:
    item = require_mapping(entry, location)
    relative_name = require_string(item.get("file"), f"{location}.file")
    declared_hash = require_string(item.get("sha256"), f"{location}.sha256")
    if not SHA256_PATTERN.fullmatch(declared_hash):
        fail(f"{location}.sha256 must be lowercase hexadecimal SHA-256")
    if relative_name in registered:
        fail(f"duplicate manifest file reference: {relative_name}")
    path = safe_image_path(relative_name, f"{location}.file")
    if not path.is_file():
        fail(f"registered image is missing: {relative_name}")
    actual_hash = digest(path)
    if actual_hash != declared_hash:
        fail(
            f"manifest hash mismatch for {relative_name}: "
            f"expected {declared_hash}, got {actual_hash}"
        )
    registered[relative_name] = declared_hash
    return item


def load_manifest() -> dict[str, Any]:
    try:
        raw = MANIFEST_PATH.read_text(encoding="utf-8")
    except OSError as error:
        fail(f"cannot read {MANIFEST_PATH.relative_to(REPOSITORY_ROOT)}: {error}")
    try:
        return require_mapping(json.loads(raw), "manifest")
    except json.JSONDecodeError as error:
        fail(f"manifest.json is invalid JSON: {error}")


def manifest_entries(manifest: dict[str, Any]) -> dict[str, str]:
    if manifest.get("schemaVersion") != 1:
        fail("manifest.schemaVersion must be 1")
    require_string(manifest.get("benchmarkVersion"), "manifest.benchmarkVersion")
    require_string(manifest.get("product"), "manifest.product")

    selection = require_mapping(manifest.get("selection"), "manifest.selection")
    candidates = require_list(
        selection.get("candidates"), "manifest.selection.candidates"
    )
    if not candidates:
        fail("manifest.selection.candidates cannot be empty")

    registered: dict[str, str] = {}
    selected: list[dict[str, Any]] = []
    for index, entry in enumerate(candidates):
        location = f"manifest.selection.candidates[{index}]"
        item = register_entry(entry, location, registered)
        score = item.get("score")
        if isinstance(score, bool) or not isinstance(score, (int, float)):
            fail(f"{location}.score must be numeric")
        is_selected = item.get("selected")
        if not isinstance(is_selected, bool):
            fail(f"{location}.selected must be boolean")
        if is_selected:
            selected.append(item)
    if len(selected) != 1:
        fail(f"exactly one north-star candidate must be selected; found {len(selected)}")
    if selected[0]["score"] < 90:
        fail("the selected north-star candidate must score at least 90")

    screens = require_list(manifest.get("screens"), "manifest.screens")
    if not screens:
        fail("manifest.screens cannot be empty")
    screen_ids: set[str] = set()
    for index, entry in enumerate(screens):
        location = f"manifest.screens[{index}]"
        item = register_entry(entry, location, registered)
        screen_id = require_string(item.get("screenId"), f"{location}.screenId")
        if screen_id in screen_ids:
            fail(f"duplicate screenId: {screen_id}")
        screen_ids.add(screen_id)
        if item.get("status") != "approved":
            fail(f"{location}.status must be approved")
        require_string(item.get("promptId"), f"{location}.promptId")
        pixel_size = require_list(item.get("pixelSize"), f"{location}.pixelSize")
        if (
            len(pixel_size) != 2
            or any(isinstance(value, bool) or not isinstance(value, int) or value <= 0 for value in pixel_size)
        ):
            fail(f"{location}.pixelSize must contain two positive integers")

    evidence = manifest.get("implementationEvidence")
    if evidence is not None:
        evidence_object = require_mapping(evidence, "manifest.implementationEvidence")
        evidence_screens = require_list(
            evidence_object.get("screens"),
            "manifest.implementationEvidence.screens",
        )
        evidence_ids: set[str] = set()
        for index, entry in enumerate(evidence_screens):
            location = f"manifest.implementationEvidence.screens[{index}]"
            item = register_entry(entry, location, registered)
            screen_id = require_string(item.get("screenId"), f"{location}.screenId")
            if screen_id not in screen_ids:
                fail(f"implementation evidence references unknown screenId: {screen_id}")
            if screen_id in evidence_ids:
                fail(f"duplicate implementation evidence for screenId: {screen_id}")
            evidence_ids.add(screen_id)

    return registered


def checksum_entries() -> dict[str, str]:
    try:
        lines = CHECKSUMS_PATH.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        fail(
            f"cannot read {CHECKSUMS_PATH.relative_to(REPOSITORY_ROOT)}: {error}"
        )
    checksums: dict[str, str] = {}
    for line_number, line in enumerate(lines, start=1):
        if not line:
            continue
        match = CHECKSUM_LINE_PATTERN.fullmatch(line)
        if match is None:
            fail(f"invalid checksums.sha256 line {line_number}")
        declared_hash, relative_name = match.groups()
        if relative_name in checksums:
            fail(f"duplicate checksums.sha256 entry: {relative_name}")
        safe_image_path(relative_name, f"checksums.sha256:{line_number}")
        checksums[relative_name] = declared_hash
    return checksums


def discovered_images() -> set[str]:
    discovered: set[str] = set()
    for directory_name in IMAGE_DIRECTORIES:
        directory = BENCHMARK_ROOT / directory_name
        if not directory.is_dir():
            continue
        for path in directory.rglob("*.png"):
            discovered.add(path.relative_to(BENCHMARK_ROOT).as_posix())
    return discovered


def verify() -> None:
    registered = manifest_entries(load_manifest())
    checksums = checksum_entries()
    if registered != checksums:
        missing = sorted(set(registered) - set(checksums))
        extra = sorted(set(checksums) - set(registered))
        changed = sorted(
            name
            for name in set(registered) & set(checksums)
            if registered[name] != checksums[name]
        )
        fail(
            "manifest/checksums file set differs "
            f"(missing={missing}, extra={extra}, changed={changed})"
        )

    discovered = discovered_images()
    registered_names = set(registered)
    if discovered != registered_names:
        unregistered = sorted(discovered - registered_names)
        missing = sorted(registered_names - discovered)
        fail(
            "registered/actual PNG file set differs "
            f"(unregistered={unregistered}, missing={missing})"
        )

    for relative_name, declared_hash in checksums.items():
        actual_hash = digest(BENCHMARK_ROOT / relative_name)
        if actual_hash != declared_hash:
            fail(
                f"checksums.sha256 mismatch for {relative_name}: "
                f"expected {declared_hash}, got {actual_hash}"
            )

    print(
        "Visual Benchmark v1 verified: "
        f"{len(registered)} registered PNG files, one selected north star."
    )


def main() -> int:
    try:
        verify()
    except VerificationError as error:
        print(f"visual benchmark verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
