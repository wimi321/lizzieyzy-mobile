#!/bin/sh
set -eu

APK="${1:-build/app/outputs/flutter-apk/app-release.apk}"

if [ ! -f "$APK" ]; then
  echo "APK not found: $APK" >&2
  exit 1
fi
apkanalyzer_path="$(command -v apkanalyzer 2>/dev/null || true)"

if [ -z "$apkanalyzer_path" ]; then
  for sdk_root in \
    "${ANDROID_SDK_ROOT:-}" \
    "${ANDROID_HOME:-}" \
    "$HOME/Android/Sdk" \
    "$HOME/Library/Android/sdk"; do
    [ -n "$sdk_root" ] || continue

    for candidate in \
      "$sdk_root/cmdline-tools/latest/bin/apkanalyzer" \
      "$sdk_root/tools/bin/apkanalyzer"; do
      if [ -x "$candidate" ]; then
        apkanalyzer_path="$candidate"
        break 2
      fi
    done

    candidate="$(find "$sdk_root/cmdline-tools" -type f -path '*/bin/apkanalyzer' 2>/dev/null | sort | tail -n 1)"
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      apkanalyzer_path="$candidate"
      break
    fi
  done
fi

if [ -z "$apkanalyzer_path" ]; then
  echo "apkanalyzer is required for permission verification" >&2
  exit 1
fi

permissions="$("$apkanalyzer_path" manifest permissions "$APK" | sort -u)"
unexpected="$(printf '%s\n' "$permissions" | grep -Ev \
  '^(android\.permission\.(CAMERA|INTERNET|ACCESS_NETWORK_STATE)|com\.wimi321\.lizzieyzy\.mobile\.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION)$' \
  || true)"

if [ -n "$unexpected" ]; then
  echo "Unexpected Android permissions:" >&2
  printf '%s\n' "$unexpected" >&2
  exit 1
fi

for required in android.permission.CAMERA android.permission.INTERNET; do
  if ! printf '%s\n' "$permissions" | grep -Fxq "$required"; then
    echo "Missing required Android permission: $required" >&2
    exit 1
  fi
done

merged_manifest="$("$apkanalyzer_path" manifest print "$APK")"
for feature in android.hardware.camera.any android.hardware.camera; do
  camera_required="$(
    printf '%s\n' "$merged_manifest" | awk -v expected="$feature" '
      $0 ~ "android:name=\"" expected "\"" { camera = 1; next }
      camera && /android:required=/ {
        value = $0
        sub(/^.*android:required="/, "", value)
        sub(/".*$/, "", value)
        print value
        exit
      }
    '
  )"
  if [ "$camera_required" != "false" ]; then
    echo "$feature must remain optional after manifest merge" >&2
    exit 1
  fi
done

echo "Android permission allowlist and optional camera feature verified."
