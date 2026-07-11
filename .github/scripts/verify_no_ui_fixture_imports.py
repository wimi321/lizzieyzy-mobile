#!/usr/bin/env python3
"""Keep production feature code independent from visual/demo fixtures."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
FEATURES = ROOT / "lib" / "features"
FIXTURE = FEATURES / "fixtures" / "ui_fixtures.dart"
REFERENCE = re.compile(
    r"^\s*(?:import|export|part)\s+['\"][^'\"]*ui_fixtures(?:\.dart)?['\"]",
    re.MULTILINE,
)


def main() -> int:
    if not FIXTURE.is_file():
        print(
            "fixture guard failed: lib/features/fixtures/ui_fixtures.dart must remain "
            "available for tests and design evidence",
            file=sys.stderr,
        )
        return 1
    violations: list[str] = []
    scanned = 0
    for path in sorted(FEATURES.rglob("*.dart")):
        if path == FIXTURE:
            continue
        scanned += 1
        if REFERENCE.search(path.read_text("utf-8")):
            violations.append(path.relative_to(ROOT).as_posix())
    if violations:
        print(
            "fixture guard failed: production feature files reference ui_fixtures:",
            file=sys.stderr,
        )
        for violation in violations:
            print(f"  - {violation}", file=sys.stderr)
        return 1
    print(
        f"Fixture import guard verified {scanned} feature files; "
        "ui_fixtures.dart remains test/design-only."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
