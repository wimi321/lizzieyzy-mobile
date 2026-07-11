"""Manifest binding and immutable staging for KataGo runtime artifacts."""

from __future__ import annotations

import hashlib
import json
import os
import re
import stat
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

from .errors import BridgeConfigurationError

_HEX_SHA256 = re.compile(r"^[0-9a-f]{64}$")
_RANK = re.compile(r"^(?:[1-9]|[12][0-9]|30)k$|^(?:[1-9])d$")
_PRIVATE_LOG_SETTINGS = frozenset(
    {
        "logallrequests",
        "logallresponses",
        "logerrorsandwarnings",
        "logsearchinfo",
    }
)
_PERSPECTIVE_KEY = "reportanalysiswinratesas"
_PERSPECTIVES = frozenset({"BLACK", "WHITE", "SIDETOMOVE"})
_MAX_MANIFEST_BYTES = 64 * 1024
_MAX_CONFIG_BYTES = 512 * 1024
_MODEL_SUFFIXES = (".bin.gz", ".txt.gz")


@dataclass(frozen=True, slots=True)
class ArtifactExpectation:
    sha256: str
    size_bytes: int


@dataclass(frozen=True, slots=True)
class RuntimeTrust:
    perspective: str
    endpoint: str
    model_id: str
    engine: ArtifactExpectation
    config: ArtifactExpectation
    model: ArtifactExpectation
    human_model: ArtifactExpectation | None
    human_style_ranks: tuple[str, ...]


@dataclass(slots=True)
class StagedArtifacts:
    root: Path
    engine: Path
    config: Path
    model: Path
    human_model: Path | None
    _temporary: tempfile.TemporaryDirectory[str]
    _cleaned: bool = False

    def cleanup(self) -> None:
        if self._cleaned:
            return
        self._cleaned = True
        self._temporary.cleanup()


def parse_katago_config(path: str | os.PathLike[str]) -> str:
    """Return the unique perspective after enforcing privacy-safe logging."""

    try:
        config_path = Path(path).expanduser().resolve(strict=True)
        encoded = config_path.read_bytes()
    except (OSError, RuntimeError) as error:
        raise BridgeConfigurationError(
            "KataGo analysis config is unreadable"
        ) from error
    if not encoded or len(encoded) > _MAX_CONFIG_BYTES:
        raise BridgeConfigurationError(
            "KataGo analysis config must be between 1 byte and 512KiB"
        )
    try:
        contents = encoded.decode("utf-8-sig", errors="strict")
    except UnicodeDecodeError as error:
        raise BridgeConfigurationError(
            "KataGo analysis config must be UTF-8"
        ) from error
    observed: dict[str, str] = {}
    watched = _PRIVATE_LOG_SETTINGS | {_PERSPECTIVE_KEY}
    for raw_line in contents.splitlines():
        active = raw_line.split("#", 1)[0].strip()
        if not active or "=" not in active:
            continue
        raw_name, raw_value = active.split("=", 1)
        name = raw_name.strip().casefold()
        if name not in watched:
            continue
        if name in observed:
            raise BridgeConfigurationError(
                "KataGo perspective and privacy settings must be unique"
            )
        observed[name] = raw_value.strip()
    if not _PRIVATE_LOG_SETTINGS.issubset(observed) or any(
        observed[name].casefold() != "false" for name in _PRIVATE_LOG_SETTINGS
    ):
        raise BridgeConfigurationError(
            "KataGo config must explicitly set logAllRequests, logAllResponses, "
            "logErrorsAndWarnings, and logSearchInfo to false"
        )
    perspective = observed.get(_PERSPECTIVE_KEY, "").upper()
    if perspective not in _PERSPECTIVES:
        raise BridgeConfigurationError(
            "KataGo config must declare one valid reportAnalysisWinratesAs value"
        )
    return perspective


