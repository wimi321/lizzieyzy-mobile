#!/usr/bin/env python3
"""Validate app privacy declarations and Xcode target membership."""

from __future__ import annotations

import argparse
import plistlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "ios" / "Runner" / "PrivacyInfo.xcprivacy"
PROJECT = ROOT / "ios" / "Runner.xcodeproj" / "project.pbxproj"
INFO_PLIST = ROOT / "ios" / "Runner" / "Info.plist"
PRIVACY = ROOT / "PRIVACY.md"
DATA_SAFETY = ROOT / "docs" / "ANDROID_DATA_SAFETY.md"
POD_LOCK = ROOT / "ios" / "Podfile.lock"
MLKIT_COMMON_MANIFEST = (
    ROOT
    / "ios"
    / "Pods"
    / "MLKitCommon"
    / "Frameworks"
    / "MLKitCommon.framework"
    / "PrivacyInfo.xcprivacy"
)
MLKIT_TEXT_MANIFEST = (
    ROOT
    / "ios"
    / "Pods"
    / "MLKitTextRecognitionCommon"
    / "Frameworks"
    / "MLKitTextRecognitionCommon.framework"
    / "PrivacyInfo.xcprivacy"
)

MLKIT_COLLECTED_DATA = [
    {
        "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeDeviceID",
        "NSPrivacyCollectedDataTypeLinked": False,
        "NSPrivacyCollectedDataTypeTracking": False,
        "NSPrivacyCollectedDataTypePurposes": [
            "NSPrivacyCollectedDataTypePurposeAnalytics",
            "NSPrivacyCollectedDataTypePurposeAppFunctionality",
        ],
    },
    {
        "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeOtherDataTypes",
        "NSPrivacyCollectedDataTypeLinked": False,
        "NSPrivacyCollectedDataTypeTracking": False,
        "NSPrivacyCollectedDataTypePurposes": [
            "NSPrivacyCollectedDataTypePurposeAnalytics",
            "NSPrivacyCollectedDataTypePurposeAppFunctionality",
        ],
    },
    {
        "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeOtherDiagnosticData",
        "NSPrivacyCollectedDataTypeLinked": False,
        "NSPrivacyCollectedDataTypeTracking": False,
        "NSPrivacyCollectedDataTypePurposes": [
            "NSPrivacyCollectedDataTypePurposeAnalytics",
        ],
    },
    {
        "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeOtherUserContent",
        "NSPrivacyCollectedDataTypeLinked": False,
        "NSPrivacyCollectedDataTypeTracking": False,
        "NSPrivacyCollectedDataTypePurposes": [
            "NSPrivacyCollectedDataTypePurposeAnalytics",
            "NSPrivacyCollectedDataTypePurposeAppFunctionality",
        ],
    },
    {
        "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypePerformanceData",
        "NSPrivacyCollectedDataTypeLinked": False,
        "NSPrivacyCollectedDataTypeTracking": False,
        "NSPrivacyCollectedDataTypePurposes": [
            "NSPrivacyCollectedDataTypePurposeAnalytics",
            "NSPrivacyCollectedDataTypePurposeAppFunctionality",
        ],
    },
    {
        "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeProductInteraction",
        "NSPrivacyCollectedDataTypeLinked": False,
        "NSPrivacyCollectedDataTypeTracking": False,
        "NSPrivacyCollectedDataTypePurposes": [
            "NSPrivacyCollectedDataTypePurposeAnalytics",
            "NSPrivacyCollectedDataTypePurposeAppFunctionality",
        ],
    },
]

EXPECTED_ACCESSED_APIS = [
    {
        "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryDiskSpace",
        "NSPrivacyAccessedAPITypeReasons": ["E174.1"],
    },
    {
        "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp",
        "NSPrivacyAccessedAPITypeReasons": ["3B52.1", "C617.1"],
    },
    {
        "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategorySystemBootTime",
        "NSPrivacyAccessedAPITypeReasons": ["35F9.1"],
    },
    {
        "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
        "NSPrivacyAccessedAPITypeReasons": ["C56D.1", "CA92.1"],
    },
]

