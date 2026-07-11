#!/usr/bin/env python3
"""Verify the checked-in legacy GIB bytes with independent Python codecs."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "test" / "fixtures" / "gib_legacy_encodings.json"


def main() -> int:
    document = json.loads(FIXTURES.read_text("utf-8"))
    if document.get("schemaVersion") != 1:
        raise SystemExit("unsupported fixture schema")
    cases = document.get("cases")
    if not isinstance(cases, list) or not cases:
        raise SystemExit("fixture cases must be a non-empty array")
    for case in cases:
        case_id = case["id"]
        encoded = case["text"].encode(case["codec"], errors="strict")
        if encoded.hex() != case["hex"]:
            raise SystemExit(f"{case_id}: encoded bytes drifted")
        digest = hashlib.sha256(encoded).hexdigest()
        if digest != case["sha256"]:
            raise SystemExit(f"{case_id}: SHA-256 drifted")
        if encoded.decode(case["codec"], errors="strict") != case["text"]:
            raise SystemExit(f"{case_id}: codec round trip failed")
    print(f"Verified {len(cases)} legacy GIB encoding fixtures.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
