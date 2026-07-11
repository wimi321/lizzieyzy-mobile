"""Generate an App-importable analysis service manifest without credentials."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import json
import os
import re
import stat
import sys
import tempfile
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

from .errors import BridgeConfigurationError
from .trust import parse_katago_config

_RANK = re.compile(r"^(?:[1-9]|[12][0-9]|30)k$|^(?:[1-9])d$")
_FORBIDDEN_SECRET_KEYS = frozenset(
    {"token", "bearertoken", "authorization", "secret", "password"}
)


class ManifestError(ValueError):
    """Raised when a manifest would be incomplete or unsafe."""


@dataclass(frozen=True, slots=True)
class GeneratedManifests:
    service: dict[str, Any]
    audit: dict[str, Any]


def sha256_file(path: str | os.PathLike[str]) -> tuple[str, int]:
    """Hash one stable regular file and reject a concurrent replacement."""

    resolved = Path(path).expanduser().resolve(strict=True)
    flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0)
    descriptor = os.open(resolved, flags)
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise ManifestError("Artifact must be a regular file")
        digest = hashlib.sha256()
        while chunk := os.read(descriptor, 1024 * 1024):
            digest.update(chunk)
        after = os.fstat(descriptor)
        stable_fields = (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
            before.st_ctime_ns,
        )
        if stable_fields != (
            after.st_dev,
            after.st_ino,
            after.st_size,
            after.st_mtime_ns,
            after.st_ctime_ns,
        ):
            raise ManifestError("Artifact changed while its digest was computed")
        return digest.hexdigest(), after.st_size
    finally:
        os.close(descriptor)


def build_manifests(
    *,
    endpoint: str,
    report_analysis_winrates_as: str | None,
    engine: str | os.PathLike[str],
    katago_config: str | os.PathLike[str],
    model: str | os.PathLike[str],
    human_model: str | os.PathLike[str] | None,
    model_id: str,
    display_name: str,
    engine_version: str,
    model_version: str,
    model_license: str,
    model_source: str | None = None,
    human_style_ranks: Sequence[str] = (),
) -> GeneratedManifests:
    """Build a strict App manifest and a separate local artifact audit."""

    clean_endpoint = _validate_endpoint(endpoint)
    try:
        perspective = parse_katago_config(katago_config)
    except BridgeConfigurationError as error:
        raise ManifestError(str(error)) from error
    requested_perspective = (
        report_analysis_winrates_as.strip().upper()
        if report_analysis_winrates_as is not None
        else perspective
    )
    if requested_perspective not in {"BLACK", "WHITE", "SIDETOMOVE"}:
        raise ManifestError(
            "reportAnalysisWinratesAs must be BLACK, WHITE, or SIDETOMOVE"
        )
    if requested_perspective != perspective:
        raise ManifestError(
            "Requested perspective differs from reportAnalysisWinratesAs in config"
        )
    clean_ranks = _validate_ranks(human_style_ranks)
    if clean_ranks and human_model is None:
        raise ManifestError("HumanSL ranks require an independent HumanSL model")
    metadata = {
        "model id": model_id,
        "display name": display_name,
        "engine version": engine_version,
        "model version": model_version,
        "model license": model_license,
    }
    clean_metadata = {
        name: _bounded_text(value, name) for name, value in metadata.items()
    }
    source = _validate_source(model_source) if model_source is not None else None

    engine_sha256, engine_size = sha256_file(engine)
    config_sha256, config_size = sha256_file(katago_config)
    model_sha256, model_size = sha256_file(model)
    human_digest = sha256_file(human_model) if human_model is not None else None

    model_json: dict[str, Any] = {
        "id": clean_metadata["model id"],
        "displayName": clean_metadata["display name"],
        "sha256": model_sha256,
        "engineVersion": clean_metadata["engine version"],
        "modelVersion": clean_metadata["model version"],
        "license": clean_metadata["model license"],
    }
    if source is not None:
        model_json["source"] = source
    if clean_ranks:
        model_json["humanStyleRanks"] = clean_ranks
    if human_digest is not None:
        model_json["humanModelSha256"] = human_digest[0]

    service: dict[str, Any] = {
        "schemaVersion": 1,
        "endpoint": clean_endpoint,
        "reportAnalysisWinratesAs": perspective,
        "model": model_json,
    }
    artifacts: dict[str, Any] = {
        "engine": {"sha256": engine_sha256, "sizeBytes": engine_size},
        "analysisConfig": {
            "sha256": config_sha256,
            "sizeBytes": config_size,
        },
        "analysisModel": {"sha256": model_sha256, "sizeBytes": model_size},
    }
    if human_digest is not None:
        artifacts["humanModel"] = {
            "sha256": human_digest[0],
            "sizeBytes": human_digest[1],
        }
    audit: dict[str, Any] = {
        "schemaVersion": 1,
        "kind": "lizzieyzy-katago-bridge-artifacts",
        "serviceManifestSha256": hashlib.sha256(_encoded_manifest(service)).hexdigest(),
        "artifacts": artifacts,
    }
    _assert_no_secret_fields(service)
    _assert_no_secret_fields(audit)
    return GeneratedManifests(service=service, audit=audit)


def write_manifest(path: Path, manifest: dict[str, Any]) -> None:
    """Atomically write deterministic UTF-8 JSON with non-secret permissions."""

    _assert_no_secret_fields(manifest)
    encoded = _encoded_manifest(manifest)
    if len(encoded) > 64 * 1024:
        raise ManifestError("Manifest exceeds the App's 64KiB import boundary")
    destination = path.expanduser().resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=destination.parent,
            prefix=f".{destination.name}.",
            delete=False,
        ) as temporary:
            temporary_name = temporary.name
            temporary.write(encoded)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.chmod(temporary_name, 0o644)
        os.replace(temporary_name, destination)
        temporary_name = None
    finally:
        if temporary_name is not None:
            with contextlib.suppress(OSError):
                os.unlink(temporary_name)


def _encoded_manifest(manifest: dict[str, Any]) -> bytes:
    return (
        json.dumps(
            manifest,
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
            separators=(",", ": "),
        )
        + "\n"
    ).encode("utf-8")


def _validate_endpoint(value: str) -> str:
    endpoint = _bounded_text(value, "endpoint", maximum=2048)
    if any(ord(character) < 0x21 for character in endpoint):
        raise ManifestError("Endpoint cannot contain whitespace or control characters")
    parsed = urlsplit(endpoint)
    try:
        port = parsed.port
    except ValueError as error:
        raise ManifestError("Endpoint port is invalid") from error
    if (
        parsed.scheme.casefold() != "wss"
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or not parsed.path.startswith("/")
        or parsed.path.startswith("//")
    ):
        raise ManifestError(
            "Endpoint must be wss://host[:port]/path without credentials or query data"
        )
    if port is not None and not 1 <= port <= 65535:
        raise ManifestError("Endpoint port is invalid")
    return endpoint


def _validate_source(value: str) -> str:
    source = _bounded_text(value, "model source", maximum=2048)
    parsed = urlsplit(source)
    if (
        parsed.scheme.casefold() != "https"
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
    ):
        raise ManifestError("Model source must be an HTTPS URL without credentials")
    return source


def _validate_ranks(values: Sequence[str]) -> list[str]:
    ranks: list[str] = []
    seen: set[str] = set()
    for value in values:
        rank = value.strip().lower()
        if _RANK.fullmatch(rank) is None:
            raise ManifestError(f"Invalid HumanSL rank: {value}")
        if rank in seen:
            raise ManifestError(f"Duplicate HumanSL rank: {value}")
        seen.add(rank)
        ranks.append(rank)
    return ranks


def _bounded_text(value: str, label: str, *, maximum: int = 256) -> str:
    clean = value.strip()
    if not clean or len(clean.encode("utf-8")) > maximum:
        raise ManifestError(f"{label} must contain 1-{maximum} UTF-8 bytes")
    if any(ord(character) < 0x20 for character in clean):
        raise ManifestError(f"{label} cannot contain control characters")
    return clean


def _assert_no_secret_fields(value: Any) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if str(key).casefold() in _FORBIDDEN_SECRET_KEYS:
                raise ManifestError("Manifest cannot contain credential fields")
            _assert_no_secret_fields(child)
    elif isinstance(value, list):
        for child in value:
            _assert_no_secret_fields(child)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate a credential-free LizzieYZY analysis manifest"
    )
    parser.add_argument("--endpoint", required=True)
    parser.add_argument(
        "--report-analysis-winrates-as",
        choices=("BLACK", "WHITE", "SIDETOMOVE"),
    )
    parser.add_argument("--engine", required=True, type=Path)
    parser.add_argument("--katago-config", required=True, type=Path)
    parser.add_argument("--model", required=True, type=Path)
    parser.add_argument("--human-model", type=Path)
    parser.add_argument("--model-id", required=True)
    parser.add_argument("--display-name", required=True)
    parser.add_argument("--engine-version", required=True)
    parser.add_argument("--model-version", required=True)
    parser.add_argument("--model-license", required=True)
    parser.add_argument("--model-source")
    parser.add_argument("--human-style-rank", action="append", default=[])
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--audit-output", required=True, type=Path)
    return parser


def _require_python_312() -> None:
    if sys.version_info[:2] != (3, 12):
        raise ManifestError("Manifest generator requires Python 3.12 exactly")


def main(argv: Sequence[str] | None = None) -> None:
    _require_python_312()
    parser = _build_parser()
    arguments = parser.parse_args(argv)
    try:
        output_paths = {
            arguments.output.expanduser().resolve(),
            arguments.audit_output.expanduser().resolve(),
        }
        if len(output_paths) != 2:
            raise ManifestError(
                "Service and audit manifests need different output files"
            )
        artifact_paths = {
            arguments.engine.expanduser().resolve(strict=True),
            arguments.katago_config.expanduser().resolve(strict=True),
            arguments.model.expanduser().resolve(strict=True),
        }
        if arguments.human_model is not None:
            artifact_paths.add(arguments.human_model.expanduser().resolve(strict=True))
        if output_paths & artifact_paths:
            raise ManifestError("Manifest output cannot overwrite an artifact")
        manifests = build_manifests(
            endpoint=arguments.endpoint,
            report_analysis_winrates_as=arguments.report_analysis_winrates_as,
            engine=arguments.engine,
            katago_config=arguments.katago_config,
            model=arguments.model,
            human_model=arguments.human_model,
            model_id=arguments.model_id,
            display_name=arguments.display_name,
            engine_version=arguments.engine_version,
            model_version=arguments.model_version,
            model_license=arguments.model_license,
            model_source=arguments.model_source,
            human_style_ranks=arguments.human_style_rank,
        )
        write_manifest(arguments.output, manifests.service)
        write_manifest(arguments.audit_output, manifests.audit)
    except (ManifestError, OSError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
