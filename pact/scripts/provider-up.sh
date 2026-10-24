#!/bin/bash
# provider-up.sh — start the providers that the pacts are verified against:
#   local Supabase (PostgREST + GoTrue, migrations applied from a clean reset) and the
#   generate-listing Edge Function with OPENAI_BASE_URL pointed at the test's OpenAI stub.
# Writes pact/.env.provider (API_URL, ANON_KEY, SERVICE_ROLE_KEY) for the verifier tests.
#
# Requires Docker and the Supabase CLI. Stop everything with provider-down.sh.

set -euo pipefail

PACT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(dirname "$PACT_DIR")"
LOG_DIR="$PACT_DIR/logs"
STUB_PORT="${OPENAI_STUB_PORT:-4010}"
# Edge runtime runs in Docker; host.docker.internal reaches the stub on the host
STUB_HOST="${OPENAI_STUB_HOST:-host.docker.internal}"

mkdir -p "$LOG_DIR"

for tool in docker supabase; do
  command -v "$tool" >/dev/null 2>&1 || { echo "✘ $tool not found — see pact plan M4 prerequisites" >&2; exit 1; }
done

cd "$PROJECT_ROOT"

if [[ ! -f supabase/config.toml ]]; then
  echo "→ supabase/config.toml missing — running supabase init"
  supabase init < /dev/null
fi

echo "→ Starting local Supabase"
supabase start
echo "→ Resetting database (applies supabase/migrations)"
supabase db reset --local

supabase status -o env 2>/dev/null > "$PACT_DIR/.env.provider"
for key in API_URL ANON_KEY SERVICE_ROLE_KEY; do
  grep -q "^$key=" "$PACT_DIR/.env.provider" || { echo "✘ $key missing from supabase status" >&2; exit 1; }
done

cat > "$PACT_DIR/.env.functions" <<ENV
OPENAI_API_KEY=pact-stub-key
OPENAI_BASE_URL=http://$STUB_HOST:$STUB_PORT
ENV

echo "→ Serving generate-listing (OpenAI → http://$STUB_HOST:$STUB_PORT)"
supabase functions serve generate-listing --env-file "$PACT_DIR/.env.functions" \
  > "$LOG_DIR/functions.log" 2>&1 &
echo $! > "$LOG_DIR/functions.pid"

API_URL=$(grep '^API_URL=' "$PACT_DIR/.env.provider" | cut -d= -f2- | tr -d '"')
for _ in $(seq 1 90); do
  # CORS preflight needs no body or JWT, so it's a cheap readiness probe
  status=$(curl -s -o /dev/null -w '%{http_code}' -X OPTIONS "$API_URL/functions/v1/generate-listing" || true)
  if [[ "$status" == "200" ]]; then
    echo "✔ Providers ready at $API_URL"
    exit 0
  fi
  sleep 1
done

echo "✘ generate-listing did not become ready — see $LOG_DIR/functions.log" >&2
exit 1
