#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE="$ROOT/design/brand/v1/app-icon-source.png"
IOS="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID="$ROOT/android/app/src/main/res"

if [ ! -f "$SOURCE" ]; then
  echo "Missing icon source: $SOURCE" >&2
  exit 1
fi

resize() {
  size="$1"
  output="$2"
  sips -s format png -z "$size" "$size" "$SOURCE" --out "$output" >/dev/null
}

resize 40 "$IOS/Icon-App-20x20@2x.png"
resize 60 "$IOS/Icon-App-20x20@3x.png"
resize 29 "$IOS/Icon-App-29x29@1x.png"
resize 58 "$IOS/Icon-App-29x29@2x.png"
resize 87 "$IOS/Icon-App-29x29@3x.png"
resize 80 "$IOS/Icon-App-40x40@2x.png"
resize 120 "$IOS/Icon-App-40x40@3x.png"
resize 120 "$IOS/Icon-App-60x60@2x.png"
resize 180 "$IOS/Icon-App-60x60@3x.png"
resize 20 "$IOS/Icon-App-20x20@1x.png"
resize 40 "$IOS/Icon-App-20x20@2x.png"
resize 40 "$IOS/Icon-App-40x40@1x.png"
resize 76 "$IOS/Icon-App-76x76@1x.png"
resize 152 "$IOS/Icon-App-76x76@2x.png"
resize 167 "$IOS/Icon-App-83.5x83.5@2x.png"
resize 1024 "$IOS/Icon-App-1024x1024@1x.png"

resize 48 "$ANDROID/mipmap-mdpi/ic_launcher.png"
resize 72 "$ANDROID/mipmap-hdpi/ic_launcher.png"
resize 96 "$ANDROID/mipmap-xhdpi/ic_launcher.png"
resize 144 "$ANDROID/mipmap-xxhdpi/ic_launcher.png"
resize 192 "$ANDROID/mipmap-xxxhdpi/ic_launcher.png"

echo "Generated iOS and Android launcher icons from $SOURCE"
