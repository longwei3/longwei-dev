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

SOURCE="${1:-${SOURCE_DIR:-${HOME}/longwei-dev}}"
if [[ ! -d "${SOURCE}" ]]; then
  echo "Source directory does not exist: ${SOURCE}"
  exit 1
fi

CACHE_DIR="${HOME}/.cache/longwei-site"
OUTPUT_DIR="${CACHE_DIR}/ossutil_output"
CHECKPOINT_DIR="${CACHE_DIR}/oss_checkpoint"
mkdir -p "${OUTPUT_DIR}" "${CHECKPOINT_DIR}"

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/longwei-site-stage.XXXXXX")"
cleanup() {
  rm -rf "${STAGE_DIR}"
}
trap cleanup EXIT

# Build a clean publish directory to avoid uploading repo internals.
find "${SOURCE}" -mindepth 1 -maxdepth 1 \
  ! -name ".git" \
  ! -name "scripts" \
  ! -name "README.md" \
  ! -name ".DS_Store" \
  -exec cp -R "{}" "${STAGE_DIR}/" \;

echo "[1/2] Sync local files to OSS bucket: ${OSS_BUCKET}"
aliyun oss sync "${STAGE_DIR}/" "oss://${OSS_BUCKET}/" \
  --force \
  --delete \
  --update \
  --output-dir "${OUTPUT_DIR}" \
  --checkpoint-dir "${CHECKPOINT_DIR}" \
  --endpoint "oss-${OSS_REGION}.aliyuncs.com" \
  --mode AK \
  --access-key-id "${ALIYUN_ACCESS_KEY_ID}" \
  --access-key-secret "${ALIYUN_ACCESS_KEY_SECRET}" \
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
      --region "${CDN_API_REGION}" \
      --mode AK \
      --access-key-id "${ALIYUN_ACCESS_KEY_ID}" \
      --access-key-secret "${ALIYUN_ACCESS_KEY_SECRET}" >/dev/null
    echo "Refreshed ${url}"
  done
done

echo "Deploy finished."
