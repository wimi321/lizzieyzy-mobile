#!/usr/bin/env python3
"""Guard external-kifu native lifecycle, filtering, and failure contracts."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ANDROID = ROOT / "android/app/src/main/kotlin/com/wimi321/lizzieyzy/mobile/MainActivity.kt"
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
IOS = ROOT / "ios/Runner/AppDelegate.swift"
DART = ROOT / "lib/infrastructure/kifu/platform_inbound_kifu_service.dart"
MAIN = ROOT / "lib/main.dart"
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"
TOOLS_NS = "{http://schemas.android.com/tools}"


def require(contents: str, fragments: tuple[str, ...], label: str) -> None:
    for fragment in fragments:
        if fragment not in contents:
            raise RuntimeError(f"{label} is missing required contract: {fragment}")


def forbid(contents: str, fragments: tuple[str, ...], label: str) -> None:
    for fragment in fragments:
        if fragment in contents:
            raise RuntimeError(f"{label} restored a forbidden contract: {fragment}")


def verify_manifest() -> None:
    root = ET.parse(MANIFEST).getroot()
    features = {
        feature.attrib.get(f"{ANDROID_NS}name"): feature
        for feature in root.findall("uses-feature")
    }
    for name in ("android.hardware.camera.any", "android.hardware.camera"):
        feature = features.get(name)
        if feature is None or feature.attrib.get(f"{ANDROID_NS}required") != "false":
            raise RuntimeError(f"{name} must be explicitly optional")
    camera_any = features["android.hardware.camera.any"]
    if camera_any.attrib.get(f"{TOOLS_NS}replace") != "android:required":
        raise RuntimeError("camera.any must override the plugin's required feature")
    for data in root.iter("data"):
        if data.attrib.get(f"{ANDROID_NS}pathPattern") is not None:
            raise RuntimeError("scheme-only pathPattern intent filters are forbidden")


def main() -> int:
    try:
        android = ANDROID.read_text("utf-8")
        ios = IOS.read_text("utf-8")
        dart = DART.read_text("utf-8")
        entrypoint = MAIN.read_text("utf-8")
        verify_manifest()
        require(
            android,
            (
                "READ_TIMEOUT_SECONDS",
                "ArrayBlockingQueue(MAX_QUEUED_READS)",
                "CancellationSignal",
                "initialTakeCalled",
                "MAX_PENDING_RUNTIME_EVENTS",
                'NATIVE_READ_ERROR = "unreadable"',
            ),
            "Android inbound bridge",
        )
        require(
            ios,
            (
                "readTimeout: TimeInterval",
                "maximumPendingReads",
                "initialTakeCalled",
                "pendingReads:",
                "resolveLocked",
                'nativeReadError = "unreadable"',
            ),
            "iOS inbound bridge",
        )
        require(
            dart,
            (
                "NativeInboundKifuReadException",
                "initialReadTimeout",
                "raw.length != 1",
                "Every explicit open is delivered",
            ),
            "Dart inbound bridge",
        )
        forbid(
            android + ios + dart,
            (
                "seenFingerprints",
                "rememberFingerprint",
                "maximumRememberedDigests",
                "_seenDigests",
            ),
            "native inbound bridge",
        )
        run_app = entrypoint.index("runApp(")
        initialize = entrypoint.index("unawaited(inboundKifu.initialize())")
        if run_app >= initialize:
            raise RuntimeError("external file I/O must begin only after runApp")
    except (OSError, ET.ParseError, RuntimeError, ValueError) as error:
        print(f"native inbound contract verification failed: {error}", file=sys.stderr)
        return 1
    print("Native inbound filtering, timeout, error, and replay contracts verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
