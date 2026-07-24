#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Uso: ./scripts/generate_flavor_icons.sh <flavor> <ios_appicon_name>"
  echo "Ejemplo: ./scripts/generate_flavor_icons.sh cimarronesqro AppIconCimarronesqro"
  exit 1
fi

FLAVOR="$1"
IOS_APPICON_NAME="$2"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT_DIR/branding/$FLAVOR/logo.png"
ANDROID_DIR="$ROOT_DIR/android/app/src/$FLAVOR/res"
IOS_DIR="$ROOT_DIR/ios/Runner/Assets.xcassets/${IOS_APPICON_NAME}.appiconset"

if [ ! -f "$SRC" ]; then
  echo "No existe el logo fuente: $SRC"
  exit 1
fi

mkdir -p \
  "$ANDROID_DIR/mipmap-mdpi" \
  "$ANDROID_DIR/mipmap-hdpi" \
  "$ANDROID_DIR/mipmap-xhdpi" \
  "$ANDROID_DIR/mipmap-xxhdpi" \
  "$ANDROID_DIR/mipmap-xxxhdpi" \
  "$ANDROID_DIR/mipmap-anydpi-v26" \
  "$ANDROID_DIR/drawable" \
  "$IOS_DIR"

cat > "$ANDROID_DIR/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF

cat > "$ANDROID_DIR/mipmap-anydpi-v26/ic_launcher_round.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF

cat > "$ANDROID_DIR/drawable/ic_launcher_background.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#FFFFFF"/>
</shape>
EOF

# Android launcher sizes
sips -z 48 48   "$SRC" --out "$ANDROID_DIR/mipmap-mdpi/ic_launcher.png" >/dev/null
sips -z 72 72   "$SRC" --out "$ANDROID_DIR/mipmap-hdpi/ic_launcher.png" >/dev/null
sips -z 96 96   "$SRC" --out "$ANDROID_DIR/mipmap-xhdpi/ic_launcher.png" >/dev/null
sips -z 144 144 "$SRC" --out "$ANDROID_DIR/mipmap-xxhdpi/ic_launcher.png" >/dev/null
sips -z 192 192 "$SRC" --out "$ANDROID_DIR/mipmap-xxxhdpi/ic_launcher.png" >/dev/null

cp "$ANDROID_DIR/mipmap-mdpi/ic_launcher.png" "$ANDROID_DIR/mipmap-mdpi/ic_launcher_round.png"
cp "$ANDROID_DIR/mipmap-hdpi/ic_launcher.png" "$ANDROID_DIR/mipmap-hdpi/ic_launcher_round.png"
cp "$ANDROID_DIR/mipmap-xhdpi/ic_launcher.png" "$ANDROID_DIR/mipmap-xhdpi/ic_launcher_round.png"
cp "$ANDROID_DIR/mipmap-xxhdpi/ic_launcher.png" "$ANDROID_DIR/mipmap-xxhdpi/ic_launcher_round.png"
cp "$ANDROID_DIR/mipmap-xxxhdpi/ic_launcher.png" "$ANDROID_DIR/mipmap-xxxhdpi/ic_launcher_round.png"

sips -z 108 108 "$SRC" --out "$ANDROID_DIR/mipmap-mdpi/ic_launcher_foreground.png" >/dev/null
sips -z 162 162 "$SRC" --out "$ANDROID_DIR/mipmap-hdpi/ic_launcher_foreground.png" >/dev/null
sips -z 216 216 "$SRC" --out "$ANDROID_DIR/mipmap-xhdpi/ic_launcher_foreground.png" >/dev/null
sips -z 324 324 "$SRC" --out "$ANDROID_DIR/mipmap-xxhdpi/ic_launcher_foreground.png" >/dev/null
sips -z 432 432 "$SRC" --out "$ANDROID_DIR/mipmap-xxxhdpi/ic_launcher_foreground.png" >/dev/null

# iOS / macOS / watchOS sizes based on current asset catalog pattern
while IFS=: read -r name size; do
  sips -z "$size" "$size" "$SRC" --out "$IOS_DIR/$name" >/dev/null
done <<'EOF'
icon-ios-20x20@2x.png:40
icon-ios-20x20@3x.png:60
icon-ios-29x29@2x.png:58
icon-ios-29x29@3x.png:87
icon-ios-38x38@2x.png:76
icon-ios-38x38@3x.png:114
icon-ios-40x40@2x.png:80
icon-ios-40x40@3x.png:120
icon-ios-60x60@2x.png:120
icon-ios-60x60@3x.png:180
icon-ios-64x64@2x.png:128
icon-ios-64x64@3x.png:192
icon-ios-68x68@2x.png:136
icon-ios-76x76@2x.png:152
icon-ios-83.5x83.5@2x.png:167
icon-ios-1024x1024.png:1024
icon-mac-16x16.png:16
icon-mac-16x16@2x.png:32
icon-mac-32x32.png:32
icon-mac-32x32@2x.png:64
icon-mac-128x128.png:128
icon-mac-128x128@2x.png:256
icon-mac-256x256.png:256
icon-mac-256x256@2x.png:512
icon-mac-512x512.png:512
icon-mac-512x512@2x.png:1024
icon-watchos-22x22@2x.png:44
icon-watchos-24x24@2x.png:48
icon-watchos-27.5x27.5@2x.png:55
icon-watchos-29x29@2x.png:58
icon-watchos-30x30@2x.png:60
icon-watchos-32x32@2x.png:64
icon-watchos-33x33@2x.png:66
icon-watchos-40x40@2x.png:80
icon-watchos-43.5x43.5@2x.png:87
icon-watchos-44x44@2x.png:88
icon-watchos-46x46@2x.png:92
icon-watchos-50x50@2x.png:100
icon-watchos-51x51@2x.png:102
icon-watchos-54x54@2x.png:108
icon-watchos-86x86@2x.png:172
icon-watchos-98x98@2x.png:196
icon-watchos-108x108@2x.png:216
icon-watchos-117x117@2x.png:234
icon-watchos-129x129@2x.png:258
icon-watchos-1024x1024.png:1024
EOF

# Apple no acepta alpha en el icono grande de App Store.
TMP_JPG="/tmp/${FLAVOR}_appstore_1024.jpg"
sips -z 1024 1024 -s format jpeg "$SRC" --out "$TMP_JPG" >/dev/null
sips -s format png "$TMP_JPG" --out "$IOS_DIR/icon-ios-1024x1024.png" >/dev/null

echo "Iconos generados para $FLAVOR"
echo "Android: $ANDROID_DIR"
echo "iOS: $IOS_DIR"