def load_runtime_trust(
    *,
    service_manifest: str | os.PathLike[str],
    audit_manifest: str | os.PathLike[str],
    has_human_model: bool,
    route: str,
    port: int,
) -> RuntimeTrust:
    service_bytes, service = _read_manifest(service_manifest, "service")
    _, audit = _read_manifest(audit_manifest, "audit")
    _exact_keys(
        service,
        required={
            "schemaVersion",
            "endpoint",
            "reportAnalysisWinratesAs",
            "model",
        },
        optional={"performanceCalibration"},
        label="service manifest",
    )
    if _strict_integer(service["schemaVersion"], "schemaVersion") != 1:
        raise BridgeConfigurationError("Unsupported service manifest version")
    if "performanceCalibration" in service and not isinstance(
        service["performanceCalibration"], dict
    ):
        raise BridgeConfigurationError("performanceCalibration must be an object")
    endpoint = _strict_string(service["endpoint"], "endpoint", maximum=2048)
    _validate_runtime_endpoint(endpoint, route=route, port=port)
    perspective = _strict_string(
        service["reportAnalysisWinratesAs"],
        "reportAnalysisWinratesAs",
        maximum=16,
    ).upper()
    if perspective not in _PERSPECTIVES:
        raise BridgeConfigurationError("Service manifest perspective is invalid")

    raw_model = service["model"]
    if not isinstance(raw_model, dict):
        raise BridgeConfigurationError("Service manifest model must be an object")
    model = raw_model
    _exact_keys(
        model,
        required={
            "id",
            "displayName",
            "sha256",
            "engineVersion",
            "modelVersion",
            "license",
        },
        optional={"source", "humanStyleRanks", "humanModelSha256"},
        label="service model",
    )
    model_id = _strict_string(model["id"], "model.id")
    for field in ("displayName", "engineVersion", "modelVersion", "license"):
        _strict_string(model[field], f"model.{field}")
    if "source" in model:
        _validate_source(_strict_string(model["source"], "model.source", maximum=2048))
    model_sha256 = _strict_sha256(model["sha256"], "model.sha256")
    ranks = _parse_ranks(model.get("humanStyleRanks"))
    human_sha256 = (
        _strict_sha256(model["humanModelSha256"], "model.humanModelSha256")
        if "humanModelSha256" in model
        else None
    )
    if has_human_model:
        if human_sha256 is None:
            raise BridgeConfigurationError(
                "A configured HumanSL model requires model.humanModelSha256"
            )
    elif human_sha256 is not None or "humanStyleRanks" in model:
        raise BridgeConfigurationError(
            "HumanSL metadata is forbidden when --human-model is absent"
        )

    _exact_keys(
        audit,
        required={"schemaVersion", "kind", "serviceManifestSha256", "artifacts"},
        optional=set(),
        label="audit manifest",
    )
    if _strict_integer(audit["schemaVersion"], "audit.schemaVersion") != 1:
        raise BridgeConfigurationError("Unsupported audit manifest version")
    if audit["kind"] != "lizzieyzy-katago-bridge-artifacts":
        raise BridgeConfigurationError("Audit manifest kind is invalid")
    expected_service_sha = _strict_sha256(
        audit["serviceManifestSha256"], "audit.serviceManifestSha256"
    )
    if hashlib.sha256(service_bytes).hexdigest() != expected_service_sha:
        raise BridgeConfigurationError("Service manifest digest does not match audit")
    raw_artifacts = audit["artifacts"]
    if not isinstance(raw_artifacts, dict):
        raise BridgeConfigurationError("Audit artifacts must be an object")
    expected_roles = {"engine", "analysisConfig", "analysisModel"}
    if has_human_model:
        expected_roles.add("humanModel")
    _exact_keys(
        raw_artifacts,
        required=expected_roles,
        optional=set(),
        label="audit artifacts",
    )
    engine = _parse_artifact(raw_artifacts["engine"], "engine")
    config = _parse_artifact(raw_artifacts["analysisConfig"], "analysisConfig")
    analysis_model = _parse_artifact(raw_artifacts["analysisModel"], "analysisModel")
    human_model = (
        _parse_artifact(raw_artifacts["humanModel"], "humanModel")
        if has_human_model
        else None
    )
    if analysis_model.sha256 != model_sha256:
        raise BridgeConfigurationError(
            "Normal model digest differs between service and audit manifests"
        )
    if human_model is not None and human_model.sha256 != human_sha256:
        raise BridgeConfigurationError(
            "HumanSL digest differs between service and audit manifests"
        )
    return RuntimeTrust(
        perspective=perspective,
        endpoint=endpoint,
        model_id=model_id,
        engine=engine,
        config=config,
        model=analysis_model,
        human_model=human_model,
        human_style_ranks=ranks,
    )


