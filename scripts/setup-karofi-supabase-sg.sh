#!/usr/bin/env bash
# Setup Karofi on Supabase Singapore + optional data copy from Seoul.
#
# Prerequisites:
#   .env.karofi.sg  — bash scripts/generate-karofi-sg-env.sh
#   .env.seoul      — copy from current Seoul .env.demo (migration source)
#
#   COPY_FROM_SEOUL=1 pnpm webapp:setup:karofi:sg

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

SG_ENV="${SG_ENV:-${ROOT}/.env.karofi.sg}"
SEOUL_ENV="${SEOUL_ENV:-${ROOT}/.env.seoul}"
KAROFI_ENV="${ROOT}/.env.karofi"

# Auto-copy Seoul data when source file exists (override with COPY_FROM_SEOUL=0)
if [[ -z "${COPY_FROM_SEOUL:-}" ]] && [[ -f "${SEOUL_ENV}" || -f "${ROOT}/.env.demo" ]]; then
  COPY_FROM_SEOUL=1
fi

if [[ ! -f "${SG_ENV}" ]]; then
  echo "Missing ${SG_ENV} — generating from .env KAROFI_SG_* ..."
  bash "${ROOT}/scripts/generate-karofi-sg-env.sh"
fi

if [[ ! -f "${SG_ENV}" ]]; then
  echo "Missing ${SG_ENV}"
  echo "Run: export SUPABASE_DB_PASSWORD=... SUPABASE_SERVICE_ROLE=..."
  echo "     bash scripts/generate-karofi-sg-env.sh"
  exit 1
fi

echo "==> 1/4 Prisma migrate deploy (schema → Singapore)"
pnpm --filter @shelf/database exec dotenv -e "${SG_ENV}" -- \
  prisma migrate deploy --config prisma.config.postgres.ts

echo "==> 2/4 Prisma generate (postgres client)"
pnpm --filter @shelf/database exec dotenv -e "${SG_ENV}" -- \
  prisma generate --config prisma.config.postgres.ts

if [[ "${COPY_FROM_SEOUL:-0}" == "1" ]]; then
  if [[ ! -f "${SEOUL_ENV}" ]]; then
    if [[ -f "${ROOT}/.env.demo" ]]; then
      echo "Using ${ROOT}/.env.demo as Seoul source (consider copying to .env.seoul)"
      SEOUL_ENV="${ROOT}/.env.demo"
    else
      echo "COPY_FROM_SEOUL=1 but missing ${SEOUL_ENV}"
      exit 1
    fi
  fi
  echo "==> 3/4 Copy data Seoul → Singapore"
  SOURCE_DATABASE_URL="$(
    grep '^DIRECT_URL=' "${SEOUL_ENV}" | sed -E 's/^DIRECT_URL=//' | tr -d '"'
  )"
  TARGET_DATABASE_URL="$(
    grep '^DIRECT_URL=' "${SG_ENV}" | sed -E 's/^DIRECT_URL=//' | tr -d '"'
  )"
  export SOURCE_DATABASE_URL TARGET_DATABASE_URL
  pnpm --filter @shelf/webapp exec tsx scripts/migrate-supabase-postgres-to-postgres.ts
else
  echo "==> 3/4 Skip data copy (set COPY_FROM_SEOUL=1 to copy from .env.seoul)"
fi

echo "==> 4/4 Activate Karofi env for local dev"
cp "${SG_ENV}" "${KAROFI_ENV}"
cp "${SG_ENV}" "${ROOT}/.env"
echo "Updated .env.karofi and .env from ${SG_ENV}"

echo ""
echo "Done. Next:"
echo "  • Supabase SG → Auth → URL config: Site URL = your deploy URL"
echo "  • Auth users: re-run seed if needed: pnpm webapp:seed:karofi-admin"
echo "  • Local:      pnpm webapp:dev"
echo "  • Deploy:     render.yaml (region Singapore)"
