#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  security-preflight.sh [--env-file FILE] [--source DIR] [--cert-key FILE]

Checks:
  1) Sensitive local config permissions (deploy.env / key file)
  2) Source tree for forbidden secret file types (when --source is given)
  3) Source tree for common secret patterns (when --source is given)
  4) target="_blank" links include rel=... (when index.html exists)
EOF
}

ENV_FILE="${LONGWEI_SITE_ENV:-${HOME}/.config/longwei-site/deploy.env}"
SOURCE_DIR=""
CERT_KEY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      ENV_FILE="${2:-}"
      shift 2
      ;;
    --source)
      SOURCE_DIR="${2:-}"
      shift 2
      ;;
    --cert-key)
      CERT_KEY_FILE="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

get_perm() {
  local file="$1"
  if stat -f "%Mp%Lp" "$file" >/dev/null 2>&1; then
    stat -f "%Mp%Lp" "$file"
  elif stat -c "%a" "$file" >/dev/null 2>&1; then
    stat -c "%a" "$file"
  else
    echo "unknown"
  fi
}

assert_perm_600() {
  local file="$1"
  local perm
  perm="$(get_perm "$file")"
  if [[ "$perm" != "0600" && "$perm" != "600" ]]; then
    echo "[FAIL] Insecure permission on ${file}: ${perm} (expected 600)"
    exit 1
  fi
}

echo "[security] Running preflight checks..."

if [[ -f "$ENV_FILE" ]]; then
  assert_perm_600 "$ENV_FILE"
  echo "[security] OK deploy.env permission is 600: ${ENV_FILE}"
else
  echo "[FAIL] Missing env file: ${ENV_FILE}"
  exit 1
fi

if [[ -n "$CERT_KEY_FILE" ]]; then
  if [[ ! -f "$CERT_KEY_FILE" ]]; then
    echo "[FAIL] Missing cert key file: ${CERT_KEY_FILE}"
    exit 1
  fi
  assert_perm_600 "$CERT_KEY_FILE"
  echo "[security] OK cert key permission is 600: ${CERT_KEY_FILE}"
fi

if [[ -n "$SOURCE_DIR" ]]; then
  if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "[FAIL] Source directory does not exist: ${SOURCE_DIR}"
    exit 1
  fi

  FORBIDDEN_FILES="$(find "$SOURCE_DIR" -type f \( \
    -name '.env' -o -name '.env.*' -o \
    -name '*.pem' -o -name '*.key' -o -name '*.p12' -o -name '*.pfx' -o \
    -name 'id_rsa' -o -name 'id_rsa.pub' \
  \) \
  -not -path '*/.git/*' \
  -not -path '*/scripts/*' \
  -not -path '*/docs/*' || true)"

  if [[ -n "${FORBIDDEN_FILES}" ]]; then
    echo "[FAIL] Forbidden secret-like files found in source tree:"
    echo "${FORBIDDEN_FILES}"
    exit 1
  fi
  echo "[security] OK no forbidden secret files in source tree."

  SECRET_PATTERN='BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|ALIYUN_ACCESS_KEY_SECRET[[:space:]]*=[[:space:]]*[^[:space:]#$]|OPENAI_API_KEY[[:space:]]*=[[:space:]]*[^[:space:]#$]'
  SECRET_HITS="$(rg -n --hidden -S -g '!.git/**' -g '!scripts/**' -g '!docs/**' "${SECRET_PATTERN}" "$SOURCE_DIR" || true)"
  if [[ -n "${SECRET_HITS}" ]]; then
    echo "[FAIL] Potential secrets found in source tree:"
    echo "${SECRET_HITS}"
    exit 1
  fi
  echo "[security] OK no obvious secret pattern in source tree."

  if [[ -f "${SOURCE_DIR}/index.html" ]]; then
    BAD_LINKS="$(rg -n --pcre2 'target="_blank"(?![^>]*rel=)' "${SOURCE_DIR}/index.html" || true)"
    if [[ -n "${BAD_LINKS}" ]]; then
      echo "[FAIL] target=\"_blank\" without rel attribute detected:"
      echo "${BAD_LINKS}"
      exit 1
    fi
    echo "[security] OK target=\"_blank\" links include rel=..."
  fi
fi

echo "[security] Preflight checks passed."
