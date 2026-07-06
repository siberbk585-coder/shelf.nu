#!/usr/bin/env bash
# Karofi Singapore — Render Blueprint deploy checklist.
#
# Prerequisites:
#   • Code pushed to fork: git push -u fork dqa-fork
#   • .env.karofi filled (bash scripts/generate-karofi-sg-env.sh)
#   • Supabase Auth URLs (bash scripts/configure-karofi-supabase-auth.sh)
#
# Usage: bash scripts/deploy-karofi-render.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

FORK_REPO="${KAROFI_FORK_REPO:-siberbk585-coder/shelf.nu}"
BRANCH="${KAROFI_DEPLOY_BRANCH:-dqa-fork}"
SERVICE_NAME="${KAROFI_RENDER_SERVICE:-karofi-demo-sg}"
SITE_URL="${KAROFI_SITE_URL:-https://karofi-demo-sg.onrender.com}"

echo "==> Karofi Render deploy (${SERVICE_NAME}, Singapore)"
echo ""
echo "1. Push branch to fork"
echo "   git remote add fork https://github.com/${FORK_REPO}.git  # once"
echo "   git push -u fork ${BRANCH}"
echo ""
echo "2. Render Dashboard → New → Blueprint"
echo "   https://dashboard.render.com/blueprints"
echo "   Connect GitHub → ${FORK_REPO} → branch ${BRANCH} → Apply render.yaml"
echo ""
echo "3. Paste secrets (from .env.karofi after generate-karofi-sg-env.sh):"
echo "   See: scripts/render-karofi-env.example"
echo ""
if [[ -f "${ROOT}/.env.karofi" ]]; then
  echo "   Keys present in .env.karofi:"
  for key in DATABASE_URL DIRECT_URL SUPABASE_URL SUPABASE_ANON_PUBLIC SUPABASE_SERVICE_ROLE; do
    if grep -q "^${key}=" "${ROOT}/.env.karofi" 2>/dev/null; then
      val="$(grep "^${key}=" "${ROOT}/.env.karofi" | tail -1 | cut -d= -f2- | tr -d '"')"
      if [[ "${key}" == *"SERVICE_ROLE"* ]] || [[ "${key}" == *"PASSWORD"* ]] || [[ "${key}" == *"URL"* ]]; then
        echo "   • ${key}=***"
      else
        echo "   • ${key}=${val}"
      fi
    fi
  done
  echo "   • SERVER_URL=${SITE_URL}"
else
  echo "   (Run: bash scripts/generate-karofi-sg-env.sh && cp .env.karofi.sg .env.karofi)"
fi
echo ""
echo "4. After first deploy — set SERVER_URL on Render to the actual URL, then:"
echo "   curl -s ${SITE_URL}/healthcheck"
echo ""
echo "5. Supabase Auth → Site URL = ${SITE_URL}"
echo "   bash scripts/configure-karofi-supabase-auth.sh"
echo ""

# Optional: patch render.yaml branch to fork if different upstream
if grep -q 'branch: dqa-fork' "${ROOT}/render.yaml" 2>/dev/null; then
  echo "render.yaml branch: dqa-fork ✓"
fi

if command -v gh >/dev/null 2>&1; then
  if gh repo view "${FORK_REPO}" >/dev/null 2>&1; then
    echo "Fork repo ${FORK_REPO} exists ✓"
  fi
fi
