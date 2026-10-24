#!/bin/bash
# provider-down.sh — stop what provider-up.sh started.

set -uo pipefail

PACT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$PACT_DIR/logs/functions.pid"

if [[ -f "$PID_FILE" ]]; then
  kill "$(cat "$PID_FILE")" 2>/dev/null || true
  rm -f "$PID_FILE"
fi

cd "$(dirname "$PACT_DIR")" && supabase stop --no-backup
rm -f "$PACT_DIR/.env.provider" "$PACT_DIR/.env.functions"
