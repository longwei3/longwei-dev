#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLESCRIPT_SRC="${PROJECT_DIR}/automation/macos/publish-site.applescript"

DESKTOP_DIR="${HOME}/Desktop"
if command -v xdg-user-dir >/dev/null 2>&1; then
  DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
  DESKTOP_DIR="${DESKTOP_DIR:-$HOME/Desktop}"
fi

APP_PATH="${DESKTOP_DIR}/PublishLongweiSite.app"
LEGACY_APP_PATH="${DESKTOP_DIR}/发布网站.app"

if [[ ! -f "${APPLESCRIPT_SRC}" ]]; then
  echo "AppleScript source not found: ${APPLESCRIPT_SRC}"
  exit 1
fi

mkdir -p "${DESKTOP_DIR}"
rm -rf "${APP_PATH}"
rm -rf "${LEGACY_APP_PATH}"
/usr/bin/osacompile -o "${APP_PATH}" "${APPLESCRIPT_SRC}"

echo "Created app: ${APP_PATH}"
echo "Tip: you can rename it in Finder to any display name (for example: 发布网站.app)."
