#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
APP_NAME="DivineSleep"
APP_DIR="${SCRIPT_DIR}/.build/release-app/${APP_NAME}.app"
INFO_PLIST_PATH="${SCRIPT_DIR}/Info.plist"
ARCH="$(uname -m)"

if [[ ! -f "${INFO_PLIST_PATH}" ]]; then
  echo "Build failed: missing Info.plist at ${INFO_PLIST_PATH}" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST_PATH}")"

if [[ -z "${VERSION}" ]]; then
  echo "Build failed: CFBundleShortVersionString is empty in ${INFO_PLIST_PATH}" >&2
  exit 1
fi

"${SCRIPT_DIR}/build_app.sh"

if [[ ! -d "${APP_DIR}" ]]; then
  echo "Build failed: missing app bundle at ${APP_DIR}" >&2
  exit 1
fi

DMG_NAME="${APP_NAME}-${VERSION}-macos-${ARCH}.dmg"
DMG_PATH="${SCRIPT_DIR}/${DMG_NAME}"
VOLUME_NAME="${APP_NAME} ${VERSION}"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/${APP_NAME}.dmg.XXXXXX")"

cleanup() {
  rm -rf "${STAGING_DIR}"
}

trap cleanup EXIT

rm -f "${DMG_PATH}"

ditto "${APP_DIR}" "${STAGING_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"

hdiutil create \
  -volname "${VOLUME_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -format UDZO \
  -ov \
  "${DMG_PATH}"

echo "Built ${DMG_PATH}"
