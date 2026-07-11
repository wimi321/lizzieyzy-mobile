#!/usr/bin/env python3
"""Static fail-closed checks for release workflow security and evidence scope."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
CI = WORKFLOWS / "ci.yml"
RELEASE = WORKFLOWS / "release.yml"
EVIDENCE_TOOL = ROOT / "tool" / "release_evidence.py"


def fail(message: str) -> None:
    raise RuntimeError(message)


def checkout_blocks(path: Path) -> list[str]:
    lines = path.read_text("utf-8").splitlines()
    blocks: list[str] = []
    for index, line in enumerate(lines):
        if "uses: actions/checkout@" not in line:
            continue
        indent = len(line) - len(line.lstrip())
        block = [line]
        for candidate in lines[index + 1 :]:
            candidate_indent = len(candidate) - len(candidate.lstrip())
            if candidate.lstrip().startswith("-") and candidate_indent <= indent:
                break
            block.append(candidate)
        blocks.append("\n".join(block))
    return blocks


def require(text: str, pattern: str, message: str) -> None:
    if re.search(pattern, text, re.MULTILINE | re.DOTALL) is None:
        fail(message)


def main() -> int:
    try:
        ci = CI.read_text("utf-8")
        release = RELEASE.read_text("utf-8")
        evidence = EVIDENCE_TOOL.read_text("utf-8")
        checkouts = checkout_blocks(CI) + checkout_blocks(RELEASE)
        if not checkouts:
            fail("no checkout steps were found")
        for block in checkouts:
            if re.search(r"persist-credentials:\s*false", block) is None:
                fail("every checkout must set persist-credentials: false")

        require(ci, r"android-release:\s*\n\s+name: Android release build", "CI must build Android release")
        if "flutter build apk --debug" in ci or "app-debug.apk" in ci:
            fail("CI final-package job may not validate a debug APK")
        for required in (
            "flutter build apk --release",
            "build/app/outputs/flutter-apk/app-release.apk",
            "verify_packaged_legal_assets.py",
            "verify_android_permissions.sh",
            "release_symbols.py android",
        ):
            if required not in ci:
                fail(f"CI Android release contract omits {required}")
        if "--obfuscate" in ci or "--obfuscate" in release:
            fail("open-source release candidates must remain Dart-auditable")

        require(
            release,
            r"if: github\.event_name == 'push'\s*\n\s+run:.*verify_release_tag\.py",
            "tag-triggered release must verify the full pubspec version",
        )
        require(
            release,
            r"ios-release:.*Rerun approved macOS visual goldens.*flutter test test/golden_test\.dart.*flutter build ios --release",
            "release iOS job must rerun goldens before building",
        )
        for required in (
            "android-release-symbols.zip",
            "ios-release-symbols.zip",
            "gradle-wrapper-integrity.json",
            "gradle-wrapper.jar",
            "release-integrity-predicate.json",
            "release_evidence.py checksums",
            "release_evidence.py bundle",
            "LizzieYZY-Mobile-release-evidence.zip",
            "predicate-type: ${{ env.INTEGRITY_PREDICATE_TYPE }}",
            "predicate-path: build/sbom/release-integrity-predicate.json",
        ):
            if required not in release:
                fail(f"release evidence contract omits {required}")
        if "release-integrity.intoto.json" in release:
            fail("legacy self-authored SLSA-like integrity statements are forbidden")
        if "https://slsa.dev/provenance/v1" in evidence:
            fail("digest-only integrity predicate may not claim SLSA provenance")
        if '"buildProvenance": False' not in evidence:
            fail("custom integrity predicate must explicitly deny build-provenance scope")
    except (OSError, RuntimeError) as error:
        print(f"release workflow verification failed: {error}", file=sys.stderr)
        return 1
    print(
        f"Verified {len(checkouts)} credential-isolated checkouts and release evidence contracts."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
