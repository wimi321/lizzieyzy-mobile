#!/usr/bin/env python3
"""Verify the deterministic test-only CJK golden font boundary."""

from __future__ import annotations

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EXPECTED = {
    "test/assets/LizzieYzyGoldenCjk.otf": (
        "c5391bfb7a6987e504622e9edf604acaa9c0a66bf1f2f07d36f5caf484652590"
    ),
    "test/assets/OFL-LICENSE.txt": (
        "6a73f9541c2de74158c0e7cf6b0a58ef774f5a780bf191f2d7ec9cc53efe2bf2"
    ),
}


def main() -> int:
    for relative, expected in EXPECTED.items():
        path = ROOT / relative
        if not path.is_file():
            raise SystemExit(f"missing golden font artifact: {relative}")
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != expected:
            raise SystemExit(f"golden font artifact hash mismatch: {relative}")

    font = ROOT / "test/assets/LizzieYzyGoldenCjk.otf"
    if font.stat().st_size > 1024 * 1024:
        raise SystemExit("test-only golden font unexpectedly exceeds 1 MiB")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if "LizzieYzyGoldenCjk" in pubspec or "test/assets" in pubspec:
        raise SystemExit("test-only golden font must not enter the app asset bundle")
    print("golden font boundary verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
