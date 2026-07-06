#!/usr/bin/env bash
# Configure Supabase Auth Site URL + Redirect URLs for Karofi Singapore.
#
# Option A — Dashboard (no token):
#   https://supabase.com/dashboard/project/frgqshzrhpatolttqqdx/auth/url-configuration
#   Site URL:     https://karofi-demo-sg.onrender.com
#   Redirect URLs: https://karofi-demo-sg.onrender.com/**, http://localhost:3000/**
#
# Option B — Management API (requires personal access token):
#   export SUPABASE_ACCESS_TOKEN=sbp_...   # Dashboard → Account → Access Tokens
#   bash scripts/configure-karofi-supabase-auth.sh
#
# Optional overrides:
#   KAROFI_SITE_URL=https://your-app.onrender.com
#   KAROFI_REDIRECT_URLS="https://your-app.onrender.com/**,http://localhost:3000/**"

set -euo pipefail

PROJECT_REF="${KAROFI_SG_PROJECT_REF:-frgqshzrhpatolttqqdx}"
SITE_URL="${KAROFI_SITE_URL:-https://karofi-demo-sg.onrender.com}"
REDIRECT_URLS="${KAROFI_REDIRECT_URLS:-${SITE_URL}/**,http://localhost:3000/**}"

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "SUPABASE_ACCESS_TOKEN not set — configure manually:"
  echo "  https://supabase.com/dashboard/project/${PROJECT_REF}/auth/url-configuration"
  echo ""
  echo "  Site URL:      ${SITE_URL}"
  echo "  Redirect URLs: ${REDIRECT_URLS}"
  exit 0
fi

payload="$(node -e "
console.log(JSON.stringify({
  site_url: process.argv[1],
  uri_allow_list: process.argv[2],
}));
" "${SITE_URL}" "${REDIRECT_URLS}")"

echo "Updating Auth URL config for project ${PROJECT_REF}..."
http_code="$(
  curl -sS -o /tmp/karofi-auth-config.json -w '%{http_code}' \
    -X PATCH "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${payload}"
)"

if [[ "${http_code}" == "200" ]]; then
  echo "OK — Auth URLs updated."
  cat /tmp/karofi-auth-config.json
  echo ""
else
  echo "Failed (HTTP ${http_code}). Response:"
  cat /tmp/karofi-auth-config.json
  echo ""
  echo "Fallback: configure in Dashboard (link above)."
  exit 1
fi
