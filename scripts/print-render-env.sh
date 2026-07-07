#!/usr/bin/env bash
# Print Render env vars from .env.karofi (masked) for Dashboard paste.
# Usage: bash scripts/print-render-env.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV="${ROOT}/.env.karofi"
SITE_URL="${KAROFI_SITE_URL:-https://karofi-demo-sg.onrender.com}"

if [[ ! -f "${ENV}" ]]; then
  echo "Missing ${ENV} — run: bash scripts/generate-karofi-sg-env.sh && cp .env.karofi.sg .env.karofi"
  exit 1
fi

echo "# Paste into Render → karofi-demo-sg → Environment"
echo "# SERVER_URL: set after first deploy if URL differs"
echo ""
for key in DATABASE_URL DIRECT_URL SUPABASE_URL SUPABASE_ANON_PUBLIC SUPABASE_SERVICE_ROLE; do
  val="$(grep "^${key}=" "${ENV}" | tail -1 | sed "s/^${key}=//" | tr -d '"')"
  echo "${key}=${val}"
done
echo "SERVER_URL=${SITE_URL}"
echo "PLATFORM_PROFILE=karofi"
echo "DATABASE_PROVIDER=postgresql"
echo "AUTH_DRIVER=supabase"
echo "STORAGE_DRIVER=supabase"
echo "JOB_QUEUE_DRIVER=pgboss"
echo "APP_NAME=Karofi"
echo "DEFAULT_LOCALE=vi"
echo "DEMO_VI=true"
echo "ENABLE_PREMIUM_FEATURES=false"
echo "DISABLE_SIGNUP=true"
echo "DISABLE_SSO=false"
echo "SEND_ONBOARDING_EMAIL=false"
