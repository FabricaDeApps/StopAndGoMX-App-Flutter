#!/usr/bin/env bash

set -euo pipefail

platform=${1:-}
device=${2:-}

if [[ "$platform" != "android" && "$platform" != "ios" ]]; then
  echo "Uso: $0 <android|ios> [device-id]" >&2
  exit 64
fi

project_root=$(cd "$(dirname "$0")/.." && pwd)
store_config="$project_root/branding/academiapuebla/store.json"
review_username=${ACADEMIAPUEBLA_REVIEW_USERNAME:-$(jq -r '.store.review.username // empty' "$store_config")}
review_password=${ACADEMIAPUEBLA_REVIEW_PASSWORD:-$(jq -r '.store.review.password // empty' "$store_config")}

if [[ -z "$review_username" || -z "$review_password" ]]; then
  echo "Faltan las credenciales demo en store.review o en las variables de entorno." >&2
  exit 65
fi

flutter_args=(
  drive
  --driver test_driver/store_screenshots_driver.dart
  --target integration_test/store_screenshots_test.dart
  --flavor academiapuebla
  --dart-define "STORE_SCREENSHOT_PLATFORM=$platform"
  --dart-define "STORE_REVIEW_USERNAME=$review_username"
  --dart-define "STORE_REVIEW_PASSWORD=$review_password"
)

if [[ -n "$device" ]]; then
  flutter_args+=(--device-id "$device")
fi

cd "$project_root"
export STORE_SCREENSHOT_OUTPUT="branding/academiapuebla/store/screenshots"
export STORE_SCREENSHOT_PLATFORM="$platform"
flutter "${flutter_args[@]}"

dart run scripts/store_images.dart \
  --config branding/academiapuebla/store.json

./scripts/flavor_tool.sh stores generate \
  --config branding/academiapuebla/store.json
