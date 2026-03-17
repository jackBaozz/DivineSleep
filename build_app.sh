#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
APP_NAME="DivineSleep"
BUILD_DIR="${SCRIPT_DIR}/.build/release-app"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
BINARY_PATH="${SCRIPT_DIR}/.build/release/${APP_NAME}"
INFO_PLIST_PATH="${SCRIPT_DIR}/Info.plist"

swift build -c release --package-path "${SCRIPT_DIR}"

if [[ ! -f "${BINARY_PATH}" ]]; then
  echo "Build failed: missing binary at ${BINARY_PATH}" >&2
  exit 1
fi

if [[ ! -f "${INFO_PLIST_PATH}" ]]; then
  echo "Build failed: missing Info.plist at ${INFO_PLIST_PATH}" >&2
  exit 1
fi

rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"

cp "${BINARY_PATH}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp "${INFO_PLIST_PATH}" "${APP_DIR}/Contents/Info.plist"

codesign --force --deep --sign - "${APP_DIR}"

echo "Built ${APP_DIR}"
