#!/usr/bin/env python3
"""Validate and archive Android/iOS release symbol evidence deterministically."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import zipfile
from pathlib import Path, PurePosixPath


ZIP_TIMESTAMP = (1980, 1, 1, 0, 0, 0)
BUFFER_SIZE = 1024 * 1024
ANDROID_FLUTTER_SYMBOLS = {
    "app.android-arm.symbols",
    "app.android-arm64.symbols",
    "app.android-x64.symbols",
}
IOS_FLUTTER_SYMBOLS = {"app.ios-arm64.symbols"}


class SymbolError(RuntimeError):
    pass


def fail(message: str) -> None:
    raise SymbolError(message)


def sha256_file(path: Path) -> str:
    if not path.is_file() or path.is_symlink():
        fail(f"symbol input must be a regular file: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(BUFFER_SIZE), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_files(root: Path) -> list[Path]:
    if not root.is_dir() or root.is_symlink():
        fail(f"symbol directory is missing or unsafe: {root}")
    files: list[Path] = []
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            fail(f"symbol archives may not contain symbolic links: {path}")
        if path.is_file():
            files.append(path)
    if not files:
        fail(f"symbol directory is empty: {root}")
    return files


def zip_member_is_symlink(info: zipfile.ZipInfo) -> bool:
    return stat.S_ISLNK(info.external_attr >> 16)


def validate_native_symbols(path: Path) -> dict[str, object]:
    try:
        with zipfile.ZipFile(path) as archive:
            infos = archive.infolist()
            if not infos:
                fail("Android native symbol archive is empty")
            seen: set[str] = set()
            abis: set[str] = set()
            symbol_files = 0
            for info in infos:
                member = PurePosixPath(info.filename)
                if (
                    member.is_absolute()
                    or ".." in member.parts
                    or info.filename in seen
                    or zip_member_is_symlink(info)
                ):
                    fail(f"unsafe Android native symbol member: {info.filename}")
                seen.add(info.filename)
                if info.is_dir():
                    continue
                if info.file_size <= 0 or member.suffix != ".sym" or len(member.parts) < 2:
                    fail(f"invalid Android native symbol member: {info.filename}")
                abis.add(member.parts[0])
                symbol_files += 1
            if archive.testzip() is not None:
                fail("Android native symbol archive has a corrupt member")
            if "arm64-v8a" not in abis:
                fail("Android native symbols omit the required arm64-v8a ABI")
    except (OSError, zipfile.BadZipFile) as error:
        fail(f"invalid Android native symbol archive: {error}")
    return {"abis": sorted(abis), "symbolFiles": symbol_files}


def write_member(archive: zipfile.ZipFile, source: Path, archive_path: str) -> None:
    mode = stat.S_IMODE(source.stat().st_mode)
    info = zipfile.ZipInfo(archive_path, ZIP_TIMESTAMP)
    info.create_system = 3
    info.external_attr = (stat.S_IFREG | mode) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    with source.open("rb") as reader, archive.open(info, "w", force_zip64=True) as writer:
        shutil.copyfileobj(reader, writer, BUFFER_SIZE)


def write_archive(output: Path, inputs: list[tuple[str, Path]]) -> None:
    archive_paths = [name for name, _ in inputs]
    if len(archive_paths) != len(set(archive_paths)):
        fail("release symbol archive contains duplicate paths")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(output.name + ".tmp")
    try:
        with zipfile.ZipFile(
            temporary,
            "w",
            compression=zipfile.ZIP_DEFLATED,
            compresslevel=9,
            allowZip64=True,
        ) as archive:
            for archive_path, source in sorted(inputs):
                write_member(archive, source, archive_path)
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)


def write_manifest(
    path: Path,
    platform: str,
    archive: Path,
    inputs: list[tuple[str, Path]],
    details: dict[str, object],
) -> None:
    value = {
        "schemaVersion": 1,
        "platform": platform,
        "archive": {
            "file": archive.name,
            "sha256": sha256_file(archive),
            "bytes": archive.stat().st_size,
        },
        "files": [
            {
                "path": name,
                "sha256": sha256_file(source),
                "bytes": source.stat().st_size,
            }
            for name, source in sorted(inputs)
        ],
        "details": details,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        "utf-8",
    )


def verify_archive(archive_path: Path, manifest_path: Path) -> None:
    try:
        manifest = json.loads(manifest_path.read_text("utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot read release symbol manifest: {error}")
    if manifest.get("schemaVersion") != 1 or manifest.get("platform") not in {
        "android",
        "ios",
    }:
        fail("release symbol manifest has an invalid schema or platform")
    archive_value = manifest.get("archive")
    if not isinstance(archive_value, dict):
        fail("release symbol manifest omits archive metadata")
    if (
        archive_value.get("file") != archive_path.name
        or archive_value.get("sha256") != sha256_file(archive_path)
        or archive_value.get("bytes") != archive_path.stat().st_size
    ):
        fail("release symbol archive does not match its manifest")
    file_values = manifest.get("files")
    if not isinstance(file_values, list) or not file_values:
        fail("release symbol manifest contains no files")
    expected: dict[str, tuple[str, int]] = {}
    for value in file_values:
        if not isinstance(value, dict) or not isinstance(value.get("path"), str):
            fail("release symbol manifest contains an invalid file")
        name = value["path"]
        digest = value.get("sha256")
        size = value.get("bytes")
        if (
            name in expected
            or PurePosixPath(name).is_absolute()
            or ".." in PurePosixPath(name).parts
            or not isinstance(digest, str)
            or re.fullmatch(r"[0-9a-f]{64}", digest) is None
            or not isinstance(size, int)
            or size <= 0
        ):
            fail(f"invalid release symbol manifest entry: {name}")
        expected[name] = (digest, size)
    try:
        with zipfile.ZipFile(archive_path) as archive:
            infos = [info for info in archive.infolist() if not info.is_dir()]
            names = [info.filename for info in infos]
            if len(names) != len(set(names)) or set(names) != set(expected):
                fail("release symbol archive file set does not match its manifest")
            for info in infos:
                if zip_member_is_symlink(info):
                    fail(f"release symbol archive contains a symlink: {info.filename}")
                digest = hashlib.sha256()
                with archive.open(info) as source:
                    for chunk in iter(lambda: source.read(BUFFER_SIZE), b""):
                        digest.update(chunk)
                expected_digest, expected_size = expected[info.filename]
                if info.file_size != expected_size or digest.hexdigest() != expected_digest:
                    fail(f"release symbol member changed: {info.filename}")
            if archive.testzip() is not None:
                fail("release symbol archive has a corrupt member")
    except (OSError, zipfile.BadZipFile) as error:
        fail(f"cannot verify release symbol archive: {error}")
    print(f"Verified {manifest['platform']} release symbol archive: {archive_path}")


def android_symbols(
    mapping: Path,
    native: Path,
    flutter_dir: Path,
    output: Path,
    manifest: Path,
) -> None:
    if not mapping.is_file() or mapping.is_symlink():
        fail("R8 mapping must be a regular file")
    if not native.is_file() or native.is_symlink():
        fail("Android native symbols must be a regular ZIP")
    if mapping.stat().st_size < 1024 or " -> " not in mapping.read_text(
        "utf-8", errors="replace"
    ):
        fail("R8 mapping is missing, truncated, or not a mapping file")
    native_details = validate_native_symbols(native)
    flutter_files = safe_files(flutter_dir)
    if any(path.suffix != ".symbols" for path in flutter_files):
        fail("Flutter Android symbol directory contains a non-symbol file")
    if len({path.name for path in flutter_files}) != len(flutter_files):
        fail("Flutter Android symbol directory contains duplicate filenames")
    flutter_by_name = {path.name: path for path in flutter_files if path.suffix == ".symbols"}
    missing = ANDROID_FLUTTER_SYMBOLS - flutter_by_name.keys()
    if missing:
        fail(f"Flutter Android symbols omit architectures: {sorted(missing)}")
    unexpected = set(flutter_by_name) - ANDROID_FLUTTER_SYMBOLS
    if unexpected:
        fail(f"unexpected Flutter Android symbol files: {sorted(unexpected)}")
    inputs = [
        ("r8/mapping.txt", mapping),
        ("native/native-debug-symbols.zip", native),
    ]
    inputs.extend((f"flutter/{name}", path) for name, path in flutter_by_name.items())
    write_archive(output, inputs)
    write_manifest(
        manifest,
        "android",
        output,
        inputs,
        {
            "r8Mapping": True,
            "nativeSymbols": native_details,
            "flutterArchitectures": sorted(
                name.removeprefix("app.android-").removesuffix(".symbols")
                for name in flutter_by_name
            ),
        },
    )
    print(f"Validated and archived Android R8, native, and Flutter symbols -> {output}")


UUID_PATTERN = re.compile(r"^UUID: ([0-9A-Fa-f-]{36}) \(([^)]+)\) ")


def macho_uuids(path: Path) -> list[dict[str, str]]:
    if not path.is_file() or path.is_symlink():
        fail(f"Mach-O binary is missing: {path}")
    try:
        completed = subprocess.run(
            ["/usr/bin/dwarfdump", "--uuid", str(path)],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        detail = getattr(error, "stderr", "") or str(error)
        fail(f"cannot inspect dSYM UUID for {path}: {detail.strip()}")
    result = []
    for line in completed.stdout.splitlines():
        match = UUID_PATTERN.match(line)
        if match:
            result.append({"uuid": match.group(1).upper(), "arch": match.group(2)})
    if not result:
        fail(f"dwarfdump returned no UUID for {path}")
    return sorted(result, key=lambda item: (item["arch"], item["uuid"]))


def app_binary(app: Path, binary_name: str) -> Path:
    runner = app / binary_name
    if runner.is_file():
        return runner
    framework = app / "Frameworks" / f"{binary_name}.framework" / binary_name
    if framework.is_file():
        return framework
    fail(f"dSYM has no matching binary in Runner.app: {binary_name}")


def ios_symbols(
    app: Path,
    dsym_root: Path,
    flutter_dir: Path,
    output: Path,
    manifest: Path,
) -> None:
    if not app.is_dir() or app.is_symlink():
        fail(f"iOS release app is missing or unsafe: {app}")
    dsym_paths = sorted(path for path in dsym_root.rglob("*.dSYM") if path.is_dir())
    if not dsym_paths:
        fail("iOS release build produced no dSYM bundles")
    names = {path.name for path in dsym_paths}
    for required in ("Runner.app.dSYM", "App.framework.dSYM"):
        if required not in names:
            fail(f"iOS release symbols omit {required}")
    uuid_details = []
    inputs: list[tuple[str, Path]] = []
    for dsym in dsym_paths:
        files = safe_files(dsym)
        dwarf_root = dsym / "Contents" / "Resources" / "DWARF"
        dwarf_files = safe_files(dwarf_root)
        relative_dsym = dsym.relative_to(dsym_root).as_posix()
        for dwarf in dwarf_files:
            binary = app_binary(app, dwarf.name)
            binary_uuids = macho_uuids(binary)
            dsym_uuids = macho_uuids(dwarf)
            if binary_uuids != dsym_uuids:
                fail(f"dSYM UUID does not match packaged binary: {relative_dsym}")
            uuid_details.append(
                {
                    "dSYM": relative_dsym,
                    "binary": dwarf.name,
                    "uuids": dsym_uuids,
                }
            )
        inputs.extend(
            (
                f"dsyms/{relative_dsym}/{path.relative_to(dsym).as_posix()}",
                path,
            )
            for path in files
        )
    flutter_files = safe_files(flutter_dir)
    if {path.name for path in flutter_files} != IOS_FLUTTER_SYMBOLS:
        fail(
            "Flutter iOS split-debug-info must contain exactly "
            f"{sorted(IOS_FLUTTER_SYMBOLS)}"
        )
    inputs.extend((f"flutter/{path.name}", path) for path in flutter_files)
    write_archive(output, inputs)
    write_manifest(
        manifest,
        "ios",
        output,
        inputs,
        {
            "dSYMCount": len(dsym_paths),
            "dSYMUUIDs": sorted(uuid_details, key=lambda item: item["dSYM"]),
            "flutterSymbols": sorted(path.name for path in flutter_files),
        },
    )
    print(
        f"Validated {len(dsym_paths)} iOS dSYM bundles and archived Flutter symbols -> {output}"
    )


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description=__doc__)
    commands = root.add_subparsers(dest="command", required=True)
    android = commands.add_parser("android")
    android.add_argument("--mapping", type=Path, required=True)
    android.add_argument("--native-symbols", type=Path, required=True)
    android.add_argument("--flutter-symbols", type=Path, required=True)
    android.add_argument("--output", type=Path, required=True)
    android.add_argument("--manifest", type=Path, required=True)
    ios = commands.add_parser("ios")
    ios.add_argument("--app", type=Path, required=True)
    ios.add_argument("--dsym-root", type=Path, required=True)
    ios.add_argument("--flutter-symbols", type=Path, required=True)
    ios.add_argument("--output", type=Path, required=True)
    ios.add_argument("--manifest", type=Path, required=True)
    verify = commands.add_parser("verify")
    verify.add_argument("--archive", type=Path, required=True)
    verify.add_argument("--manifest", type=Path, required=True)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "android":
            android_symbols(
                args.mapping,
                args.native_symbols,
                args.flutter_symbols,
                args.output,
                args.manifest,
            )
        elif args.command == "ios":
            ios_symbols(
                args.app,
                args.dsym_root,
                args.flutter_symbols,
                args.output,
                args.manifest,
            )
        else:
            verify_archive(args.archive, args.manifest)
    except (OSError, SymbolError) as error:
        print(f"release symbol verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
