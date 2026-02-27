#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${LONGWEI_SITE_ENV:-${HOME}/.config/longwei-site/deploy.env}"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing config: ${ENV_FILE}"
  echo "Run: ./scripts/setup-site-env.sh"
  exit 1
fi

# shellcheck source=/dev/null
source "${ENV_FILE}"

: "${ALIYUN_ACCESS_KEY_ID:?Missing ALIYUN_ACCESS_KEY_ID in ${ENV_FILE}}"
: "${ALIYUN_ACCESS_KEY_SECRET:?Missing ALIYUN_ACCESS_KEY_SECRET in ${ENV_FILE}}"
: "${OSS_BUCKET:?Missing OSS_BUCKET in ${ENV_FILE}}"
: "${OSS_REGION:?Missing OSS_REGION in ${ENV_FILE}}"
: "${CDN_API_REGION:?Missing CDN_API_REGION in ${ENV_FILE}}"
: "${CDN_DOMAINS:?Missing CDN_DOMAINS in ${ENV_FILE}}"

# Avoid exposing credentials via command-line flags (visible in process listings).
ALIYUN_CONFIG_FILE="$(mktemp "${TMPDIR:-/tmp}/longwei-aliyun-config.XXXXXX.json")"
cat >"${ALIYUN_CONFIG_FILE}" <<EOF
{
  "current": "default",
  "profiles": [
    {
      "name": "default",
      "mode": "AK",
      "access_key_id": "${ALIYUN_ACCESS_KEY_ID}",
      "access_key_secret": "${ALIYUN_ACCESS_KEY_SECRET}",
      "region_id": "${OSS_REGION}",
      "output_format": "json",
      "language": "zh",
      "site": "china"
    }
  ],
  "meta_path": ""
}
EOF
chmod 600 "${ALIYUN_CONFIG_FILE}"

SOURCE="${1:-${SOURCE_DIR:-${HOME}/longwei-dev}}"
if [[ ! -d "${SOURCE}" ]]; then
  echo "Source directory does not exist: ${SOURCE}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/security-preflight.sh" --env-file "${ENV_FILE}" --source "${SOURCE}"

CACHE_DIR="${HOME}/.cache/longwei-site"
OUTPUT_DIR="${CACHE_DIR}/ossutil_output"
CHECKPOINT_DIR="${CACHE_DIR}/oss_checkpoint"
mkdir -p "${OUTPUT_DIR}" "${CHECKPOINT_DIR}"

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/longwei-site-stage.XXXXXX")"
cleanup() {
  rm -rf "${STAGE_DIR}"
  rm -f "${ALIYUN_CONFIG_FILE}"
}
trap cleanup EXIT

# Build a strict publish directory with an allowlist.
# This prevents accidental upload of internal docs/automation/scripts.
rsync -a \
  --prune-empty-dirs \
  --include='*/' \
  --include='.well-known/***' \
  --include='*.html' \
  --include='*.htm' \
  --include='*.css' \
  --include='*.js' \
  --include='*.mjs' \
  --include='*.json' \
  --include='*.txt' \
  --include='*.xml' \
  --include='*.webmanifest' \
  --include='*.ico' \
  --include='*.svg' \
  --include='*.png' \
  --include='*.jpg' \
  --include='*.jpeg' \
  --include='*.webp' \
  --include='*.gif' \
  --exclude='*' \
  "${SOURCE}/" "${STAGE_DIR}/"

echo "[1/2] Sync local files to OSS bucket: ${OSS_BUCKET}"
aliyun oss sync "${STAGE_DIR}/" "oss://${OSS_BUCKET}/" \
  --force \
  --delete \
  --update \
  --config-path "${ALIYUN_CONFIG_FILE}" \
  --profile default \
  --output-dir "${OUTPUT_DIR}" \
  --checkpoint-dir "${CHECKPOINT_DIR}" \
  --endpoint "oss-${OSS_REGION}.aliyuncs.com" \
  --mode AK \
  --region "${OSS_REGION}"

echo "[2/2] Refresh CDN cache for HTML entry files"
IFS=',' read -r -a DOMAIN_LIST <<< "${CDN_DOMAINS}"
for raw in "${DOMAIN_LIST[@]}"; do
  domain="${raw//[[:space:]]/}"
  [[ -z "${domain}" ]] && continue
  for path in "/" "/index.html"; do
    url="https://${domain}${path}"
    aliyun cdn RefreshObjectCaches \
      --ObjectPath "${url}" \
      --ObjectType File \
      --config-path "${ALIYUN_CONFIG_FILE}" \
      --profile default \
      --region "${CDN_API_REGION}" \
      --mode AK >/dev/null
    echo "Refreshed ${url}"
  done
done

echo "Deploy finished."
