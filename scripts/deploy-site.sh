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

# Keep sub-sites (such as /mythic-pets) from being deleted by root-site deploy.
# oss sync pattern does not accept '/' directory patterns, so we normalize them.
PRESERVE_PREFIXES="${PRESERVE_PREFIXES:-mythic-pets*}"
ROOT_SYNC_DELETE="${ROOT_SYNC_DELETE:-0}"
SYNC_EXCLUDE_ARGS=()
if [[ -n "${PRESERVE_PREFIXES}" ]]; then
  IFS=',' read -r -a _preserve_list <<< "${PRESERVE_PREFIXES}"
  for _raw in "${_preserve_list[@]}"; do
    _pattern="${_raw//[[:space:]]/}"
    [[ -z "${_pattern}" ]] && continue
    _pattern="${_pattern//\//\*}"
    SYNC_EXCLUDE_ARGS+=(--exclude "${_pattern}")
done
fi

SYNC_DELETE_ARGS=()
if [[ "${ROOT_SYNC_DELETE}" == "1" ]]; then
  SYNC_DELETE_ARGS+=(--delete)
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
if (( ${#SYNC_EXCLUDE_ARGS[@]} > 0 )); then
  echo "Preserve patterns: ${PRESERVE_PREFIXES}"
fi
echo "Delete remote extras: ${ROOT_SYNC_DELETE}"
OSS_SYNC_CMD=(
  aliyun
  --config-path "${ALIYUN_CONFIG_FILE}"
  --profile default
  --mode AK
  --region "${OSS_REGION}"
  oss sync "${STAGE_DIR}/" "oss://${OSS_BUCKET}/"
)
if (( ${#SYNC_EXCLUDE_ARGS[@]} > 0 )); then
  OSS_SYNC_CMD+=("${SYNC_EXCLUDE_ARGS[@]}")
fi
if (( ${#SYNC_DELETE_ARGS[@]} > 0 )); then
  OSS_SYNC_CMD+=("${SYNC_DELETE_ARGS[@]}")
fi
OSS_SYNC_CMD+=(
  --force
  --update
  --output-dir "${OUTPUT_DIR}"
  --checkpoint-dir "${CHECKPOINT_DIR}"
  --endpoint "oss-${OSS_REGION}.aliyuncs.com"
)
"${OSS_SYNC_CMD[@]}"

echo "[2/2] Refresh CDN cache for HTML entry files"
IFS=',' read -r -a DOMAIN_LIST <<< "${CDN_DOMAINS}"
failed_urls=()
for raw in "${DOMAIN_LIST[@]}"; do
  domain="${raw//[[:space:]]/}"
  [[ -z "${domain}" ]] && continue
  for path in "/" "/index.html"; do
    url="https://${domain}${path}"
    refreshed=0
    for attempt in 1 2 3; do
      if aliyun \
        --config-path "${ALIYUN_CONFIG_FILE}" \
        --profile default \
        --mode AK \
        --region "${CDN_API_REGION}" \
        cdn RefreshObjectCaches \
        --ObjectPath "${url}" \
        --ObjectType File >/dev/null; then
        echo "Refreshed ${url}"
        refreshed=1
        break
      fi
      echo "WARN: refresh failed for ${url} (attempt ${attempt}/3), retrying..." >&2
      sleep 2
    done
    if [[ "${refreshed}" -ne 1 ]]; then
      failed_urls+=("${url}")
    fi
  done
done

if (( ${#failed_urls[@]} > 0 )); then
  echo "WARN: deploy finished, but CDN refresh failed for:" >&2
  printf '%s\n' "${failed_urls[@]}" >&2
else
  echo "Deploy finished."
fi
