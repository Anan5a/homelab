#!/usr/bin/env bash
set -euo pipefail

# Generates all required secrets for the Supabase .env file.
# Pure bash + openssl, no Node/npm dependency needed for JWT signing.

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

if [[ -f "$ENV_FILE" ]]; then
  read -rp ".env already exists. Overwrite? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted. No changes made."
    exit 0
  fi
fi

if [[ ! -f "$ENV_EXAMPLE" ]]; then
  echo "Error: $ENV_EXAMPLE not found in current directory."
  exit 1
fi

# ── base64url helper (no padding, URL-safe) ──
b64url() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

# ── HS256 JWT signer ──
# Usage: sign_jwt '<json-payload>' '<secret>'
sign_jwt() {
  local payload="$1"
  local secret="$2"
  local header='{"alg":"HS256","typ":"JWT"}'

  local header_b64
  header_b64=$(printf '%s' "$header" | b64url)
  local payload_b64
  payload_b64=$(printf '%s' "$payload" | b64url)

  local signing_input="${header_b64}.${payload_b64}"
  local signature
  signature=$(printf '%s' "$signing_input" | openssl dgst -sha256 -hmac "$secret" -binary | b64url)

  printf '%s.%s' "$signing_input" "$signature"
}

echo "Generating secrets..."

POSTGRES_PASSWORD=$(openssl rand -hex 24)
JWT_SECRET=$(openssl rand -base64 40 | tr -d '\n')
REALTIME_SECRET_KEY_BASE=$(openssl rand -base64 48 | tr -d '\n')
LOGFLARE_API_KEY=$(openssl rand -hex 16)

NOW=$(date +%s)
EXP=$((NOW + 10*365*24*60*60))   # 10 years out

ANON_PAYLOAD=$(printf '{"role":"anon","iss":"supabase","iat":%d,"exp":%d}' "$NOW" "$EXP")
SERVICE_PAYLOAD=$(printf '{"role":"service_role","iss":"supabase","iat":%d,"exp":%d}' "$NOW" "$EXP")

ANON_KEY=$(sign_jwt "$ANON_PAYLOAD" "$JWT_SECRET")
SERVICE_ROLE_KEY=$(sign_jwt "$SERVICE_PAYLOAD" "$JWT_SECRET")

# ── Write .env from .env.example, substituting generated values ──
cp "$ENV_EXAMPLE" "$ENV_FILE"

set_env_var() {
  local key="$1"
  local value="$2"
  # Escape & and / for sed replacement safety
  local escaped_value
  escaped_value=$(printf '%s' "$value" | sed -e 's/[\/&]/\\&/g')
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i.bak "s|^${key}=.*|${key}=${escaped_value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

set_env_var "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD"
set_env_var "JWT_SECRET" "$JWT_SECRET"
set_env_var "ANON_KEY" "$ANON_KEY"
set_env_var "SERVICE_ROLE_KEY" "$SERVICE_ROLE_KEY"
set_env_var "REALTIME_SECRET_KEY_BASE" "$REALTIME_SECRET_KEY_BASE"
set_env_var "LOGFLARE_API_KEY" "$LOGFLARE_API_KEY"

rm -f "${ENV_FILE}.bak"

echo ""
echo "Done. Secrets written to $ENV_FILE"
echo ""
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
echo "JWT_SECRET=${JWT_SECRET}"
echo "ANON_KEY=${ANON_KEY}"
echo "SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}"
echo "REALTIME_SECRET_KEY_BASE=${REALTIME_SECRET_KEY_BASE}"
echo "LOGFLARE_API_KEY=${LOGFLARE_API_KEY}"
echo ""
echo "Review $ENV_FILE, fill in any remaining optional values, then run ./setup.sh"
