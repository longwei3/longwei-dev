#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${LONGWEI_SITE_ENV:-${HOME}/.config/longwei-site/deploy.env}"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing config: ${ENV_FILE}"
  exit 1
fi

# shellcheck source=/dev/null
source "${ENV_FILE}"

: "${ALIYUN_ACCESS_KEY_ID:?Missing ALIYUN_ACCESS_KEY_ID in ${ENV_FILE}}"
: "${ALIYUN_ACCESS_KEY_SECRET:?Missing ALIYUN_ACCESS_KEY_SECRET in ${ENV_FILE}}"
: "${CDN_API_REGION:?Missing CDN_API_REGION in ${ENV_FILE}}"
: "${CDN_DOMAINS:?Missing CDN_DOMAINS in ${ENV_FILE}}"

FULLCHAIN="${1:-${CERT_FULLCHAIN:-${HOME}/.acme.sh/longwei.org.cn_ecc/fullchain.cer}}"
KEYFILE="${2:-${CERT_KEY:-${HOME}/.acme.sh/longwei.org.cn_ecc/longwei.org.cn.key}}"

if [[ ! -f "${FULLCHAIN}" ]]; then
  echo "Full chain cert not found: ${FULLCHAIN}"
  exit 1
fi
if [[ ! -f "${KEYFILE}" ]]; then
  echo "Private key not found: ${KEYFILE}"
  exit 1
fi

PUB_CONTENT="$(cat "${FULLCHAIN}")"
KEY_CONTENT="$(cat "${KEYFILE}")"
TS="$(date +%Y%m%d%H%M%S)"

IFS=',' read -r -a DOMAIN_LIST <<< "${CDN_DOMAINS}"
for raw in "${DOMAIN_LIST[@]}"; do
  domain="${raw//[[:space:]]/}"
  [[ -z "${domain}" ]] && continue
  cert_name="le-${domain//./-}-${TS}"
  aliyun cdn SetCdnDomainSSLCertificate \
    --DomainName "${domain}" \
    --SSLProtocol on \
    --CertType upload \
    --SSLPub "${PUB_CONTENT}" \
    --SSLPri "${KEY_CONTENT}" \
    --CertName "${cert_name}" \
    --region "${CDN_API_REGION}" \
    --mode AK \
    --access-key-id "${ALIYUN_ACCESS_KEY_ID}" \
    --access-key-secret "${ALIYUN_ACCESS_KEY_SECRET}" >/dev/null
  echo "Pushed certificate to ${domain}"
done

echo "Certificate sync finished."
