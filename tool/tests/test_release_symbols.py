from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))

import release_symbols  # noqa: E402


class ReleaseSymbolsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_manifest_verifies_every_archive_member(self) -> None:
        source = self.root / "mapping.txt"
        source.write_text("A -> a:\n", "utf-8")
        archive = self.root / "symbols.zip"
        release_symbols.write_archive(archive, [("r8/mapping.txt", source)])
        manifest = self.root / "symbols.json"
        release_symbols.write_manifest(
            manifest,
            "android",
            archive,
            [("r8/mapping.txt", source)],
            {"test": True},
        )
        release_symbols.verify_archive(archive, manifest)

    def test_verifier_rejects_member_digest_mismatch(self) -> None:
        archive = self.root / "symbols.zip"
        with zipfile.ZipFile(archive, "w") as output:
            output.writestr("flutter/app.android-arm64.symbols", b"symbols")
        manifest = self.root / "symbols.json"
        manifest.write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "platform": "android",
                    "archive": {
                        "file": archive.name,
                        "sha256": release_symbols.sha256_file(archive),
                        "bytes": archive.stat().st_size,
                    },
                    "files": [
                        {
                            "path": "flutter/app.android-arm64.symbols",
                            "sha256": hashlib.sha256(b"changed").hexdigest(),
                            "bytes": 7,
                        }
                    ],
                    "details": {},
                }
            )
            + "\n",
            "utf-8",
        )
        with self.assertRaises(release_symbols.SymbolError):
            release_symbols.verify_archive(archive, manifest)


if __name__ == "__main__":
    unittest.main()
