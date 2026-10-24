#!/bin/bash
# run-all-tests.sh — Run web, API, and mobile test suites
#
# Usage:
#   ./scripts/run-all-tests.sh               # all suites
#   ./scripts/run-all-tests.sh --web         # Playwright (web + API) only
#   ./scripts/run-all-tests.sh --mobile      # Appium only
#   ./scripts/run-all-tests.sh --smoke       # @smoke tag across all suites
#   ./scripts/run-all-tests.sh --no-mobile   # skip mobile (no emulator needed)
#   ./scripts/run-all-tests.sh --pact        # Pact consumer contracts + Dart model guard only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$SCRIPT_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOGS_DIR/run_${TIMESTAMP}.log"

mkdir -p "$LOGS_DIR"

# ── colour helpers ─────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD='\033[1m'; GREEN='\033[32m'; RED='\033[31m'
  YELLOW='\033[33m'; CYAN='\033[36m'; RESET='\033[0m'
else
  BOLD=''; GREEN=''; RED=''; YELLOW=''; CYAN=''; RESET=''
fi

header() { printf "\n${BOLD}${CYAN}══  %s  ══${RESET}\n" "$1" | tee -a "$LOG_FILE"; }
ok()     { printf "${GREEN}✔ %s${RESET}\n" "$1" | tee -a "$LOG_FILE"; }
fail()   { printf "${RED}✘ %s${RESET}\n" "$1" | tee -a "$LOG_FILE"; }
note()   { printf "${YELLOW}→ %s${RESET}\n" "$1" | tee -a "$LOG_FILE"; }

# ── argument parsing ───────────────────────────────────────────────────────────
RUN_WEB=true
RUN_MOBILE=true
RUN_PACT=false
SMOKE_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --web)       RUN_MOBILE=false ;;
    --mobile)    RUN_WEB=false ;;
    --no-mobile) RUN_MOBILE=false ;;
    --pact)      RUN_PACT=true; RUN_WEB=false; RUN_MOBILE=false ;;
    --smoke)     SMOKE_ONLY=true ;;
    --help|-h)
      printf "Usage: %s [--web|--mobile|--no-mobile|--pact|--smoke]\n" "$(basename "$0")"
      exit 0
      ;;
  esac
done

# ── results tracking ───────────────────────────────────────────────────────────
WEB_EXIT=0
MOBILE_EXIT=0
PACT_EXIT=0

printf "\n${BOLD}SellScribe Test Runner${RESET}  [%s]\n" "$TIMESTAMP" | tee -a "$LOG_FILE"
note "Log: $LOG_FILE"

# ══════════════════════════════════════════════════════════════════════════════
# WEB + API  (TypeScript Playwright)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_WEB" == "true" ]]; then
  header "Web + API Tests (Playwright)"

  PLAYWRIGHT_DIR="$PROJECT_ROOT/playwright"

  # Non-login shells (cron, IDE runners) may not inherit Homebrew/nvm on PATH
  if ! command -v npm >/dev/null 2>&1; then
    for dir in /opt/homebrew/bin /usr/local/bin; do
      [[ -x "$dir/npm" ]] && export PATH="$dir:$PATH" && break
    done
  fi
  if ! command -v npm >/dev/null 2>&1 && [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    set +u; source "$HOME/.nvm/nvm.sh"; set -u
  fi
  if ! command -v npm >/dev/null 2>&1; then
    fail "npm not found — install Node (e.g. 'brew install node') or add it to PATH"
    exit 1
  fi

  if [[ ! -d "$PLAYWRIGHT_DIR/node_modules" ]]; then
    note "Installing Playwright dependencies..."
    (cd "$PLAYWRIGHT_DIR" && npm ci) >> "$LOG_FILE" 2>&1
  fi

  PW_CMD="npx playwright test"
  [[ "$SMOKE_ONLY" == "true" ]] && PW_CMD="$PW_CMD --grep @smoke"

  note "Command: $PW_CMD"
  set +e
  (cd "$PLAYWRIGHT_DIR" && eval "$PW_CMD") 2>&1 | tee -a "$LOG_FILE"
  WEB_EXIT=${PIPESTATUS[0]}
  set -e

  if [[ $WEB_EXIT -eq 0 ]]; then
    ok "Web + API tests passed."
  else
    fail "Web + API tests FAILED (exit $WEB_EXIT)."
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# MOBILE  (Appium / Python)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_MOBILE" == "true" ]]; then
  header "Mobile Tests (Appium)"

  MOBILE_SCRIPT="$PROJECT_ROOT/test_mobile/appium_scripts/launch_and_test.sh"

  MOBILE_ARGS=""
  [[ "$SMOKE_ONLY" == "true" ]] && MOBILE_ARGS="-m smoke"

  note "Command: $MOBILE_SCRIPT $MOBILE_ARGS"
  set +e
  bash "$MOBILE_SCRIPT" $MOBILE_ARGS 2>&1 | tee -a "$LOG_FILE"
  MOBILE_EXIT=${PIPESTATUS[0]}
  set -e

  if [[ $MOBILE_EXIT -eq 0 ]]; then
    ok "Mobile tests passed."
  else
    fail "Mobile tests FAILED (exit $MOBILE_EXIT)."
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# CONTRACT  (Pact consumer + Dart model guard; provider verification runs in CI)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_PACT" == "true" ]]; then
  header "Contract Tests (Pact)"

  PACT_DIR="$PROJECT_ROOT/pact"

  if [[ ! -d "$PACT_DIR/node_modules" ]]; then
    note "Installing Pact dependencies..."
    (cd "$PACT_DIR" && npm ci) >> "$LOG_FILE" 2>&1
  fi

  note "Command: npm run test:consumer && flutter test test/contract"
  set +e
  { (cd "$PACT_DIR" && npm run test:consumer) && (cd "$PROJECT_ROOT" && flutter test test/contract); } 2>&1 | tee -a "$LOG_FILE"
  PACT_EXIT=${PIPESTATUS[0]}
  set -e

  if [[ $PACT_EXIT -eq 0 ]]; then
    ok "Contract tests passed."
  else
    fail "Contract tests FAILED (exit $PACT_EXIT)."
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════════════
header "Summary"

OVERALL=0
[[ "$RUN_WEB"    == "true" && $WEB_EXIT    -ne 0 ]] && OVERALL=1
[[ "$RUN_MOBILE" == "true" && $MOBILE_EXIT -ne 0 ]] && OVERALL=1
[[ "$RUN_PACT"   == "true" && $PACT_EXIT   -ne 0 ]] && OVERALL=1

[[ "$RUN_WEB"    == "true" ]] && { [[ $WEB_EXIT    -eq 0 ]] && ok "Web + API : PASS" || fail "Web + API : FAIL"; }
[[ "$RUN_MOBILE" == "true" ]] && { [[ $MOBILE_EXIT -eq 0 ]] && ok "Mobile   : PASS" || fail "Mobile   : FAIL"; }
[[ "$RUN_PACT"   == "true" ]] && { [[ $PACT_EXIT   -eq 0 ]] && ok "Contract : PASS" || fail "Contract : FAIL"; }

note "Full log: $LOG_FILE"
exit $OVERALL
