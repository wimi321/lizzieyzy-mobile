#!/usr/bin/env python3
"""Generate and validate a deterministic CycloneDX 1.5 release SBOM.

The generator inventories Pub, CocoaPods, the locked desktop-bridge Python
wheel, and a resolved Gradle runtime report without downloading a schema or
adding a build-time package dependency. It is deliberately fail-closed:
release CI supplies every shipped ecosystem and the validator rejects missing
lockfile components, duplicate refs, unreviewed Python wheels, and local paths.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.parse
import uuid
from collections import defaultdict, deque
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
PUB_LOCK = ROOT / "pubspec.lock"
PACKAGE_CONFIG = ROOT / ".dart_tool" / "package_config.json"
DEFAULT_POD_LOCK = ROOT / "ios" / "Podfile.lock"
DEFAULT_PYTHON_LOCK = ROOT / "tool" / "katago_bridge" / "requirements.lock"
DEFAULT_MAVEN_POLICY = ROOT / "tool" / "native_license_policy.json"
DEFAULT_GRADLE_VERIFICATION = ROOT / "android" / "gradle" / "verification-metadata.xml"
SCHEMA = "http://cyclonedx.org/schema/bom-1.5.schema.json"
ROOT_PURL_PREFIX = "pkg:github/wimi321/lizzieyzy-mobile@"
LICENSE_FILES = ("LICENSE", "LICENSE.md", "COPYING", "COPYING.txt")
LICENSE_ORDER = (
    "BSD-3-Clause",
    "BSD-2-Clause",
    "MIT",
    "Apache-2.0",
    "MPL-2.0",
    "ISC",
    "Zlib",
)
PYTHON_LICENSE_POLICY = {
    "websockets": {
        "version": "16.0",
        "distributionUrl": (
            "https://files.pythonhosted.org/packages/6f/28/"
            "258ebab549c2bf3e64d2b0217b973467394a9cea8c42f70418ca2c5d0d2e/"
            "websockets-16.0-py3-none-any.whl"
        ),
        "distributionSha256": (
            "1637db62fad1dc833276dded54215f2c7fa46912301a24bd94d45d46a011ceec"
        ),
        "license": "BSD-3-Clause",
        "licenseFile": ROOT
        / "tool"
        / "katago_bridge"
        / "LICENSES"
        / "websockets-BSD-3-Clause.txt",
        "licenseTextSha256": (
            "61e8f0ecaaf9f48294f27b1b63a49312d34c807f3a2d9095fe5db5442c025d7b"
        ),
        "licenseUrl": "https://github.com/python-websockets/websockets/blob/16.0/LICENSE",
    }
}


class SbomError(RuntimeError):
    pass


def fail(message: str) -> None:
    raise SbomError(message)


def run_json(command: list[str]) -> dict[str, Any]:
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        value = json.loads(completed.stdout)
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or error.stdout or "").strip()
        fail(f"cannot run {' '.join(command)}: {detail or error}")
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot run {' '.join(command)}: {error}")
    if not isinstance(value, dict):
        fail(f"{' '.join(command)} did not return a JSON object")
    return value


def scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == '"':
        try:
            decoded = json.loads(value)
            if isinstance(decoded, str):
                return decoded
        except json.JSONDecodeError:
            pass
    return value


def parse_pub_lock(path: Path = PUB_LOCK) -> dict[str, dict[str, str]]:
    if not path.is_file():
        fail(f"missing lockfile: {path.relative_to(ROOT)}")
    packages: dict[str, dict[str, str]] = {}
    current: str | None = None
    in_packages = False
    for line in path.read_text("utf-8").splitlines():
        if line == "packages:":
            in_packages = True
            continue
        if not in_packages:
            continue
        if line and not line.startswith(" "):
            break
        match = re.fullmatch(r"  ([A-Za-z0-9_]+):", line)
        if match:
            current = match.group(1)
            packages[current] = {}
            continue
        if current is None:
            continue
        match = re.fullmatch(
            r"    (dependency|source|version):\s*(.+)", line
        )
        if match:
            packages[current][match.group(1)] = scalar(match.group(2))
            continue
        match = re.fullmatch(r"      sha256:\s*(.+)", line)
        if match:
            packages[current]["sha256"] = scalar(match.group(1))
    if not packages:
        fail("pubspec.lock contains no packages")
    return packages


def package_roots() -> dict[str, Path]:
    if not PACKAGE_CONFIG.is_file():
        fail(".dart_tool/package_config.json is missing; run flutter pub get")
    try:
        config = json.loads(PACKAGE_CONFIG.read_text("utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"invalid package_config.json: {error}")
    entries = config.get("packages")
    if not isinstance(entries, list):
        fail("package_config.json.packages must be an array")
    roots: dict[str, Path] = {}
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        name = entry.get("name")
        uri = entry.get("rootUri")
        if not isinstance(name, str) or not isinstance(uri, str):
            continue
        parsed = urllib.parse.urlparse(uri)
        if parsed.scheme == "file":
            root = Path(urllib.parse.unquote(parsed.path))
        elif parsed.scheme:
            continue
        else:
            root = (PACKAGE_CONFIG.parent / urllib.parse.unquote(uri)).resolve()
        roots[name] = root
    return roots


def license_ids(text: str) -> list[str]:
    normalized = " ".join(text.lower().split())
    found: set[str] = set()
    if "mozilla public license version 2.0" in normalized:
        found.add("MPL-2.0")
    if "apache license" in normalized and "version 2.0" in normalized:
        found.add("Apache-2.0")
    if "permission is hereby granted, free of charge" in normalized:
        found.add("MIT")
    if "redistribution and use in source and binary forms" in normalized:
        if "neither the name" in normalized or "names of its contributors" in normalized:
            found.add("BSD-3-Clause")
        else:
            found.add("BSD-2-Clause")
    if "isc license" in normalized:
        found.add("ISC")
    if "zlib license" in normalized:
        found.add("Zlib")
    return [item for item in LICENSE_ORDER if item in found]


def package_license(name: str, roots: dict[str, Path]) -> tuple[str | None, str | None]:
    root = roots.get(name)
    if root is None:
        return None, None
    for filename in LICENSE_FILES:
        path = root / filename
        if not path.is_file():
            continue
        text = path.read_text("utf-8", errors="replace")
        identifiers = license_ids(text)
        expression = " AND ".join(identifiers) if identifiers else None
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
        return expression, digest
    return None, None


def encode_segment(value: str) -> str:
    return urllib.parse.quote(value, safe="._-")


def pub_ref(name: str, version: str) -> str:
    return f"pkg:pub/{encode_segment(name)}@{encode_segment(version)}"


def pod_ref(name: str, version: str) -> str:
    if "/" in name:
        package, subspec = name.split("/", 1)
        return (
            f"pkg:cocoapods/{encode_segment(package)}@{encode_segment(version)}"
            f"?subspec={encode_segment(subspec)}"
        )
    return f"pkg:cocoapods/{encode_segment(name)}@{encode_segment(version)}"


def maven_ref(group: str, name: str, version: str) -> str:
    return (
        f"pkg:maven/{encode_segment(group)}/{encode_segment(name)}"
        f"@{encode_segment(version)}"
    )


def pypi_ref(name: str, version: str) -> str:
    return f"pkg:pypi/{encode_segment(name)}@{encode_segment(version)}"


def normalize_python_name(value: str) -> str:
    return re.sub(r"[-_.]+", "-", value).lower()


def parse_python_lock(path: Path = DEFAULT_PYTHON_LOCK) -> list[dict[str, Any]]:
    """Parse the bridge's deliberately narrow direct-wheel requirements lock."""

    if not path.is_file():
        fail(f"missing Python bridge lockfile: {path}")
    logical_lines: list[str] = []
    pending = ""
    for raw_line in path.read_text("utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.endswith("\\"):
            pending += line[:-1].rstrip() + " "
            continue
        logical_lines.append((pending + line).strip())
        pending = ""
    if pending:
        fail("Python bridge lockfile ends with an incomplete continuation")
    if not logical_lines:
        fail("Python bridge lockfile contains no requirements")

    components: list[dict[str, Any]] = []
    seen: set[str] = set()
    pattern = re.compile(
        r"([A-Za-z0-9][A-Za-z0-9._-]*)\s+@\s+(https://\S+)\s+"
        r"--hash=sha256:([0-9a-f]{64})"
    )
    wheel_pattern = re.compile(
        r"([A-Za-z0-9_.]+)-([A-Za-z0-9_.!+]+)-py3-none-any\.whl"
    )
    for index, line in enumerate(logical_lines, start=1):
        match = pattern.fullmatch(line)
        if match is None:
            fail(
                "Python bridge requirement must be an HTTPS direct wheel with "
                f"one SHA-256 hash (logical line {index})"
            )
        declared_name, distribution_url, digest = match.groups()
        parsed = urllib.parse.urlparse(distribution_url)
        if (
            parsed.scheme != "https"
            or parsed.hostname != "files.pythonhosted.org"
            or parsed.username is not None
            or parsed.password is not None
            or parsed.port is not None
            or parsed.query
            or parsed.fragment
        ):
            fail(
                "Python bridge wheel must use an unmodified "
                "files.pythonhosted.org HTTPS URL"
            )
        filename = Path(urllib.parse.unquote(parsed.path)).name
        wheel = wheel_pattern.fullmatch(filename)
        if wheel is None:
            fail("Python bridge dependency must use a universal py3-none-any wheel")
        wheel_name, version = wheel.groups()
        normalized_name = normalize_python_name(declared_name)
        if normalized_name != normalize_python_name(wheel_name):
            fail(
                "Python bridge requirement name does not match its wheel: "
                f"{declared_name} != {wheel_name}"
            )
        policy = PYTHON_LICENSE_POLICY.get(normalized_name)
        if policy is None:
            fail(f"unreviewed Python bridge dependency: {declared_name}")
        if (
            version != policy["version"]
            or distribution_url != policy["distributionUrl"]
            or digest != policy["distributionSha256"]
        ):
            fail(
                f"unreviewed Python bridge artifact change for {declared_name}; "
                "version, URL, and SHA-256 must match the reviewed policy"
            )
        ref = pypi_ref(normalized_name, version)
        if ref in seen:
            fail(f"duplicate Python bridge dependency: {ref}")
        seen.add(ref)
        license_path = policy["licenseFile"]
        if not isinstance(license_path, Path) or not license_path.is_file():
            fail(f"missing reviewed Python license text for {declared_name}")
        license_text = license_path.read_text("utf-8", errors="strict")
        detected = license_ids(license_text)
        license_id = policy["license"]
        if detected != [license_id]:
            fail(
                f"Python license evidence drift for {declared_name}: "
                f"expected {license_id}, detected {detected}"
            )
        license_digest = hashlib.sha256(license_text.encode("utf-8")).hexdigest()
        if license_digest != policy["licenseTextSha256"]:
            fail(f"reviewed Python license text changed for {declared_name}")
        components.append(
            {
                "type": "library",
                "bom-ref": ref,
                "group": "pypi.org",
                "name": normalized_name,
                "version": version,
                "scope": "optional",
                "purl": ref,
                "hashes": [{"alg": "SHA-256", "content": digest}],
                "licenses": [{"expression": license_id}],
                "externalReferences": [
                    {"type": "distribution", "url": distribution_url},
                    {"type": "license", "url": policy["licenseUrl"]},
                ],
                "properties": [
                    {"name": "lizzieyzy:ecosystem", "value": "python"},
                    {
                        "name": "lizzieyzy:artifact-resolution",
                        "value": "direct-wheel-url-with-sha256",
                    },
                    {
                        "name": "lizzieyzy:lockfile",
                        "value": "tool/katago_bridge/requirements.lock",
                    },
                    {
                        "name": "lizzieyzy:component-boundary",
                        "value": "user-deployed-desktop-tool-not-mobile-binary",
                    },
                    {
                        "name": "lizzieyzy:license-text-sha256",
                        "value": license_digest,
                    },
                ],
            }
        )
    return sorted(components, key=lambda item: item["bom-ref"])


def dependency_closure(
    packages: dict[str, dict[str, Any]], roots: Iterable[str]
) -> set[str]:
    visited: set[str] = set()
    pending = deque(roots)
    while pending:
        name = pending.popleft()
        if name in visited or name not in packages:
            continue
        visited.add(name)
        dependencies = packages[name].get("directDependencies", [])
        if isinstance(dependencies, list):
            pending.extend(item for item in dependencies if isinstance(item, str))
    return visited


def pub_components() -> tuple[
    dict[str, Any],
    list[dict[str, Any]],
    dict[str, set[str]],
]:
    graph = run_json(["flutter", "pub", "deps", "--json"])
    package_entries = graph.get("packages")
    root_name = graph.get("root")
    if not isinstance(package_entries, list) or not isinstance(root_name, str):
        fail("dart pub deps JSON is missing root/packages")
    packages = {
        entry["name"]: entry
        for entry in package_entries
        if isinstance(entry, dict) and isinstance(entry.get("name"), str)
    }
    root_package = packages.get(root_name)
    if root_package is None:
        fail("dart pub deps JSON does not contain its root package")
    runtime_roots = root_package.get("directDependencies", [])
    if not isinstance(runtime_roots, list):
        fail("root directDependencies must be an array")
    runtime = dependency_closure(packages, runtime_roots)
    sdk_versions = {
        entry["name"].lower(): entry["version"]
        for entry in graph.get("sdks", [])
        if isinstance(entry, dict)
        and isinstance(entry.get("name"), str)
        and isinstance(entry.get("version"), str)
    }
    flutter_version = sdk_versions.get("flutter")
    dart_version = sdk_versions.get("dart")
    if flutter_version is None or dart_version is None:
        fail("dart pub deps JSON is missing Flutter/Dart SDK versions")
    lock = parse_pub_lock()
    roots = package_roots()
    components: list[dict[str, Any]] = []
    refs: dict[str, str] = {}
    for name, entry in packages.items():
        if name == root_name:
            continue
        version = entry.get("version")
        source = entry.get("source")
        if not isinstance(version, str) or not isinstance(source, str):
            fail(f"invalid Pub package metadata for {name}")
        component_version = flutter_version if source == "sdk" else version
        ref = pub_ref(name, component_version)
        refs[name] = ref
        component: dict[str, Any] = {
            "type": "framework" if name == "flutter" else "library",
            "bom-ref": ref,
            "group": "pub.dev" if source == "hosted" else "flutter-sdk",
            "name": name,
            "version": component_version,
            "scope": "required" if name in runtime else "excluded",
            "purl": ref,
            "properties": [
                {"name": "lizzieyzy:ecosystem", "value": "pub"},
                {"name": "lizzieyzy:pub-source", "value": source},
            ],
        }
        locked = lock.get(name, {})
        digest = locked.get("sha256")
        if source == "hosted":
            if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
                fail(f"hosted package {name} is missing a lockfile SHA-256")
            component["hashes"] = [{"alg": "SHA-256", "content": digest}]
            component["externalReferences"] = [
                {
                    "type": "distribution",
                    "url": f"https://pub.dev/packages/{name}/versions/{version}",
                }
            ]
        expression, license_digest = package_license(name, roots)
        if source == "sdk" and expression is None:
            expression = "BSD-3-Clause"
        if expression:
            component["licenses"] = [{"expression": expression}]
        if license_digest:
            component["properties"].append(
                {"name": "lizzieyzy:license-text-sha256", "value": license_digest}
            )
        if source == "sdk":
            component["properties"].append(
                {"name": "lizzieyzy:resolved-sdk-version", "value": flutter_version}
            )
        components.append(component)

    dependencies: dict[str, set[str]] = defaultdict(set)
    root_version = root_package.get("version")
    if not isinstance(root_version, str):
        fail("root package version is missing")
    root_ref = ROOT_PURL_PREFIX + encode_segment(root_version)
    root_dependencies = root_package.get("dependencies", [])
    if isinstance(root_dependencies, list):
        dependencies[root_ref].update(
            refs[name] for name in root_dependencies if name in refs
        )
    for name, entry in packages.items():
        if name == root_name or name not in refs:
            continue
        children = entry.get("directDependencies", [])
        if isinstance(children, list):
            dependencies[refs[name]].update(
                refs[child] for child in children if child in refs
            )
    root_component = {
        "type": "application",
        "bom-ref": root_ref,
        "name": root_name,
        "version": root_version,
        "purl": root_ref,
        "licenses": [{"expression": "MPL-2.0"}],
        "properties": [
            {"name": "lizzieyzy:flutter-sdk-version", "value": flutter_version},
            {"name": "lizzieyzy:dart-sdk-version", "value": dart_version},
        ],
    }
    return root_component, components, dependencies


def parse_pod_lock(
    path: Path,
) -> tuple[list[dict[str, Any]], dict[str, set[str]], set[str]]:
    if not path.is_file():
        fail(f"missing CocoaPods lockfile: {path}")
    pods: dict[str, str] = {}
    edges_by_name: dict[str, set[str]] = defaultdict(set)
    declared: set[str] = set()
    section: str | None = None
    current: str | None = None
    for line in path.read_text("utf-8").splitlines():
        if line and not line.startswith(" ") and line.endswith(":"):
            section = line[:-1]
            current = None
            continue
        if section == "PODS":
            match = re.fullmatch(r"  - (.+?) \(([^)]+)\):?", line)
            if match:
                current = match.group(1).strip('"')
                pods[current] = match.group(2)
                continue
            match = re.fullmatch(r"    - (.+?)(?: \([^)]+\))?", line)
            if match and current:
                edges_by_name[current].add(match.group(1).strip('"'))
        elif section == "DEPENDENCIES":
            match = re.fullmatch(r"  - (.+?)(?: \(.+\))?", line)
            if match:
                declared.add(match.group(1).strip('"'))
    checksums: dict[str, str] = {}
    checksum_section = False
    for line in path.read_text("utf-8").splitlines():
        if line == "SPEC CHECKSUMS:":
            checksum_section = True
            continue
        if checksum_section and line and not line.startswith(" "):
            break
        if checksum_section:
            match = re.fullmatch(r"  (.+): ([0-9a-f]{40})", line)
            if match:
                checksums[match.group(1)] = match.group(2)
    components: list[dict[str, Any]] = []
    refs = {name: pod_ref(name, version) for name, version in pods.items()}
    for name, version in pods.items():
        base_name = name.split("/", 1)[0]
        properties = [
            {"name": "lizzieyzy:ecosystem", "value": "cocoapods"},
            {
                "name": "lizzieyzy:license-review",
                "value": "Bundled CocoaPods acknowledgements",
            },
        ]
        checksum = checksums.get(base_name)
        if checksum:
            properties.append(
                {"name": "lizzieyzy:podspec-sha1", "value": checksum}
            )
        components.append(
            {
                "type": "library",
                "bom-ref": refs[name],
                "group": "cocoapods",
                "name": name,
                "version": version,
                "scope": "required",
                "purl": refs[name],
                "licenses": [
                    {"license": {"name": "See bundled CocoaPods acknowledgements"}}
                ],
                "properties": properties,
            }
        )
    dependencies: dict[str, set[str]] = defaultdict(set)
    for name, children in edges_by_name.items():
        if name not in refs:
            continue
        dependencies[refs[name]].update(refs[child] for child in children if child in refs)
    return components, dependencies, {refs[name] for name in declared if name in refs}


MAVEN_PATTERN = re.compile(
    r"(?:\+---|\\---)\s+"
    r"([A-Za-z0-9_.-]+):([A-Za-z0-9_.-]+):([^\s(]+)"
    r"(?:\s+->\s+([^\s(]+))?"
)


def parse_android_report(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        fail(f"missing Android dependency report: {path}")
    modules: set[tuple[str, str, str]] = set()
    for line in path.read_text("utf-8", errors="replace").splitlines():
        match = MAVEN_PATTERN.search(line)
        if match is None:
            continue
        group, name, requested, selected = match.groups()
        version = selected or requested
        if version in {"FAILED", "unspecified"} or version.startswith("{"):
            continue
        modules.add((group, name, version))
    if not modules:
        fail("Android dependency report contains no resolved Maven modules")
    return [
        {
            "type": "library",
            "bom-ref": maven_ref(group, name, version),
            "group": group,
            "name": name,
            "version": version,
            "scope": "required",
            "purl": maven_ref(group, name, version),
            "properties": [
                {"name": "lizzieyzy:ecosystem", "value": "maven"},
                {
                    "name": "lizzieyzy:license-review",
                    "value": "Resolve from POM and preserve NOTICE before release",
                },
            ],
        }
        for group, name, version in sorted(modules)
    ]


def load_maven_manifest(path: Path) -> dict[str, dict[str, Any]]:
    try:
        value = json.loads(path.read_text("utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot parse Maven artifact manifest: {error}")
    if not isinstance(value, dict) or value.get("schemaVersion") != 1:
        fail("Maven artifact manifest must use schemaVersion 1")
    expected_policy = hashlib.sha256(DEFAULT_MAVEN_POLICY.read_bytes()).hexdigest()
    expected_verification = hashlib.sha256(
        DEFAULT_GRADLE_VERIFICATION.read_bytes()
    ).hexdigest()
    if value.get("licensePolicySha256") != expected_policy:
        fail("Maven artifact manifest uses an unreviewed license policy")
    if value.get("gradleVerificationSha256") != expected_verification:
        fail("Maven artifact manifest differs from Gradle dependency verification")
    entries = value.get("components")
    if not isinstance(entries, list) or not entries:
        fail("Maven artifact manifest contains no components")
    result: dict[str, dict[str, Any]] = {}
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict) or not isinstance(entry.get("purl"), str):
            fail(f"invalid Maven artifact manifest component {index}")
        purl = entry["purl"]
        if purl in result:
            fail(f"duplicate Maven artifact manifest component: {purl}")
        result[purl] = entry
    return result


def enrich_maven_components(
    components: list[dict[str, Any]], manifest_path: Path
) -> None:
    manifest = load_maven_manifest(manifest_path)
    graph_refs = [component["purl"] for component in components]
    refs = set(graph_refs)
    if refs != set(manifest):
        fail(
            "Maven artifact manifest differs from resolved runtime graph: "
            f"missing={sorted(refs - set(manifest))}, "
            f"unknown={sorted(set(manifest) - refs)}"
        )
    raw_manifest = json.loads(manifest_path.read_text("utf-8"))
    graph_sha256 = hashlib.sha256(
        ("\n".join(graph_refs) + "\n").encode("utf-8")
    ).hexdigest()
    if raw_manifest.get("resolvedGraphSha256") != graph_sha256:
        fail("Maven artifact manifest differs from the resolved runtime graph")
    for component in components:
        entry = manifest[component["purl"]]
        license_id = entry.get("license")
        license_url = entry.get("licenseUrl")
        resolution = entry.get("resolution")
        artifacts = entry.get("artifacts")
        if (
            not isinstance(license_id, str)
            or not isinstance(license_url, str)
            or resolution != "gradle-sha256-lock"
            or not isinstance(artifacts, list)
        ):
            fail(f"incomplete Maven legal/artifact evidence for {component['purl']}")
        component["licenses"] = [{"expression": license_id}]
        component["externalReferences"] = [
            {"type": "license", "url": license_url}
        ]
        component["properties"] = [
            {"name": "lizzieyzy:ecosystem", "value": "maven"},
            {"name": "lizzieyzy:artifact-resolution", "value": resolution},
        ]
        binary_hashes: list[dict[str, str]] = []
        for artifact in artifacts:
            if not isinstance(artifact, dict):
                fail(f"invalid Maven artifact evidence for {component['purl']}")
            filename = artifact.get("file")
            digest = artifact.get("sha256")
            kind = artifact.get("kind")
            if (
                not isinstance(filename, str)
                or not isinstance(digest, str)
                or not re.fullmatch(r"[0-9a-f]{64}", digest)
                or kind not in {"aar", "jar", "module", "pom"}
            ):
                fail(f"invalid Maven artifact hash for {component['purl']}")
            component["properties"].append(
                {
                    "name": f"lizzieyzy:artifact:{filename}:sha256",
                    "value": digest,
                }
            )
            if kind in {"aar", "jar"}:
                binary_hashes.append({"alg": "SHA-256", "content": digest})
        if binary_hashes:
            component["hashes"] = sorted(
                binary_hashes, key=lambda item: item["content"]
            )


def release_artifact_components(path: Path) -> list[dict[str, Any]]:
    try:
        value = json.loads(path.read_text("utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot parse release artifact digest manifest: {error}")
    if not isinstance(value, dict) or value.get("schemaVersion") != 1:
        fail("release artifact digest manifest must use schemaVersion 1")
    artifacts = value.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        fail("release artifact digest manifest contains no artifacts")
    result: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, artifact in enumerate(artifacts):
        if not isinstance(artifact, dict):
            fail(f"release artifact {index} is not an object")
        name = artifact.get("name")
        filename = artifact.get("file")
        digest = artifact.get("sha256")
        size = artifact.get("bytes")
        media_type = artifact.get("mediaType")
        if (
            not isinstance(name, str)
            or not name
            or name in seen
            or not isinstance(filename, str)
            or "/" in filename
            or not re.fullmatch(r"[0-9a-f]{64}", digest or "")
            or not isinstance(size, int)
            or size <= 0
            or not isinstance(media_type, str)
        ):
            fail(f"invalid release artifact digest entry {index}")
        seen.add(name)
        ref = f"urn:sha256:{digest}#{encode_segment(name)}"
        result.append(
            {
                "type": "file",
                "bom-ref": ref,
                "name": name,
                "version": digest[:12],
                "scope": "required",
                "hashes": [{"alg": "SHA-256", "content": digest}],
                "properties": [
                    {"name": "lizzieyzy:ecosystem", "value": "release-artifact"},
                    {"name": "lizzieyzy:file-name", "value": filename},
                    {"name": "lizzieyzy:file-bytes", "value": str(size)},
                    {"name": "lizzieyzy:media-type", "value": media_type},
                ],
            }
        )
    return sorted(result, key=lambda item: item["bom-ref"])


def timestamp() -> str:
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if epoch:
        try:
            value = dt.datetime.fromtimestamp(int(epoch), tz=dt.timezone.utc)
            return value.isoformat().replace("+00:00", "Z")
        except (ValueError, OSError):
            fail("SOURCE_DATE_EPOCH must be an integer Unix timestamp")
    try:
        value = subprocess.run(
            ["git", "show", "-s", "--format=%cI", "HEAD"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed.astimezone(dt.timezone.utc).isoformat().replace("+00:00", "Z")
    except (OSError, subprocess.CalledProcessError, ValueError):
        return "1970-01-01T00:00:00Z"


def merge_dependencies(
    target: dict[str, set[str]], source: dict[str, set[str]]
) -> None:
    for ref, children in source.items():
        target[ref].update(children)


def generate(
    output: Path,
    pod_lock: Path | None,
    python_lock: Path,
    android_report: Path | None,
    maven_manifest: Path | None,
    artifact_digests: Path | None,
) -> None:
    root_component, components, dependencies = pub_components()
    ecosystems = {"pub"}
    if pod_lock is not None:
        pod_components, pod_dependencies, declared_pods = parse_pod_lock(pod_lock)
        components.extend(pod_components)
        merge_dependencies(dependencies, pod_dependencies)
        dependencies[root_component["bom-ref"]].update(declared_pods)
        ecosystems.add("cocoapods")
    python_components = parse_python_lock(python_lock)
    components.extend(python_components)
    dependencies[root_component["bom-ref"]].update(
        component["bom-ref"] for component in python_components
    )
    ecosystems.add("python")
    if android_report is not None:
        android_components = parse_android_report(android_report)
        if maven_manifest is None:
            fail("--maven-manifest is required with --android-report")
        enrich_maven_components(android_components, maven_manifest)
        components.extend(android_components)
        dependencies[root_component["bom-ref"]].update(
            component["bom-ref"] for component in android_components
        )
        ecosystems.add("maven")
    elif maven_manifest is not None:
        fail("--maven-manifest requires --android-report")
    if artifact_digests is not None:
        artifacts = release_artifact_components(artifact_digests)
        components.extend(artifacts)
        ecosystems.add("release-artifact")

    deduplicated: dict[str, dict[str, Any]] = {}
    for component in components:
        ref = component["bom-ref"]
        existing = deduplicated.get(ref)
        if existing is not None and existing != component:
            fail(f"conflicting components use bom-ref {ref}")
        deduplicated[ref] = component
    components = sorted(deduplicated.values(), key=lambda item: item["bom-ref"])
    material = "\n".join(
        [root_component["bom-ref"]]
        + [
            item["bom-ref"]
            + "|"
            + ",".join(
                sorted(
                    digest["content"]
                    for digest in item.get("hashes", [])
                    if isinstance(digest, dict)
                    and isinstance(digest.get("content"), str)
                )
            )
            for item in components
        ]
    )
    serial = uuid.uuid5(uuid.NAMESPACE_URL, material)
    all_refs = {root_component["bom-ref"], *(item["bom-ref"] for item in components)}
    dependency_entries = []
    for ref in sorted(all_refs):
        children = sorted(child for child in dependencies.get(ref, set()) if child in all_refs)
        dependency_entries.append({"ref": ref, "dependsOn": children})
    bom = {
        "$schema": SCHEMA,
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{serial}",
        "version": 1,
        "metadata": {
            "timestamp": timestamp(),
            "tools": {
                "components": [
                    {
                        "type": "application",
                        "name": "lizzieyzy-sbom",
                        "version": "1",
                    }
                ]
            },
            "component": root_component,
            "properties": [
                {
                    "name": "lizzieyzy:included-ecosystems",
                    "value": ",".join(sorted(ecosystems)),
                },
                {
                    "name": "lizzieyzy:generation-policy",
                    "value": "lockfiles-and-resolved-runtime-graph",
                },
            ],
        },
        "components": components,
        "dependencies": dependency_entries,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(bom, ensure_ascii=False, indent=2) + "\n", "utf-8")
    print(
        f"Generated CycloneDX 1.5 SBOM with {len(components)} components "
        f"({', '.join(sorted(ecosystems))}): {output}"
    )


def properties_map(value: Any) -> dict[str, str]:
    if not isinstance(value, list):
        return {}
    return {
        item["name"]: item["value"]
        for item in value
        if isinstance(item, dict)
        and isinstance(item.get("name"), str)
        and isinstance(item.get("value"), str)
    }


def validate(path: Path, required_ecosystems: set[str]) -> None:
    try:
        bom = json.loads(path.read_text("utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot parse SBOM: {error}")
    if not isinstance(bom, dict):
        fail("SBOM root must be an object")
    expected = {
        "$schema": SCHEMA,
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "version": 1,
    }
    for key, value in expected.items():
        if bom.get(key) != value:
            fail(f"SBOM {key} must be {value!r}")
    serial = bom.get("serialNumber")
    if not isinstance(serial, str) or not re.fullmatch(
        r"urn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}",
        serial,
    ):
        fail("SBOM serialNumber must be a deterministic UUIDv5 URN")
    metadata = bom.get("metadata")
    if not isinstance(metadata, dict):
        fail("SBOM metadata must be an object")
    root_component = metadata.get("component")
    if not isinstance(root_component, dict):
        fail("SBOM metadata.component must be an object")
    root_ref = root_component.get("bom-ref")
    if not isinstance(root_ref, str) or not root_ref.startswith(ROOT_PURL_PREFIX):
        fail("SBOM metadata.component has an invalid root bom-ref")
    ecosystems = set(
        properties_map(metadata.get("properties"))
        .get("lizzieyzy:included-ecosystems", "")
        .split(",")
    )
    ecosystems.discard("")
    missing_ecosystems = required_ecosystems - ecosystems
    if missing_ecosystems:
        fail(f"SBOM is missing required ecosystems: {sorted(missing_ecosystems)}")

    components = bom.get("components")
    if not isinstance(components, list) or not components:
        fail("SBOM components must be a non-empty array")
    refs: set[str] = {root_ref}
    purls: set[str] = set()
    component_by_purl: dict[str, dict[str, Any]] = {}
    previous_ref = ""
    for index, component in enumerate(components):
        if not isinstance(component, dict):
            fail(f"components[{index}] must be an object")
        for key in ("type", "bom-ref", "name", "version"):
            if not isinstance(component.get(key), str) or not component[key]:
                fail(f"components[{index}].{key} must be a non-empty string")
        ref = component["bom-ref"]
        purl = component.get("purl")
        props = properties_map(component.get("properties"))
        if props.get("lizzieyzy:ecosystem") == "release-artifact":
            if purl is not None or not ref.startswith("urn:sha256:"):
                fail(f"release artifact {component['name']} has an invalid bom-ref")
            hashes = component.get("hashes")
            if (
                not isinstance(hashes, list)
                or len(hashes) != 1
                or hashes[0].get("alg") != "SHA-256"
                or not re.fullmatch(r"[0-9a-f]{64}", hashes[0].get("content", ""))
                or hashes[0]["content"] not in ref
            ):
                fail(f"release artifact {component['name']} has an invalid digest")
        elif not isinstance(purl, str) or ref != purl:
            fail(f"component {component['name']} must use its purl as bom-ref")
        if ref <= previous_ref:
            fail("SBOM components must be uniquely sorted by bom-ref")
        previous_ref = ref
        if ref in refs or (isinstance(purl, str) and purl in purls):
            fail(f"duplicate SBOM component reference: {ref}")
        refs.add(ref)
        if isinstance(purl, str):
            purls.add(purl)
            component_by_purl[purl] = component
        if component.get("scope") not in {"required", "optional", "excluded"}:
            fail(f"component {ref} has an invalid scope")
        if isinstance(purl, str) and purl.startswith("pkg:pub/") and component.get("group") == "pub.dev":
            hashes = component.get("hashes")
            if (
                not isinstance(hashes, list)
                or len(hashes) != 1
                or hashes[0].get("alg") != "SHA-256"
                or not re.fullmatch(r"[0-9a-f]{64}", hashes[0].get("content", ""))
            ):
                fail(f"hosted Pub component {ref} is missing its lockfile hash")

    lock = parse_pub_lock()
    component_names = {
        component["name"]
        for component in components
        if isinstance(component, dict) and isinstance(component.get("name"), str)
    }
    for name, entry in lock.items():
        version = entry.get("version")
        if entry.get("source") == "sdk":
            if name not in component_names:
                fail(f"SBOM omits locked SDK package {name}")
        elif isinstance(version, str) and pub_ref(name, version) not in component_by_purl:
            fail(f"SBOM omits locked Pub package {name} {version}")
    if "cocoapods" in required_ecosystems:
        pod_components, _, _ = parse_pod_lock(DEFAULT_POD_LOCK)
        for component in pod_components:
            if component["purl"] not in component_by_purl:
                fail(f"SBOM omits locked CocoaPod {component['name']} {component['version']}")
    if "maven" in required_ecosystems:
        required_mlkit = maven_ref("com.google.mlkit", "text-recognition", "16.0.1")
        if required_mlkit not in component_by_purl:
            fail("SBOM omits the pinned Android ML Kit text-recognition runtime")
        maven_components = [
            component
            for component in components
            if properties_map(component.get("properties")).get("lizzieyzy:ecosystem")
            == "maven"
        ]
        for component in maven_components:
            props = properties_map(component.get("properties"))
            if props.get("lizzieyzy:artifact-resolution") not in {
                "gradle-sha256-lock",
            }:
                fail(f"Maven component lacks artifact resolution: {component['bom-ref']}")
            if not isinstance(component.get("licenses"), list):
                fail(f"Maven component lacks reviewed license: {component['bom-ref']}")
    if "python" in required_ecosystems:
        expected_python = {
            component["purl"]: component
            for component in parse_python_lock(DEFAULT_PYTHON_LOCK)
        }
        actual_python = {
            component["purl"]: component
            for component in components
            if properties_map(component.get("properties")).get(
                "lizzieyzy:ecosystem"
            )
            == "python"
        }
        if actual_python != expected_python:
            fail(
                "SBOM Python components differ from the reviewed bridge lock, "
                "wheel hashes, or license evidence"
            )
    if "release-artifact" in required_ecosystems:
        release_components = [
            component
            for component in components
            if properties_map(component.get("properties")).get("lizzieyzy:ecosystem")
            == "release-artifact"
        ]
        if len(release_components) < 2:
            fail("SBOM must include both Android and iOS release candidates")

    dependency_entries = bom.get("dependencies")
    if not isinstance(dependency_entries, list):
        fail("SBOM dependencies must be an array")
    dependency_refs: set[str] = set()
    for index, dependency in enumerate(dependency_entries):
        if not isinstance(dependency, dict):
            fail(f"dependencies[{index}] must be an object")
        ref = dependency.get("ref")
        children = dependency.get("dependsOn")
        if ref not in refs or not isinstance(children, list):
            fail(f"dependencies[{index}] contains an unknown ref or invalid dependsOn")
        if ref in dependency_refs:
            fail(f"duplicate dependency entry: {ref}")
        dependency_refs.add(ref)
        if len(children) != len(set(children)) or any(child not in refs for child in children):
            fail(f"dependency entry {ref} contains duplicate or unknown children")
    if dependency_refs != refs:
        fail("every component and the root must have one dependency entry")

    serialized = json.dumps(bom, ensure_ascii=False)
    forbidden = (str(ROOT), "/Users/", "file://", "\\Users\\")
    if any(value in serialized for value in forbidden):
        fail("SBOM leaks a local absolute path")
    print(
        f"Validated CycloneDX 1.5 SBOM: {len(components)} components; "
        f"ecosystems={','.join(sorted(ecosystems))}."
    )


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description=__doc__)
    commands = root.add_subparsers(dest="command", required=True)
    generate_parser = commands.add_parser("generate")
    generate_parser.add_argument("--output", type=Path, required=True)
    generate_parser.add_argument(
        "--pod-lock",
        type=Path,
        default=DEFAULT_POD_LOCK,
        help="CocoaPods lockfile; pass an empty path only through API tests",
    )
    generate_parser.add_argument(
        "--python-lock",
        type=Path,
        default=DEFAULT_PYTHON_LOCK,
        help="locked direct-wheel requirements for the desktop KataGo bridge",
    )
    generate_parser.add_argument("--android-report", type=Path)
    generate_parser.add_argument("--maven-manifest", type=Path)
    generate_parser.add_argument("--artifact-digests", type=Path)
    validate_parser = commands.add_parser("validate")
    validate_parser.add_argument("--input", type=Path, required=True)
    validate_parser.add_argument(
        "--require-ecosystem",
        action="append",
        default=[],
        choices=("pub", "cocoapods", "python", "maven", "release-artifact"),
    )
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "generate":
            generate(
                args.output,
                args.pod_lock,
                args.python_lock,
                args.android_report,
                args.maven_manifest,
                args.artifact_digests,
            )
        else:
            validate(args.input, set(args.require_ecosystem))
    except (SbomError, OSError, ValueError) as error:
        print(f"SBOM {args.command} failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