def stage_runtime_artifacts(
    trust: RuntimeTrust,
    *,
    engine: str | os.PathLike[str],
    config: str | os.PathLike[str],
    model: str | os.PathLike[str],
    human_model: str | os.PathLike[str] | None,
) -> StagedArtifacts:
    if (human_model is None) != (trust.human_model is None):
        raise BridgeConfigurationError("HumanSL runtime and manifest modes differ")
    temporary = tempfile.TemporaryDirectory(prefix="lizzieyzy-katago-stage-")
    root = Path(temporary.name)
    try:
        os.chmod(root, 0o700)
        engine_suffix = ".exe" if os.name == "nt" else ""
        staged_engine = root / f"engine-{trust.engine.sha256}{engine_suffix}"
        staged_config = root / f"config-{trust.config.sha256}.cfg"
        staged_model = root / (
            f"normal-{trust.model.sha256}{_model_suffix(model, 'analysis model')}"
        )
        _copy_verified(engine, staged_engine, trust.engine, mode=0o500)
        _copy_verified(config, staged_config, trust.config, mode=0o400)
        _copy_verified(model, staged_model, trust.model, mode=0o400)
        staged_human: Path | None = None
        if human_model is not None and trust.human_model is not None:
            staged_human = root / (
                f"human-{trust.human_model.sha256}"
                f"{_model_suffix(human_model, 'HumanSL model')}"
            )
            _copy_verified(
                human_model,
                staged_human,
                trust.human_model,
                mode=0o400,
            )
        staged_perspective = parse_katago_config(staged_config)
        if staged_perspective != trust.perspective:
            raise BridgeConfigurationError(
                "KataGo config perspective differs from service manifest"
            )
        return StagedArtifacts(
            root=root,
            engine=staged_engine,
            config=staged_config,
            model=staged_model,
            human_model=staged_human,
            _temporary=temporary,
        )
    except BaseException:
        temporary.cleanup()
        raise


def _model_suffix(source: str | os.PathLike[str], label: str) -> str:
    """Keep KataGo's parser-selecting model suffix while constraining the name."""

    source_name = os.fspath(source).casefold()
    for suffix in _MODEL_SUFFIXES:
        if source_name.endswith(suffix):
            return suffix
    raise BridgeConfigurationError(
        f"KataGo {label} must use a supported .bin.gz or .txt.gz filename"
    )


