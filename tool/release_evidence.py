#!/usr/bin/env python3
"""Create deterministic release digests, bundles, and an integrity predicate.

The custom predicate intentionally asserts only digest binding and evidence
completeness. It is not a SLSA build-provenance predicate; GitHub's attestation
action wraps it in an in-toto statement and binds it to the final evidence ZIP.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import os
import re
import stat
import subprocess
import sys
import zipfile
from pathlib import Path, PurePosixPath
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
INTEGRITY_PREDICATE_TYPE = (
    "https://github.com/wimi321/lizzieyzy-mobile/"
    "attestations/release-integrity/v1"
)
ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)
BUFFER_SIZE = 1024 * 1024


class EvidenceError(RuntimeError):
    pass


def fail(message: str) -> None:
    raise EvidenceError(message)


def sha256_file(path: Path) -> str:
    if not path.is_file() or path.is_symlink():
        fail(f"evidence input must be a regular file: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(BUFFER_SIZE), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_named_path(value: str) -> tuple[str, Path]:
    name, separator, raw_path = value.partition("=")
    if (
        not separator
        or not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", name)
        or not raw_path
    ):
        fail(f"expected NAME=PATH with a stable lowercase name, got: {value!r}")
    return name, Path(raw_path)


def media_type(path: Path) -> str:
    if path.suffix.lower() == ".apk":
        return "application/vnd.android.package-archive"
    guessed, _ = mimetypes.guess_type(path.name)
    return guessed or "application/octet-stream"


def hash_artifacts(output: Path, values: list[str]) -> None:
    if not values:
        fail("at least one --artifact NAME=PATH is required")
    artifacts = []
    seen: set[str] = set()
    for value in values:
        name, path = parse_named_path(value)
        if name in seen:
            fail(f"duplicate artifact name: {name}")
        seen.add(name)
        artifacts.append(
            {
                "name": name,
                "file": path.name,
                "sha256": sha256_file(path),
                "bytes": path.stat().st_size,
                "mediaType": media_type(path),
            }
        )
    manifest = {
        "schemaVersion": 1,
        "artifacts": sorted(artifacts, key=lambda item: item["name"]),
    }
    write_json(output, manifest)
    print(f"Hashed {len(artifacts)} release candidates -> {output}")


def load_artifacts(path: Path) -> list[dict[str, object]]:
    try:
        value = json.loads(path.read_text("utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot read release artifact digest manifest: {error}")
    if not isinstance(value, dict) or value.get("schemaVersion") != 1:
        fail("release artifact digest manifest must use schemaVersion 1")
    artifacts = value.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        fail("release artifact digest manifest contains no artifacts")
    seen: set[str] = set()
    for item in artifacts:
        if (
            not isinstance(item, dict)
            or not isinstance(item.get("name"), str)
            or not isinstance(item.get("file"), str)
            or not isinstance(item.get("bytes"), int)
            or item["bytes"] < 0
            or not re.fullmatch(r"[0-9a-f]{64}", str(item.get("sha256", "")))
        ):
            fail("release artifact digest manifest contains an invalid artifact")
        name = str(item["name"])
        if name in seen:
            fail(f"release artifact digest manifest repeats artifact: {name}")
        seen.add(name)
    return artifacts


def git_sha() -> str:
    candidate = os.environ.get("GITHUB_SHA", "")
    if not candidate:
        try:
            candidate = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
        except (OSError, subprocess.CalledProcessError) as error:
            fail(f"cannot resolve source revision: {error}")
    if not re.fullmatch(r"[0-9a-f]{40}", candidate):
        fail("source revision must be a full 40-character Git SHA")
    return candidate


def integrity_predicate(
    output: Path, artifacts_path: Path, evidence_values: list[str]
) -> None:
    artifacts = load_artifacts(artifacts_path)
    if not evidence_values:
        fail("at least one --evidence NAME=PATH is required")
    evidence = []
    seen: set[str] = set()
    for value in evidence_values:
        name, path = parse_named_path(value)
        if name in seen:
            fail(f"duplicate evidence name: {name}")
        seen.add(name)
        evidence.append(
            {
                "name": name,
                "file": path.name,
                "sha256": sha256_file(path),
                "bytes": path.stat().st_size,
            }
        )
    repository = os.environ.get(
        "GITHUB_SERVER_URL", "https://github.com"
    ).rstrip("/") + "/" + os.environ.get(
        "GITHUB_REPOSITORY", "wimi321/lizzieyzy-mobile"
    )
    value = {
        "schemaVersion": 1,
        "kind": "lizzieyzy-mobile-release-integrity",
        "claimScope": "digest-binding-and-evidence-completeness-only",
        "buildProvenance": False,
        "source": {
            "repository": repository,
            "revision": git_sha(),
            "ref": os.environ.get("GITHUB_REF", "local"),
            "workflowRef": os.environ.get(
                "GITHUB_WORKFLOW_REF",
                "wimi321/lizzieyzy-mobile/.github/workflows/release.yml@local",
            ),
            "runId": os.environ.get("GITHUB_RUN_ID", "local"),
            "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT", "1"),
            "flutterVersion": os.environ.get("FLUTTER_VERSION", "unknown"),
        },
        "candidateArtifacts": [
            {
                "name": item["name"],
                "file": item["file"],
                "sha256": item["sha256"],
                "bytes": item["bytes"],
            }
            for item in sorted(artifacts, key=lambda item: str(item["name"]))
        ],
        "evidence": sorted(evidence, key=lambda item: item["name"]),
    }
    write_json(output, value)
    print(
        f"Generated custom release integrity predicate for "
        f"{len(artifacts)} candidates -> {output}"
    )


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        "utf-8",
    )


def iter_named_files(values: Iterable[str]) -> list[tuple[str, Path, str]]:
    result: list[tuple[str, Path, str]] = []
    seen_names: set[str] = set()
    seen_archive_paths: set[str] = set()
    for value in values:
        name, path = parse_named_path(value)
        if name in seen_names:
            fail(f"duplicate input name: {name}")
        seen_names.add(name)
        if path.is_symlink():
            fail(f"symbolic links are forbidden in release evidence: {path}")
        if path.is_file():
            candidates = [(path, path.name)]
        elif path.is_dir():
            candidates = []
            for candidate in sorted(path.rglob("*")):
                if candidate.is_symlink():
                    fail(
                        "symbolic links are forbidden in release evidence: "
                        f"{candidate}"
                    )
                if candidate.is_file():
                    candidates.append((candidate, candidate.relative_to(path).as_posix()))
            if not candidates:
                fail(f"release evidence directory is empty: {path}")
        else:
            fail(f"release evidence input is missing: {path}")
        for candidate, relative in candidates:
            archive_path = PurePosixPath(name, relative).as_posix()
            if archive_path in seen_archive_paths:
                fail(f"duplicate release evidence archive path: {archive_path}")
            seen_archive_paths.add(archive_path)
            result.append((archive_path, candidate, name))
    if not result:
        fail("at least one --input NAME=PATH is required")
    return sorted(result, key=lambda item: item[0])


def write_zip_file(archive: zipfile.ZipFile, archive_path: str, source: Path) -> None:
    mode = stat.S_IMODE(source.stat().st_mode)
    info = zipfile.ZipInfo(archive_path, ZIP_TIMESTAMP)
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | mode) << 16
    info.compress_type = zipfile.ZIP_STORED
    with source.open("rb") as reader, archive.open(info, "w", force_zip64=True) as writer:
        for chunk in iter(lambda: reader.read(BUFFER_SIZE), b""):
            writer.write(chunk)


def deterministic_bundle(output: Path, values: list[str]) -> None:
    inputs = iter_named_files(values)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(output.name + ".tmp")
    try:
        with zipfile.ZipFile(temporary, "w", allowZip64=True) as archive:
            for archive_path, source, _ in inputs:
                write_zip_file(archive, archive_path, source)
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"Packed {len(inputs)} deterministic evidence files -> {output}")


def checksums(output: Path, values: list[str]) -> None:
    inputs = iter_named_files(values)
    lines = [f"{sha256_file(path)}  {archive_path}" for archive_path, path, _ in inputs]
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", "utf-8")
    print(f"Hashed {len(inputs)} evidence files -> {output}")


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description=__doc__)
    commands = root.add_subparsers(dest="command", required=True)
    hashes = commands.add_parser("hash")
    hashes.add_argument("--output", type=Path, required=True)
    hashes.add_argument("--artifact", action="append", default=[])
    predicate = commands.add_parser("predicate")
    predicate.add_argument("--output", type=Path, required=True)
    predicate.add_argument("--artifacts", type=Path, required=True)
    predicate.add_argument("--evidence", action="append", default=[])
    bundle = commands.add_parser("bundle")
    bundle.add_argument("--output", type=Path, required=True)
    bundle.add_argument("--input", action="append", default=[])
    checksum = commands.add_parser("checksums")
    checksum.add_argument("--output", type=Path, required=True)
    checksum.add_argument("--input", action="append", default=[])
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "hash":
            hash_artifacts(args.output, args.artifact)
        elif args.command == "predicate":
            integrity_predicate(args.output, args.artifacts, args.evidence)
        elif args.command == "bundle":
            deterministic_bundle(args.output, args.input)
        else:
            checksums(args.output, args.input)
    except EvidenceError as error:
        print(f"release evidence generation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