EXPECTED_USAGE_DESCRIPTIONS = {
    "en": {
        "NSCameraUsageDescription": "Use the camera to photograph a Go board and recognize the current position or a numbered game diagram on this device.",
        "NSPhotoLibraryUsageDescription": "Select a Go board photo or numbered game diagram for recognition on this device.",
        "NSLocalNetworkUsageDescription": "Connect to the KataGo analysis service on your local network that you configured.",
    },
    "zh-Hans": {
        "NSCameraUsageDescription": "用于拍摄围棋棋盘，并在设备上识别当前局面或编号棋谱图。",
        "NSPhotoLibraryUsageDescription": "用于选择围棋棋盘照片或编号棋谱图，并在设备上进行识别。",
        "NSLocalNetworkUsageDescription": "用于连接您配置的局域网 KataGo 分析服务。",
    },
    "zh-Hant": {
        "NSCameraUsageDescription": "用於拍攝圍棋棋盤，並在裝置上辨識目前局面或編號棋譜圖。",
        "NSPhotoLibraryUsageDescription": "用於選取圍棋棋盤照片或編號棋譜圖，並在裝置上進行辨識。",
        "NSLocalNetworkUsageDescription": "用於連線至您設定的區域網路 KataGo 分析服務。",
    },
    "ja": {
        "NSCameraUsageDescription": "囲碁盤を撮影し、現在の局面または番号付き棋譜図を端末上で認識するために使用します。",
        "NSPhotoLibraryUsageDescription": "囲碁盤の写真または番号付き棋譜図を選び、端末上で認識するために使用します。",
        "NSLocalNetworkUsageDescription": "設定したローカルネットワーク上の KataGo 解析サービスに接続するために使用します。",
    },
    "ko": {
        "NSCameraUsageDescription": "바둑판을 촬영하고 현재 국면 또는 수순이 표시된 기보 이미지를 기기에서 인식하는 데 사용합니다.",
        "NSPhotoLibraryUsageDescription": "바둑판 사진 또는 수순이 표시된 기보 이미지를 선택하여 기기에서 인식하는 데 사용합니다.",
        "NSLocalNetworkUsageDescription": "사용자가 설정한 로컬 네트워크의 KataGo 분석 서비스에 연결하는 데 사용합니다.",
    },
}

_STRINGS_ENTRY = re.compile(r'^\s*"([^"\\]+)"\s*=\s*"([^"\\]*)";\s*$')


def fail(message: str) -> None:
    raise RuntimeError(message)


def read_manifest(path: Path) -> dict:
    try:
        value = plistlib.loads(path.read_bytes())
    except (OSError, plistlib.InvalidFileException) as error:
        fail(f"invalid iOS privacy manifest {path}: {error}")
    if not isinstance(value, dict):
        fail("iOS privacy manifest root must be a dictionary")
    return value


def read_info_plist_strings(path: Path) -> dict[str, str]:
    try:
        payload = path.read_bytes()
    except OSError as error:
        fail(f"cannot read iOS permission localization {path}: {error}")
    try:
        value = plistlib.loads(payload)
    except plistlib.InvalidFileException:
        try:
            text = payload.decode("utf-8-sig")
        except UnicodeDecodeError as error:
            fail(f"iOS permission localization is not UTF-8 or a compiled plist: {path}: {error}")
        value = {}
        for line_number, line in enumerate(text.splitlines(), start=1):
            if not line.strip():
                continue
            match = _STRINGS_ENTRY.fullmatch(line)
            if match is None:
                fail(f"invalid InfoPlist.strings entry {path}:{line_number}")
            key, localized = match.groups()
            if key in value:
                fail(f"duplicate InfoPlist.strings key {key} in {path}")
            value[key] = localized
    if not isinstance(value, dict) or not all(
        isinstance(key, str) and isinstance(localized, str)
        for key, localized in value.items()
    ):
        fail(f"iOS permission localization must be a string dictionary: {path}")
    return value


