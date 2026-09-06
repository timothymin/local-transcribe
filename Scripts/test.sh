#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
CACHE_DIR="${PROJECT_ROOT}/.cache"

mkdir -p "${CACHE_DIR}/clang" "${CACHE_DIR}/swiftpm" "${CACHE_DIR}/swiftpm-module"
export CLANG_MODULE_CACHE_PATH="${CACHE_DIR}/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="${CACHE_DIR}/swiftpm-module"

cd "${PROJECT_ROOT}"
swift test \
  --disable-sandbox \
  --cache-path "${CACHE_DIR}/swiftpm" \
  --scratch-path "${PROJECT_ROOT}/.build"

plutil -lint "${PROJECT_ROOT}/MeetingNote/Info.plist"
zsh -n "${PROJECT_ROOT}/Scripts/build-release.sh" "${PROJECT_ROOT}/Scripts/install.sh"

BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${PROJECT_ROOT}/MeetingNote/Info.plist")"
if [[ "${BUILD_NUMBER}" != <-> ]] || (( BUILD_NUMBER <= 1 )); then
  print -u2 "CFBundleVersion must be an increasing numeric build number, not ${BUILD_NUMBER}."
  exit 1
fi

if /usr/libexec/PlistBuddy -c 'Print :LSUIElement' "${PROJECT_ROOT}/MeetingNote/Info.plist" >/dev/null 2>&1; then
  print -u2 "LSUIElement must stay out of Info.plist so macOS can discover the app."
  exit 1
fi
