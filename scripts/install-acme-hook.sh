#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-longwei.org.cn}"
ACME_HOME="${ACME_HOME:-${HOME}/.acme.sh}"
ACME="${ACME_HOME}/acme.sh"
HOOK_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/push-cert-to-cdn.sh"
KEY_PATH="${HOME}/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.key"
FULLCHAIN_PATH="${HOME}/.acme.sh/${DOMAIN}_ecc/fullchain.cer"

if [[ ! -x "${ACME}" ]]; then
  echo "acme.sh not found: ${ACME}"
  exit 1
fi

"${ACME}" --install-cert -d "${DOMAIN}" --ecc \
  --key-file "${KEY_PATH}" \
  --fullchain-file "${FULLCHAIN_PATH}" \
  --reloadcmd "${HOOK_SCRIPT}"

echo "Installed acme renew hook: ${HOOK_SCRIPT}"
