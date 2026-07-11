#!/usr/bin/env python3
"""Require a pushed release tag to exactly match pubspec's package version."""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PUBSPEC = ROOT / "pubspec.yaml"
VERSION = re.compile(
    r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    r"(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
    r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
)


def pubspec_version(path: Path = PUBSPEC) -> str:
    matches = []
    for line in path.read_text("utf-8").splitlines():
        match = re.fullmatch(r"version:\s*([^\s#]+)\s*(?:#.*)?", line)
        if match:
            matches.append(match.group(1))
    if len(matches) != 1 or VERSION.fullmatch(matches[0]) is None:
        raise ValueError("pubspec.yaml must contain one valid unquoted package version")
    return matches[0]


def expected_tag(path: Path = PUBSPEC) -> str:
    return f"v{pubspec_version(path)}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", default=os.environ.get("GITHUB_REF_NAME"))
    parser.add_argument(
        "--event-name", default=os.environ.get("GITHUB_EVENT_NAME", "local")
    )
    args = parser.parse_args()
    if args.event_name == "workflow_dispatch" and not args.tag:
        print("Manual release-readiness run: package tag equality is not applicable.")
        return 0
    if not args.tag:
        print("release tag verification failed: no tag was supplied", file=sys.stderr)
        return 1
    try:
        expected = expected_tag()
    except (OSError, ValueError) as error:
        print(f"release tag verification failed: {error}", file=sys.stderr)
        return 1
    if args.tag != expected:
        print(
            f"release tag verification failed: expected {expected!r}, got {args.tag!r}",
            file=sys.stderr,
        )
        return 1
    print(f"Release tag {args.tag} exactly matches pubspec version.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
