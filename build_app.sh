#!/bin/zsh
set -euo pipefail

APP_NAME="DivineSleep"
BUILD_DIR=".build/release-app"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"

swift build -c release

rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"

cp ".build/release/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp "Info.plist" "${APP_DIR}/Contents/Info.plist"

echo "Built ${APP_DIR}"
