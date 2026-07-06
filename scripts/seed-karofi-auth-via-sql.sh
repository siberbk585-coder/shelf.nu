#!/usr/bin/env bash
# Seed Supabase Auth for migrated Karofi user when service_role key is unavailable.
# Prefer: pnpm webapp:seed:karofi-admin with valid SUPABASE_SERVICE_ROLE.
#
# Requires: Supabase SQL access (Dashboard SQL editor or MCP execute_sql).
# User id must match public."User".id from region migration.

set -euo pipefail

USER_ID="${KAROFI_USER_ID:-82550a0e-50a6-4da5-be81-c7f2ae99e6df}"
EMAIL="${DEMO_ADMIN_EMAIL:-admin@dqa-karofi.io.vn}"
PASSWORD="${DEMO_ADMIN_PASSWORD:-KarofiAdmin123!}"

cat <<SQL
-- Karofi admin auth (id must match public."User")
DELETE FROM auth.identities WHERE user_id = '${USER_ID}';
DELETE FROM auth.users WHERE id = '${USER_ID}';

INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, aud, role, raw_user_meta_data, raw_app_meta_data,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '${USER_ID}',
  '00000000-0000-0000-0000-000000000000',
  '${EMAIL}',
  crypt('${PASSWORD}', gen_salt('bf', 10)),
  now(), now(), now(),
  'authenticated', 'authenticated',
  '{"first_name":"Quản trị","last_name":"viên"}'::jsonb,
  '{"provider":"email","providers":["email"]}'::jsonb,
  '', '', '', ''
);

INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at, email
) VALUES (
  '${USER_ID}',
  '${USER_ID}',
  jsonb_build_object('sub', '${USER_ID}', 'email', '${EMAIL}', 'email_verified', true),
  'email', '${USER_ID}',
  now(), now(), now(), '${EMAIL}'
);
SQL

echo ""
echo "Paste the SQL above into Supabase SQL editor for project frgqshzrhpatolttqqdx."
