#!/usr/bin/env bash
# Build .env.karofi.sg from KAROFI_SG_* in root .env (or env vars).
#
#   # Điền trong .env:
#   KAROFI_SG_DB_PASSWORD=...
#   KAROFI_SG_SERVICE_ROLE=sb_secret_...
#   pnpm webapp:generate:karofi-sg-env

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/.env.karofi.sg"
ENV_FILE="${ENV_FILE:-${ROOT}/.env}"

read_env_value() {
  local key="$1"
  local from_file=""
  if [[ -f "${ENV_FILE}" ]]; then
    from_file="$(
      grep -E "^${key}=" "${ENV_FILE}" 2>/dev/null | tail -1 | sed -E "s/^${key}=//" | tr -d '"' | tr -d "'" || true
    )"
  fi
  if [[ -n "${from_file}" ]]; then
    printf '%s' "${from_file}"
    return
  fi
  # shellcheck disable=SC2154
  printf '%s' "${!key:-}"
}

REF="$(read_env_value KAROFI_SG_PROJECT_REF)"
REF="${REF:-frgqshzrhpatolttqqdx}"
SUPABASE_DB_PASSWORD="$(read_env_value KAROFI_SG_DB_PASSWORD)"
SUPABASE_SERVICE_ROLE="$(read_env_value KAROFI_SG_SERVICE_ROLE)"

if [[ -z "${SUPABASE_DB_PASSWORD}" ]]; then
  echo "Thiếu KAROFI_SG_DB_PASSWORD trong ${ENV_FILE}"
  echo "Dashboard → Settings → Database → Reset database password"
  exit 1
fi
if [[ -z "${SUPABASE_SERVICE_ROLE}" ]]; then
  echo "Thiếu KAROFI_SG_SERVICE_ROLE — dùng placeholder (migrate DB vẫn chạy; seed auth cần key thật sau)."
  SUPABASE_SERVICE_ROLE="placeholder-run-pnpm-webapp-seed-karofi-admin-after-fixing-service-role"
fi

SESSION_SECRET="$(openssl rand -hex 32)"
FINGERPRINT="$(openssl rand -hex 32)"
INVITE_TOKEN_SECRET="$(openssl rand -hex 32)"

ENC_PASS="$(node -e "console.log(encodeURIComponent(process.argv[1]))" "${SUPABASE_DB_PASSWORD}")"

cat > "${OUT}" <<EOF
# Karofi — Supabase Singapore (generated $(date -u +%Y-%m-%dT%H:%MZ))
# Project: ${REF} (ap-southeast-1)

DATABASE_URL="postgres://postgres.${REF}:${ENC_PASS}@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true"
DIRECT_URL="postgres://postgres.${REF}:${ENC_PASS}@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres"

SESSION_SECRET="${SESSION_SECRET}"
SUPABASE_ANON_PUBLIC="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyZ3FzaHpyaHBhdG9sdHRxcWR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzNDI5OTgsImV4cCI6MjA5ODkxODk5OH0.pExIzcvBBESoDemeVTgljMu66MyC6afAKF1Dj37U5Ak"
SUPABASE_SERVICE_ROLE="${SUPABASE_SERVICE_ROLE}"
SUPABASE_URL="https://${REF}.supabase.co"
SERVER_URL="http://localhost:3000"

DATABASE_PROVIDER="postgresql"
PLATFORM_PROFILE="karofi"
AUTH_DRIVER="supabase"
STORAGE_DRIVER="supabase"
JOB_QUEUE_DRIVER="pgboss"

APP_NAME="Karofi"
DEFAULT_LOCALE="vi"
DEMO_VI="true"
COOKIE_DOMAIN=""
DISABLE_HTTPS="true"

ENABLE_PREMIUM_FEATURES="false"
DISABLE_SIGNUP="true"
DISABLE_SSO="true"
SEND_ONBOARDING_EMAIL="false"

FINGERPRINT="${FINGERPRINT}"
INVITE_TOKEN_SECRET="${INVITE_TOKEN_SECRET}"

STRIPE_SECRET_KEY="stripe-secret-key"
STRIPE_PUBLIC_KEY="stripe-public-key"
STRIPE_WEBHOOK_ENDPOINT_SECRET="stripe-endpoint-secret"
FREE_TRIAL_DAYS="14"

SMTP_PWD="super-safe-passw0rd"
SMTP_HOST="mail.example.com"
SMTP_PORT=465
SMTP_USER="some-email@example.com"
SMTP_FROM="Karofi <noreply@example.com>"

MAPTILER_TOKEN="maptiler-token"
GEOCODING_USER_AGENT="Karofi Asset Management"
SENTRY_DSN=""

ADMIN_EMAIL="admin@dqa-karofi.io.vn"
DEMO_ADMIN_EMAIL="admin@dqa-karofi.io.vn"
DEMO_ADMIN_PASSWORD="KarofiAdmin123!"
SUPPORT_EMAIL="support@karofi.local"
FULL_CALENDAR_LICENSE_KEY="full-calendar-license-key"
EOF

echo "Wrote ${OUT}"
