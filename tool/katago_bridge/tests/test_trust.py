from __future__ import annotations

import hashlib
import json
import os
import stat
import tempfile
import unittest
from pathlib import Path

from katago_bridge.bridge import EngineCommand
from katago_bridge.errors import BridgeConfigurationError
from katago_bridge.manifest import build_manifests, write_manifest
from katago_bridge.trust import (
    load_runtime_trust,
    stage_runtime_artifacts,
)


class RuntimeTrustTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.engine = self.root / "katago"
        self.config = self.root / "analysis.cfg"
        self.model = self.root / "normal.bin.gz"
        self.human_model = self.root / "human.bin.gz"
        self.service_manifest = self.root / "service-manifest.json"
        self.audit_manifest = self.root / "bridge-artifact-manifest.json"
        self.engine.write_bytes(b"engine artifact")
        self.engine.chmod(0o700)
        self.config.write_text(_private_config("SIDETOMOVE"))
        self.model.write_bytes(b"normal model")
        self.human_model.write_bytes(b"human model")
        self._write_manifests(human=True)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_stage_uses_content_addressed_private_copies_and_cleans_up(self) -> None:
        trust = self._load_trust(human=True)
        staged = stage_runtime_artifacts(
            trust,
            engine=self.engine,
            config=self.config,
            model=self.model,
            human_model=self.human_model,
        )
        stage_root = staged.root
        try:
            self.assertTrue(stage_root.is_dir())
            self.assertIn(trust.engine.sha256, staged.engine.name)
            self.assertIn(trust.config.sha256, staged.config.name)
            self.assertIn(trust.model.sha256, staged.model.name)
            self.assertIn(trust.human_model.sha256, staged.human_model.name)
            if os.name == "posix":
                self.assertEqual(stat.S_IMODE(stage_root.stat().st_mode), 0o700)
                self.assertEqual(stat.S_IMODE(staged.engine.stat().st_mode), 0o500)
                self.assertEqual(stat.S_IMODE(staged.config.stat().st_mode), 0o400)
                self.assertEqual(stat.S_IMODE(staged.model.stat().st_mode), 0o400)
                self.assertEqual(stat.S_IMODE(staged.human_model.stat().st_mode), 0o400)
            command = EngineCommand.validated(
                executable=staged.engine,
                config=staged.config,
                model=staged.model,
                human_model=staged.human_model,
            )
            self.assertEqual(
                command.argv,
                (
                    str(staged.engine.resolve()),
                    "analysis",
                    "-config",
                    str(staged.config.resolve()),
                    "-model",
                    str(staged.model.resolve()),
                    "-human-model",
                    str(staged.human_model.resolve()),
                ),
            )
            self.model.write_bytes(b"replaced after staging")
            self.assertEqual(staged.model.read_bytes(), b"normal model")
        finally:
            staged.cleanup()
        self.assertFalse(stage_root.exists())
        staged.cleanup()

    def test_stage_preserves_katago_parser_selecting_model_suffix(self) -> None:
        text_model = self.root / "normal.txt.gz"
        self.model.rename(text_model)
        self.model = text_model
        self._write_manifests(human=True)

        staged = stage_runtime_artifacts(
            self._load_trust(human=True),
            engine=self.engine,
            config=self.config,
            model=self.model,
            human_model=self.human_model,
        )
        try:
            self.assertTrue(staged.model.name.endswith(".txt.gz"))
            self.assertTrue(staged.human_model.name.endswith(".bin.gz"))
        finally:
            staged.cleanup()

    def test_stage_rejects_ambiguous_model_filename(self) -> None:
        ambiguous_model = self.root / "normal.gz"
        self.model.rename(ambiguous_model)
        self.model = ambiguous_model
        self._write_manifests(human=True)

        with self.assertRaisesRegex(BridgeConfigurationError, "supported"):
            stage_runtime_artifacts(
                self._load_trust(human=True),
                engine=self.engine,
                config=self.config,
                model=self.model,
                human_model=self.human_model,
            )

    def test_replacing_any_runtime_artifact_is_rejected_and_cleaned(self) -> None:
        trust = self._load_trust(human=True)
        artifacts = [self.engine, self.config, self.model, self.human_model]
        for artifact in artifacts:
            with self.subTest(artifact=artifact.name):
                original = artifact.read_bytes()
                tampered = bytes([original[0] ^ 0x01]) + original[1:]
                artifact.write_bytes(tampered)
                if artifact == self.engine:
                    artifact.chmod(0o700)
                before = _stage_directories()
                with self.assertRaisesRegex(
                    BridgeConfigurationError, "does not match audit"
                ):
                    stage_runtime_artifacts(
                        trust,
                        engine=self.engine,
                        config=self.config,
                        model=self.model,
                        human_model=self.human_model,
                    )
                self.assertEqual(_stage_directories(), before)
                artifact.write_bytes(original)
                if artifact == self.engine:
                    artifact.chmod(0o700)

    def test_service_digest_and_runtime_perspective_are_bound(self) -> None:
        service = json.loads(self.service_manifest.read_text())
        service["model"]["displayName"] = "tampered metadata"
        write_manifest(self.service_manifest, service)
        with self.assertRaisesRegex(BridgeConfigurationError, "digest"):
            self._load_trust(human=True)

        self._write_manifests(human=True)
        self.config.write_text(_private_config("BLACK"))
        audit = json.loads(self.audit_manifest.read_text())
        config_bytes = self.config.read_bytes()
        audit["artifacts"]["analysisConfig"] = {
            "sha256": hashlib.sha256(config_bytes).hexdigest(),
            "sizeBytes": len(config_bytes),
        }
        write_manifest(self.audit_manifest, audit)
        trust = self._load_trust(human=True)
        with self.assertRaisesRegex(BridgeConfigurationError, "perspective differs"):
            stage_runtime_artifacts(
                trust,
                engine=self.engine,
                config=self.config,
                model=self.model,
                human_model=self.human_model,
            )

    def test_runtime_manifests_reject_unknown_schema_fields(self) -> None:
        service = json.loads(self.service_manifest.read_text())
        service["unknown"] = True
        write_manifest(self.service_manifest, service)
        with self.assertRaisesRegex(BridgeConfigurationError, "schema"):
            self._load_trust(human=True)

        self._write_manifests(human=True)
        audit = json.loads(self.audit_manifest.read_text())
        audit["unknown"] = True
        write_manifest(self.audit_manifest, audit)
        with self.assertRaisesRegex(BridgeConfigurationError, "schema"):
            self._load_trust(human=True)

    def test_no_human_mode_forbids_every_human_artifact_and_field(self) -> None:
        self._write_manifests(human=False)
        trust = self._load_trust(human=False)
        self.assertIsNone(trust.human_model)
        self.assertEqual(trust.human_style_ranks, ())
        staged = stage_runtime_artifacts(
            trust,
            engine=self.engine,
            config=self.config,
            model=self.model,
            human_model=None,
        )
        try:
            self.assertIsNone(staged.human_model)
        finally:
            staged.cleanup()
        with self.assertRaises(BridgeConfigurationError):
            self._load_trust(human=True)

    def _write_manifests(self, *, human: bool) -> None:
        manifests = build_manifests(
            endpoint="wss://gpu.example.test:8443/v1",
            report_analysis_winrates_as=None,
            engine=self.engine,
            katago_config=self.config,
            model=self.model,
            human_model=self.human_model if human else None,
            model_id="kata-normal",
            display_name="KataGo Normal + HumanSL" if human else "KataGo Normal",
            engine_version="1.16.5",
            model_version="b18c384",
            model_license="CC-BY-4.0",
            model_source="https://example.test/models/normal",
            human_style_ranks=("3k", "1d") if human else (),
        )
        write_manifest(self.service_manifest, manifests.service)
        write_manifest(self.audit_manifest, manifests.audit)

    def _load_trust(self, *, human: bool):
        return load_runtime_trust(
            service_manifest=self.service_manifest,
            audit_manifest=self.audit_manifest,
            has_human_model=human,
            route="/v1",
            port=8443,
        )


def _private_config(perspective: str) -> str:
    return (
        f"reportAnalysisWinratesAs = {perspective}\n"
        "logAllRequests = false\n"
        "logAllResponses = false\n"
        "logErrorsAndWarnings = false\n"
        "logSearchInfo = false\n"
    )


def _stage_directories() -> set[Path]:
    return set(Path(tempfile.gettempdir()).glob("lizzieyzy-katago-stage-*"))


if __name__ == "__main__":
    unittest.main()