def _copy_verified(
    source: str | os.PathLike[str],
    destination: Path,
    expectation: ArtifactExpectation,
    *,
    mode: int,
) -> None:
    source_flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0)
    source_flags |= getattr(os, "O_NOFOLLOW", 0)
    try:
        source_path = Path(source).expanduser().resolve(strict=True)
        source_descriptor = os.open(source_path, source_flags)
    except (OSError, RuntimeError) as error:
        raise BridgeConfigurationError(
            "Could not securely open runtime artifact"
        ) from error
    destination_descriptor: int | None = None
    try:
        before = os.fstat(source_descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise BridgeConfigurationError("Runtime artifact must be a regular file")
        destination_descriptor = os.open(
            destination,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_CLOEXEC", 0),
            mode,
        )
        digest = hashlib.sha256()
        total = 0
        while chunk := os.read(source_descriptor, 1024 * 1024):
            digest.update(chunk)
            total += len(chunk)
            pending = memoryview(chunk)
            while pending:
                written = os.write(destination_descriptor, pending)
                if written <= 0:
                    raise OSError("Could not write staged artifact")
                pending = pending[written:]
        after = os.fstat(source_descriptor)
        stable_before = (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
            before.st_ctime_ns,
        )
        stable_after = (
            after.st_dev,
            after.st_ino,
            after.st_size,
            after.st_mtime_ns,
            after.st_ctime_ns,
        )
        if stable_before != stable_after:
            raise BridgeConfigurationError("Runtime artifact changed during staging")
        if total != expectation.size_bytes or digest.hexdigest() != expectation.sha256:
            raise BridgeConfigurationError(
                "Runtime artifact does not match audit manifest"
            )
        os.fsync(destination_descriptor)
        if hasattr(os, "fchmod"):
            os.fchmod(destination_descriptor, mode)
        else:
            os.chmod(destination, mode)
    except OSError as error:
        raise BridgeConfigurationError(
            "Could not create private staged artifact"
        ) from error
    finally:
        if destination_descriptor is not None:
            os.close(destination_descriptor)
        os.close(source_descriptor)


def _read_manifest(
    path: str | os.PathLike[str], label: str
) -> tuple[bytes, dict[str, Any]]:
    try:
        raw = Path(path).expanduser().resolve(strict=True).read_bytes()
    except (OSError, RuntimeError) as error:
        raise BridgeConfigurationError(f"Could not read {label} manifest") from error
    if not raw or len(raw) > _MAX_MANIFEST_BYTES:
        raise BridgeConfigurationError(
            f"{label.capitalize()} manifest must be between 1 byte and 64KiB"
        )
    try:
        text = raw.decode("utf-8", errors="strict")
        _validate_json_depth(text)
        decoded = json.loads(
            text,
            object_pairs_hook=_unique_object,
            parse_constant=_reject_json_constant,
        )
    except BridgeConfigurationError:
        raise
    except (UnicodeError, ValueError, RecursionError) as error:
        raise BridgeConfigurationError(
            f"{label.capitalize()} manifest is invalid"
        ) from error
    if not isinstance(decoded, dict):
        raise BridgeConfigurationError(
            f"{label.capitalize()} manifest must be an object"
        )
    return raw, decoded


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise BridgeConfigurationError("Manifest contains a duplicate JSON key")
        result[key] = value
    return result


def _reject_json_constant(value: str) -> None:
    raise BridgeConfigurationError(f"Manifest contains non-finite number {value}")


def _validate_json_depth(text: str) -> None:
    depth = 0
    in_string = False
    escaped = False
    for character in text:
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            continue
        if character == '"':
            in_string = True
        elif character in "[{":
            depth += 1
            if depth > 32:
                raise BridgeConfigurationError("Manifest JSON is nested too deeply")
        elif character in "]}":
            depth -= 1
            if depth < 0:
                raise BridgeConfigurationError("Manifest JSON is unbalanced")
    if depth != 0 or in_string or escaped:
        raise BridgeConfigurationError("Manifest JSON is incomplete")


def _exact_keys(
    value: dict[str, Any],
    *,
    required: set[str],
    optional: set[str],
    label: str,
) -> None:
    keys = set(value)
    if not required.issubset(keys) or not keys.issubset(required | optional):
        raise BridgeConfigurationError(f"{label} fields do not match its schema")


def _strict_string(value: Any, label: str, *, maximum: int = 256) -> str:
    if not isinstance(value, str):
        raise BridgeConfigurationError(f"{label} must be a string")
    clean = value.strip()
    if not clean or len(clean.encode("utf-8")) > maximum:
        raise BridgeConfigurationError(f"{label} is empty or too large")
    if any(ord(character) < 0x20 for character in clean):
        raise BridgeConfigurationError(f"{label} contains control characters")
    return clean


def _strict_integer(value: Any, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise BridgeConfigurationError(f"{label} must be an integer")
    return value


def _strict_sha256(value: Any, label: str) -> str:
    digest = _strict_string(value, label, maximum=64).lower()
    if _HEX_SHA256.fullmatch(digest) is None:
        raise BridgeConfigurationError(f"{label} must be a SHA-256 digest")
    return digest


def _parse_ranks(value: Any) -> tuple[str, ...]:
    if value is None:
        return ()
    if not isinstance(value, list):
        raise BridgeConfigurationError("model.humanStyleRanks must be an array")
    ranks: list[str] = []
    for entry in value:
        rank = _strict_string(entry, "HumanSL rank", maximum=3).lower()
        if _RANK.fullmatch(rank) is None or rank in ranks:
            raise BridgeConfigurationError("HumanSL ranks are invalid or duplicated")
        ranks.append(rank)
    return tuple(ranks)


def _parse_artifact(value: Any, label: str) -> ArtifactExpectation:
    if not isinstance(value, dict):
        raise BridgeConfigurationError(f"{label} artifact must be an object")
    _exact_keys(
        value,
        required={"sha256", "sizeBytes"},
        optional=set(),
        label=f"{label} artifact",
    )
    size = _strict_integer(value["sizeBytes"], f"{label}.sizeBytes")
    if size <= 0:
        raise BridgeConfigurationError(f"{label}.sizeBytes must be positive")
    return ArtifactExpectation(
        sha256=_strict_sha256(value["sha256"], f"{label}.sha256"),
        size_bytes=size,
    )


def _validate_runtime_endpoint(endpoint: str, *, route: str, port: int) -> None:
    parsed = urlsplit(endpoint)
    try:
        endpoint_port = parsed.port or 443
    except ValueError as error:
        raise BridgeConfigurationError("Service endpoint port is invalid") from error
    if (
        parsed.scheme.casefold() != "wss"
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or parsed.path != route
        or endpoint_port != port
    ):
        raise BridgeConfigurationError(
            "Service endpoint path or port differs from bridge runtime"
        )


def _validate_source(source: str) -> None:
    parsed = urlsplit(source)
    if not parsed.scheme or not parsed.hostname:
        raise BridgeConfigurationError("model.source must be an absolute URI")
