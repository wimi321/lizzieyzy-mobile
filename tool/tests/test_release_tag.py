from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / ".github" / "scripts" / "verify_release_tag.py"
SPEC = importlib.util.spec_from_file_location("verify_release_tag", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
verify_release_tag = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(verify_release_tag)


class ReleaseTagTest(unittest.TestCase):
    def test_full_pubspec_version_including_build_metadata_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            pubspec = Path(temporary) / "pubspec.yaml"
            pubspec.write_text("name: app\nversion: 1.2.3+45\n", "utf-8")
            self.assertEqual(verify_release_tag.expected_tag(pubspec), "v1.2.3+45")

    def test_ambiguous_or_quoted_version_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            pubspec = Path(temporary) / "pubspec.yaml"
            pubspec.write_text('version: "1.2.3"\n', "utf-8")
            with self.assertRaises(ValueError):
                verify_release_tag.pubspec_version(pubspec)


if __name__ == "__main__":
    unittest.main()
