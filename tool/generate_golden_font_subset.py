#!/usr/bin/env python3
"""Build the test-only, human-readable CJK golden font subset.

The source must be Noto Sans CJK SC 2.004 (OFL-1.1). The generated font is
renamed because it is a modified OFL font. It is loaded only by Flutter widget
tests and is not declared as an application asset.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


EXPECTED_SHA256 = "2c76254f6fc379fddfce0a7e84fb5385bb135d3e399294f6eeb6680d0365b74b"
FAMILY = "LizzieYzy Golden CJK"
POSTSCRIPT_NAME = "LizzieYzyGoldenCJK-Regular"


def _characters(repo: Path) -> set[int]:
    codepoints = set(range(0x20, 0x7F))
    sources = [*repo.joinpath("lib").rglob("*.dart")]
    sources.append(repo / "lib/l10n/app_zh.arb")
    sources.extend(
        [
            repo / "test/golden_test.dart",
            repo / "test/support/review_screen_fixture.dart",
        ]
    )
    for source in sources:
        for character in source.read_text(encoding="utf-8"):
            if ord(character) >= 0x80:
                codepoints.add(ord(character))
    return codepoints


def _rename(font: TTFont) -> None:
    names = font["name"]
    renamed_ids = {1, 2, 3, 4, 6, 16, 17}
    names.names = [record for record in names.names if record.nameID not in renamed_ids]
    values = {
        1: FAMILY,
        2: "Regular",
        3: POSTSCRIPT_NAME,
        4: f"{FAMILY} Regular",
        6: POSTSCRIPT_NAME,
        16: FAMILY,
        17: "Regular",
    }
    for name_id, value in values.items():
        names.setName(value, name_id, 3, 1, 0x409)
        names.setName(value, name_id, 1, 0, 0)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("test/assets/LizzieYzyGoldenCjk.otf"),
    )
    parser.add_argument("--allow-unverified-source", action="store_true")
    args = parser.parse_args()

    source_bytes = args.source.read_bytes()
    digest = hashlib.sha256(source_bytes).hexdigest()
    if digest != EXPECTED_SHA256 and not args.allow_unverified_source:
        raise SystemExit(
            "Unexpected Noto source SHA-256. Refusing a non-reproducible font: "
            f"{digest}"
        )

    repo = Path(__file__).resolve().parents[1]
    output = args.output if args.output.is_absolute() else repo / args.output
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = [0, 1, 2, 3, 4, 5, 6, 13, 14, 16, 17]
    options.name_legacy = True
    options.name_languages = ["*"]
    options.recommended_glyphs = True
    options.notdef_outline = True

    font = TTFont(args.source, recalcTimestamp=False)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=_characters(repo))
    subsetter.subset(font)
    _rename(font)
    output.parent.mkdir(parents=True, exist_ok=True)
    font.save(output, reorderTables=True)
    print(f"wrote {output} ({output.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
