#!/bin/sh
set -eu

APK="${1:-build/app/outputs/flutter-apk/app-debug.apk}"

if [ ! -f "$APK" ]; then
  echo "APK not found: $APK" >&2
  exit 1
fi
if ! command -v apkanalyzer >/dev/null 2>&1; then
  echo "apkanalyzer is required for permission verification" >&2
  exit 1
fi

permissions="$(apkanalyzer manifest permissions "$APK" | sort -u)"
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

echo "Android permission allowlist verified."
