from __future__ import annotations

import hashlib
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from katago_bridge.manifest import ManifestError, build_manifests, write_manifest


class ManifestTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.engine = self.root / "katago"
        self.config = self.root / "analysis.cfg"
        self.model = self.root / "normal.bin.gz"
        self.human_model = self.root / "human.bin.gz"
        self.engine.write_bytes(b"engine artifact")
        self.config.write_text(_PRIVATE_ANALYSIS_CONFIG)
        self.model.write_bytes(b"normal analysis model")
        self.human_model.write_bytes(b"HumanSL model")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_hashes_engine_normal_model_and_human_model_independently(self) -> None:
        sentinel = "must-never-appear-in-the-manifest"
        with mock.patch.dict(
            os.environ, {"LIZZIEYZY_BRIDGE_TOKEN": sentinel}, clear=False
        ):
            manifests = self._manifests(human_style_ranks=("3k", "1d"))
        serialized = json.dumps(
            {"service": manifests.service, "audit": manifests.audit}, sort_keys=True
        )
        self.assertNotIn(sentinel, serialized)
        self.assertNotIn("bearerToken", serialized)
        self.assertEqual(
            manifests.audit["artifacts"]["engine"]["sha256"],
            hashlib.sha256(self.engine.read_bytes()).hexdigest(),
        )
        self.assertEqual(
            manifests.audit["artifacts"]["analysisConfig"]["sha256"],
            hashlib.sha256(self.config.read_bytes()).hexdigest(),
        )
        normal_sha = hashlib.sha256(self.model.read_bytes()).hexdigest()
        human_sha = hashlib.sha256(self.human_model.read_bytes()).hexdigest()
        self.assertEqual(manifests.service["model"]["sha256"], normal_sha)
        self.assertEqual(manifests.service["model"]["humanModelSha256"], human_sha)
        self.assertEqual(
            manifests.audit["artifacts"]["humanModel"]["sha256"], human_sha
        )
        self.assertNotEqual(normal_sha, human_sha)
        self.assertEqual(
            set(manifests.service),
            {"schemaVersion", "endpoint", "reportAnalysisWinratesAs", "model"},
        )

        service_output = self.root / "service-manifest.json"
        audit_output = self.root / "bridge-artifact-manifest.json"
        write_manifest(service_output, manifests.service)
        write_manifest(audit_output, manifests.audit)
        self.assertEqual(json.loads(service_output.read_text()), manifests.service)
        self.assertEqual(json.loads(audit_output.read_text()), manifests.audit)
        self.assertEqual(
            manifests.audit["serviceManifestSha256"],
            hashlib.sha256(service_output.read_bytes()).hexdigest(),
        )

    def test_human_ranks_require_a_separate_human_model(self) -> None:
        with self.assertRaisesRegex(ManifestError, "independent HumanSL model"):
            build_manifests(
                endpoint="wss://gpu.example.test/v1",
                report_analysis_winrates_as="SIDETOMOVE",
                engine=self.engine,
                katago_config=self.config,
                model=self.model,
                human_model=None,
                model_id="kata-normal",
                display_name="KataGo Normal + HumanSL",
                engine_version="1.16.5",
                model_version="b18c384",
                model_license="CC-BY-4.0",
                human_style_ranks=("3k",),
            )

    def test_manifest_rejects_endpoint_credentials_and_query_secrets(self) -> None:
        unsafe = [
            "wss://token@gpu.example.test/v1",
            "wss://gpu.example.test/v1?token=no",
            "ws://gpu.example.test/v1",
        ]
        for endpoint in unsafe:
            with self.subTest(endpoint=endpoint):
                with self.assertRaises(ManifestError):
                    self._manifests(endpoint=endpoint)

    def test_perspective_is_derived_from_one_unique_config_value(self) -> None:
        derived = self._manifests(report_analysis_winrates_as=None)
        self.assertEqual(derived.service["reportAnalysisWinratesAs"], "SIDETOMOVE")
        with self.assertRaisesRegex(ManifestError, "differs"):
            self._manifests(report_analysis_winrates_as="BLACK")
        for suffix in (
            "\nreportAnalysisWinratesAs = BLACK\n",
            _PRIVATE_ANALYSIS_CONFIG.replace(
                "reportAnalysisWinratesAs = SIDETOMOVE\n", ""
            ),
        ):
            with self.subTest(config=suffix):
                self.config.write_text(
                    _PRIVATE_ANALYSIS_CONFIG + suffix
                    if suffix.startswith("\n")
                    else suffix
                )
                with self.assertRaises(ManifestError):
                    self._manifests(report_analysis_winrates_as=None)
        self.config.write_text(_PRIVATE_ANALYSIS_CONFIG)

    def _manifests(
        self,
        *,
        endpoint: str = "wss://gpu.example.test:8443/v1",
        human_style_ranks: tuple[str, ...] = (),
        report_analysis_winrates_as: str | None = "SIDETOMOVE",
    ):
        return build_manifests(
            endpoint=endpoint,
            report_analysis_winrates_as=report_analysis_winrates_as,
            engine=self.engine,
            katago_config=self.config,
            model=self.model,
            human_model=self.human_model,
            model_id="kata-normal",
            display_name="KataGo Normal + HumanSL",
            engine_version="1.16.5",
            model_version="b18c384",
            model_license="CC-BY-4.0",
            model_source="https://example.test/models/normal",
            human_style_ranks=human_style_ranks,
        )


_PRIVATE_ANALYSIS_CONFIG = """\
reportAnalysisWinratesAs = SIDETOMOVE
logAllRequests = false
logAllResponses = false
logErrorsAndWarnings = false
logSearchInfo = false
"""


if __name__ == "__main__":
    unittest.main()