def verify_usage_localizations() -> None:
    info = read_manifest(INFO_PLIST)
    locales = list(EXPECTED_USAGE_DESCRIPTIONS)
    if info.get("CFBundleLocalizations") != locales:
        fail(f"CFBundleLocalizations must declare exactly: {', '.join(locales)}")
    if {
        key: info.get(key) for key in EXPECTED_USAGE_DESCRIPTIONS["en"]
    } != EXPECTED_USAGE_DESCRIPTIONS["en"]:
        fail("Info.plist fallback permission descriptions must match English")
    forbidden = {
        "NSMicrophoneUsageDescription",
        "NSPhotoLibraryAddUsageDescription",
    }
    unexpected = forbidden.intersection(info)
    if unexpected:
        fail(f"Info.plist declares unused permissions: {sorted(unexpected)}")

    for locale, expected in EXPECTED_USAGE_DESCRIPTIONS.items():
        path = INFO_PLIST.parent / f"{locale}.lproj" / "InfoPlist.strings"
        if read_info_plist_strings(path) != expected:
            fail(f"iOS permission descriptions differ from the reviewed {locale} copy")


def verify_manifest() -> dict:
    value = read_manifest(MANIFEST)
    expected_keys = {
        "NSPrivacyTracking",
        "NSPrivacyTrackingDomains",
        "NSPrivacyCollectedDataTypes",
        "NSPrivacyAccessedAPITypes",
    }
    if set(value) != expected_keys:
        fail(f"unexpected iOS privacy manifest keys: {sorted(set(value) ^ expected_keys)}")
    if value["NSPrivacyTracking"] is not False:
        fail("NSPrivacyTracking must remain false unless the product is re-audited")
    if value["NSPrivacyTrackingDomains"] != []:
        fail("tracking domains must be empty when tracking is false")
    if value["NSPrivacyCollectedDataTypes"] != MLKIT_COLLECTED_DATA:
        fail("collected-data declarations differ from the locked ML Kit aggregate")
    if value["NSPrivacyAccessedAPITypes"] != EXPECTED_ACCESSED_APIS:
        fail("required-reason APIs differ from the locked app + ML Kit aggregate")
    return value


def verify_locked_mlkit() -> None:
    lock = POD_LOCK.read_text("utf-8")
    required = (
        "  - GoogleMLKit/TextRecognition (9.0.0):",
        "  - MLKitCommon (14.0.0):",
        "  - MLKitTextRecognitionCommon (6.0.0):",
        "  - MLKitVision (10.0.0):",
    )
    for line in required:
        if line not in lock:
            fail(f"locked ML Kit privacy source changed: {line.strip()}")
    if (ROOT / "ios" / "Pods").is_dir():
        if not MLKIT_COMMON_MANIFEST.is_file() or not MLKIT_TEXT_MANIFEST.is_file():
            fail("locked ML Kit vendored privacy manifests are missing")
        common = read_manifest(MLKIT_COMMON_MANIFEST)
        recognition = read_manifest(MLKIT_TEXT_MANIFEST)
        for name, manifest in (("MLKitCommon", common), ("MLKitTextRecognitionCommon", recognition)):
            if manifest.get("NSPrivacyCollectedDataTypes") != MLKIT_COLLECTED_DATA:
                fail(f"{name} collected-data manifest differs from the reviewed aggregate")
        if recognition.get("NSPrivacyAccessedAPITypes") != EXPECTED_ACCESSED_APIS:
            fail("MLKitTextRecognitionCommon required-reason APIs changed")


