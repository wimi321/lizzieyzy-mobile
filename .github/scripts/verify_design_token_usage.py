#!/usr/bin/env python3
"""Reject presentation colors that bypass the versioned design tokens."""

from __future__ import annotations

import pathlib
import re
import sys


ROOT = pathlib.Path(__file__).resolve().parents[2]
SCOPES = (ROOT / "lib" / "app", ROOT / "lib" / "features")
COLOR_CONSTRUCTOR = re.compile(r"\bColor\s*\(")
MATERIAL_COLOR = re.compile(r"\bColors\.([A-Za-z0-9_]+)")
ALLOWED_MATERIAL_COLORS = {"transparent"}


def main() -> int:
    violations: list[str] = []
    checked = 0
    for scope in SCOPES:
        for path in sorted(scope.rglob("*.dart")):
            checked += 1
            for line_number, line in enumerate(
                path.read_text(encoding="utf-8").splitlines(), start=1
            ):
                if COLOR_CONSTRUCTOR.search(line):
                    violations.append(
                        f"{path.relative_to(ROOT)}:{line_number}: raw Color()"
                    )
                for match in MATERIAL_COLOR.finditer(line):
                    if match.group(1) not in ALLOWED_MATERIAL_COLORS:
                        violations.append(
                            f"{path.relative_to(ROOT)}:{line_number}: "
                            f"raw Colors.{match.group(1)}"
                        )
    if violations:
        print("Presentation colors must come from lib/design_system tokens:")
        print("\n".join(violations))
        return 1
    print(f"Design-token color boundary verified across {checked} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
