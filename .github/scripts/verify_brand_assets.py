#!/usr/bin/env python3
"""Read-only integrity and platform-size checks for Brand Benchmark v1."""

from __future__ import annotations

import hashlib
import json
import os
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "design" / "brand" / "v1"
MANIFEST = BRAND / "manifest.json"
IOS_SET = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
ANDROID_SIZES = {
    "mipmap-mdpi/ic_launcher.png": 48,
    "mipmap-hdpi/ic_launcher.png": 72,
    "mipmap-xhdpi/ic_launcher.png": 96,
    "mipmap-xxhdpi/ic_launcher.png": 144,
    "mipmap-xxxhdpi/ic_launcher.png": 192,
}


class VerificationError(RuntimeError):
    pass


def fail(message: str) -> None:
    raise VerificationError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def png_info(path: Path) -> tuple[int, int, int, bool]:
    data = path.read_bytes()
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        fail(f"not a valid PNG: {path.relative_to(ROOT)}")
    width, height = struct.unpack(">II", data[16:24])
    color_type = data[25]
    has_alpha = color_type in (4, 6) or b"tRNS" in data
    return width, height, color_type, has_alpha


def require_mapping(value: Any, name: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(f"{name} must be an object")
    return value


def require_file_hash(entry: Any, name: str) -> Path:
    item = require_mapping(entry, name)
    relative = item.get("file")
    expected = item.get("sha256")
    if not isinstance(relative, str) or not relative or Path(relative).is_absolute():
        fail(f"{name}.file must be a safe relative path")
    if ".." in Path(relative).parts:
        fail(f"{name}.file escapes the brand directory")
    if not isinstance(expected, str) or len(expected) != 64:
        fail(f"{name}.sha256 must be a SHA-256 string")
    path = BRAND / relative
    if not path.is_file():
        fail(f"missing brand asset: {relative}")
    actual = digest(path)
    if actual != expected:
        fail(f"hash mismatch for {relative}: expected {expected}, got {actual}")
    return path


def verify_manifest() -> None:
    manifest = require_mapping(json.loads(MANIFEST.read_text("utf-8")), "manifest")
    if manifest.get("schemaVersion") != 1:
        fail("manifest.schemaVersion must be 1")
    candidates = manifest.get("candidates")
    if not isinstance(candidates, list) or len(candidates) != 3:
        fail("manifest.candidates must contain exactly three candidates")
    selected = []
    for index, candidate in enumerate(candidates):
        item = require_mapping(candidate, f"candidates[{index}]")
        require_file_hash(item, f"candidates[{index}]")
        if item.get("selected") is True:
            selected.append(item)
    if len(selected) != 1 or selected[0].get("score", 0) < 90:
        fail("exactly one candidate scoring at least 90 must be selected")

    source = require_file_hash(manifest.get("source"), "source")
    width, height, _, has_alpha = png_info(source)
    if (width, height) != (1024, 1024):
        fail("app-icon-source.png must be 1024x1024")
    if has_alpha:
        fail("the iOS marketing icon source must not contain alpha")

    generator = manifest.get("platformGeneration")
    if not isinstance(generator, str) or not generator:
        fail("manifest.platformGeneration is required")
    script = ROOT / generator
    if not script.is_file() or not os.access(script, os.X_OK):
        fail("the platform icon generator must exist and be executable")


def verify_ios() -> int:
    contents = json.loads((IOS_SET / "Contents.json").read_text("utf-8"))
    images = contents.get("images")
    if not isinstance(images, list) or not images:
        fail("iOS AppIcon Contents.json has no images")
    checked: set[str] = set()
    for item in images:
        filename = item.get("filename")
        size = item.get("size")
        scale = item.get("scale")
        if not all(isinstance(value, str) for value in (filename, size, scale)):
            fail("every iOS icon entry needs filename, size, and scale")
        logical = float(size.split("x", 1)[0])
        multiplier = int(scale.removesuffix("x"))
        expected = round(logical * multiplier)
        path = IOS_SET / filename
        width, height, _, has_alpha = png_info(path)
        if (width, height) != (expected, expected):
            fail(f"wrong iOS icon size for {filename}: {width}x{height}")
        if has_alpha:
            fail(f"iOS icon must not contain alpha: {filename}")
        checked.add(filename)
    return len(checked)


def verify_android() -> int:
    for relative, expected in ANDROID_SIZES.items():
        width, height, _, _ = png_info(ANDROID_RES / relative)
        if (width, height) != (expected, expected):
            fail(f"wrong Android icon size for {relative}: {width}x{height}")

    v26 = ANDROID_RES / "mipmap-anydpi-v26" / "ic_launcher.xml"
    v33 = ANDROID_RES / "mipmap-anydpi-v33" / "ic_launcher.xml"
    for path in (v26, v33):
        if ET.parse(path).getroot().tag != "adaptive-icon":
            fail(f"invalid adaptive icon XML: {path.relative_to(ROOT)}")
    if "monochrome" not in v33.read_text("utf-8"):
        fail("Android 13 icon must declare a monochrome drawable")
    return len(ANDROID_SIZES) + 2


def main() -> int:
    try:
        verify_manifest()
        ios_count = verify_ios()
        android_count = verify_android()
    except (OSError, ValueError, json.JSONDecodeError, ET.ParseError, VerificationError) as error:
        print(f"brand asset verification failed: {error}", file=sys.stderr)
        return 1
    print(
        "Brand Benchmark v1 verified: "
        f"{ios_count} iOS renditions and {android_count} Android assets."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