def verify_packaged_app(app: Path, expected: dict) -> None:
    if not app.is_dir():
        fail(f"packaged Runner.app is missing: {app}")
    packaged = app / "PrivacyInfo.xcprivacy"
    if read_manifest(packaged) != expected:
        fail("packaged root PrivacyInfo.xcprivacy differs from the reviewed source")
    manifests = sorted(app.rglob("PrivacyInfo.xcprivacy"))
    if len(manifests) < 2:
        fail("packaged app contains no dependency privacy manifests")
    # ML Kit is statically linked by the locked Pods graph. Its complete
    # declarations therefore live in the Runner aggregate even when the
    # vendored framework manifest is not copied as a standalone resource.
    if read_manifest(packaged)["NSPrivacyCollectedDataTypes"] != MLKIT_COLLECTED_DATA:
        fail("packaged app omits the statically linked ML Kit data aggregate")
    for locale, descriptions in EXPECTED_USAGE_DESCRIPTIONS.items():
        localized = app / f"{locale}.lproj" / "InfoPlist.strings"
        if read_info_plist_strings(localized) != descriptions:
            fail(f"packaged app omits or changes {locale} permission descriptions")


def verify_target_membership() -> None:
    project = PROJECT.read_text("utf-8")
    required_fragments = (
        "PrivacyInfo.xcprivacy */ = {isa = PBXFileReference;",
        "PrivacyInfo.xcprivacy in Resources */ = {isa = PBXBuildFile;",
        "PrivacyInfo.xcprivacy in Resources */,",
    )
    for fragment in required_fragments:
        if fragment not in project:
            fail(f"PrivacyInfo.xcprivacy is not correctly attached to Runner: {fragment}")
    localized_fragments = (
        "InfoPlist.strings in Resources */ = {isa = PBXBuildFile;",
        "InfoPlist.strings in Resources */,",
        *(
            f"path = {locale}.lproj/InfoPlist.strings;"
            if "-" not in locale
            else f'path = "{locale}.lproj/InfoPlist.strings";'
            for locale in EXPECTED_USAGE_DESCRIPTIONS
        ),
    )
    for fragment in localized_fragments:
        if fragment not in project:
            fail(f"InfoPlist.strings is not correctly attached to Runner: {fragment}")
    if re.search(
        r"/\* InfoPlist\.strings \*/ = \{\s*isa = PBXVariantGroup;",
        project,
    ) is None:
        fail("InfoPlist.strings is not a localized Xcode variant group")
    for locale in EXPECTED_USAGE_DESCRIPTIONS:
        region = locale if "-" not in locale else f'"{locale}"'
        if f"\t\t\t\t{region}," not in project:
            fail(f"Runner.xcodeproj knownRegions is missing {locale}")


def verify_documents() -> None:
    privacy = PRIVACY.read_text("utf-8")
    data_safety = DATA_SAFETY.read_text("utf-8")
    required_privacy = (
        "https://developers.google.com/ml-kit/terms",
        "https://developers.google.com/ml-kit/android-data-disclosure",
        "wss://",
        "Keychain",
        "Keystore",
        "安装标记",
        "先删除可能残留的 KataGo Bearer token",
        "此流程只在 iOS 启用，不改变 Android",
    )
    for fragment in required_privacy:
        if fragment not in privacy:
            fail(f"PRIVACY.md is missing a reviewed data-flow disclosure: {fragment}")
    required_android = (
        "com.wimi321.lizzieyzy.mobile",
        "com.google.mlkit:text-recognition",
        "android.permission.CAMERA",
        "android.permission.INTERNET",
        "android.permission.ACCESS_NETWORK_STATE",
    )
    for fragment in required_android:
        if fragment not in data_safety:
            fail(f"Android Data Safety worksheet is missing: {fragment}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path)
    args = parser.parse_args()
    try:
        expected = verify_manifest()
        verify_locked_mlkit()
        verify_usage_localizations()
        verify_target_membership()
        verify_documents()
        if args.app is not None:
            verify_packaged_app(args.app, expected)
    except (OSError, RuntimeError) as error:
        print(f"privacy declaration verification failed: {error}", file=sys.stderr)
        return 1
    print(
        "Privacy aggregate, localized iOS permissions, locked ML Kit boundary, "
        "packaging, and disclosures verified."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
