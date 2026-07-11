#!/usr/bin/env python3
"""Reject mutable third-party GitHub Action references."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
USES = re.compile(r"^\s*(?:-\s*)?uses:\s*([^\s#]+)", re.MULTILINE)
FULL_SHA = re.compile(r"^[^/@\s]+/[^/@\s]+@[0-9a-f]{40}$")
REVIEWED = {
    "actions/attest": "a1948c3f048ba23858d222213b7c278aabede763",
    "actions/checkout": "df4cb1c069e1874edd31b4311f1884172cec0e10",
    "actions/download-artifact": "3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c",
    "actions/setup-java": "0f481fcb613427c0f801b606911222b5b6f3083a",
    "actions/upload-artifact": "043fb46d1a93c77aae656e7c1c64a875d1fc6a0a",
    "subosito/flutter-action": "1a449444c387b1966244ae4d4f8c696479add0b2",
}


def main() -> int:
    failures: list[str] = []
    checked = 0
    for path in sorted(WORKFLOWS.glob("*.yml")):
        text = path.read_text("utf-8")
        for match in USES.finditer(text):
            reference = match.group(1)
            if reference.startswith("./") or reference.startswith("docker://"):
                continue
            checked += 1
            if FULL_SHA.fullmatch(reference) is None:
                line = text.count("\n", 0, match.start()) + 1
                failures.append(f"{path.relative_to(ROOT)}:{line}: {reference}")
                continue
            action, digest = reference.split("@", 1)
            if REVIEWED.get(action) != digest:
                line = text.count("\n", 0, match.start()) + 1
                failures.append(
                    f"{path.relative_to(ROOT)}:{line}: unreviewed {reference}"
                )
    if failures:
        print("mutable GitHub Action references are forbidden:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    print(f"Verified {checked} GitHub Action references are pinned to full SHAs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
