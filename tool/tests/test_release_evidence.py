from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool"))

import release_evidence  # noqa: E402


class ReleaseEvidenceTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_bundle_is_byte_identical_and_has_stable_metadata(self) -> None:
        source = self.root / "source"
        source.mkdir()
        (source / "b.txt").write_text("bravo\n", "utf-8")
        (source / "a.txt").write_text("alpha\n", "utf-8")
        first = self.root / "first.zip"
        second = self.root / "second.zip"
        values = [f"evidence={source}"]
        release_evidence.deterministic_bundle(first, values)
        release_evidence.deterministic_bundle(second, values)
        self.assertEqual(first.read_bytes(), second.read_bytes())
        with zipfile.ZipFile(first) as archive:
            self.assertEqual(
                archive.namelist(), ["evidence/a.txt", "evidence/b.txt"]
            )
            self.assertTrue(all(info.date_time == (1980, 1, 1, 0, 0, 0) for info in archive.infolist()))

    def test_custom_predicate_is_explicitly_not_build_provenance(self) -> None:
        candidate = self.root / "candidate.apk"
        candidate.write_bytes(b"apk")
        evidence = self.root / "sbom.json"
        evidence.write_text("{}\n", "utf-8")
        digests = self.root / "digests.json"
        release_evidence.hash_artifacts(digests, [f"android-apk={candidate}"])
        output = self.root / "predicate.json"
        environment = {
            "GITHUB_SHA": "a" * 40,
            "GITHUB_REPOSITORY": "wimi321/lizzieyzy-mobile",
            "GITHUB_REF": "refs/tags/v0.1.0+1",
        }
        with mock.patch.dict(os.environ, environment, clear=False):
            release_evidence.integrity_predicate(
                output, digests, [f"sbom={evidence}"]
            )
        value = json.loads(output.read_text("utf-8"))
        self.assertFalse(value["buildProvenance"])
        self.assertEqual(
            value["claimScope"], "digest-binding-and-evidence-completeness-only"
        )
        self.assertNotIn("predicateType", value)
        self.assertNotIn("slsa.dev", output.read_text("utf-8"))

    def test_checksums_use_logical_paths_not_host_paths(self) -> None:
        source = self.root / "artifact.bin"
        source.write_bytes(b"content")
        output = self.root / "checksums.sha256"
        release_evidence.checksums(output, [f"candidate={source}"])
        line = output.read_text("utf-8").strip()
        self.assertTrue(line.endswith("  candidate/artifact.bin"))
        self.assertNotIn(str(self.root), line)


if __name__ == "__main__":
    unittest.main()
