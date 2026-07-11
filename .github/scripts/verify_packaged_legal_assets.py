#!/usr/bin/env python3
"""Verify final Android/iOS packages embed the reviewed native legal assets."""

from __future__ import annotations

import argparse
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ASSETS = (
    "cocoapods_third_party_licenses.txt",
    "maven_third_party_licenses.txt",
)


def fail(message: str) -> None:
    raise RuntimeError(message)


def verify_apk(path: Path) -> None:
    if not path.is_file():
        fail(f"Android candidate is missing: {path}")
    try:
        with zipfile.ZipFile(path) as archive:
            names = archive.namelist()
            for filename in ASSETS:
                packaged = f"assets/flutter_assets/assets/legal/{filename}"
                if names.count(packaged) != 1:
                    fail(f"Android candidate must contain exactly one {packaged}")
                source = (ROOT / "assets" / "legal" / filename).read_bytes()
                if archive.read(packaged) != source:
                    fail(f"Android candidate contains stale legal asset: {filename}")
    except zipfile.BadZipFile as error:
        fail(f"Android candidate is not a valid APK: {error}")


def verify_ios_app(path: Path) -> None:
    if not path.is_dir():
        fail(f"iOS Runner.app is missing: {path}")
    root = path / "Frameworks" / "App.framework" / "flutter_assets" / "assets" / "legal"
    for filename in ASSETS:
        packaged = root / filename
        if not packaged.is_file():
            fail(f"iOS candidate omits legal asset: {filename}")
        source = (ROOT / "assets" / "legal" / filename).read_bytes()
        if packaged.read_bytes() != source:
            fail(f"iOS candidate contains stale legal asset: {filename}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--ios-app", type=Path)
    args = parser.parse_args()
    if args.apk is None and args.ios_app is None:
        parser.error("at least one of --apk or --ios-app is required")
    try:
        if args.apk is not None:
            verify_apk(args.apk)
        if args.ios_app is not None:
            verify_ios_app(args.ios_app)
    except (OSError, RuntimeError) as error:
        print(f"packaged legal asset verification failed: {error}", file=sys.stderr)
        return 1
    print("Packaged CocoaPods and Maven legal assets match reviewed sources.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
