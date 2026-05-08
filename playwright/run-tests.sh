#!/usr/bin/env bash
# run-tests.sh — SellScribe Playwright test runner
#
# Usage:
#   ./run-tests.sh [OPTIONS]
#
# Flags (skip interactive prompts):
#   -b <browser>   chromium | firefox | all
#   -m <mode>      headed | headless
#   -w <workers>   1-10 | max
#   -r <reporter>  list | dot | line | html | json | junit
#   -g <grep>      @smoke | @regression | <pattern>
#   -h             Show help

set -euo pipefail

# ── ANSI colours (disabled when not a terminal) ──────────────────────────────
if [[ -t 1 ]]; then
  BOLD='\033[1m'; CYAN='\033[36m'; GREEN='\033[32m'
  YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'
else
  BOLD=''; CYAN=''; GREEN=''; YELLOW=''; RED=''; RESET=''
fi

header() { printf "\n${BOLD}${CYAN}%s${RESET}\n" "$1"; }
ok()     { printf "${GREEN}✔ %s${RESET}\n" "$1"; }
note()   { printf "${YELLOW}  %s${RESET}\n" "$1"; }
err()    { printf "${RED}✘ %s${RESET}\n" "$1"; }

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"   # SellScribe root
APP_PORT=8080
APP_LOG="$SCRIPT_DIR/flutter-server.log"
FLUTTER_PID=""

# ── Defaults ──────────────────────────────────────────────────────────────────
BROWSER=""; MODE=""; WORKERS=""; REPORTER=""; GREP=""

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  printf "\n${BOLD}SellScribe Playwright Test Runner${RESET}\n\n"
  printf "Usage:  ./run-tests.sh [OPTIONS]\n\n"
  printf "  ${BOLD}-b <browser>${RESET}   Browser:\n"
  printf "                   chromium   Desktop Chrome  (default)\n"
  printf "                   firefox    Desktop Firefox\n"
  printf "                   all        Both browsers\n\n"
  printf "  ${BOLD}-m <mode>${RESET}      Display:\n"
  printf "                   headless   No browser window  (default)\n"
  printf "                   headed     Visible browser window\n\n"
  printf "  ${BOLD}-w <workers>${RESET}   Parallelism (default: auto):\n"
  printf "                   1          Sequential\n"
  printf "                   2-5        Balanced\n"
  printf "                   max        All CPU cores\n\n"
  printf "  ${BOLD}-r <reporter>${RESET}  Output format (default: list):\n"
  printf "                   list       One line per test with timing\n"
  printf "                   dot        Compact dots\n"
  printf "                   line       Compact single-line summary\n"
  printf "                   html       HTML report  (then: npm run report)\n"
  printf "                   json       JSON to test-results/results.json\n"
  printf "                   junit      JUnit XML to playwright-report/results.xml\n\n"
  printf "  ${BOLD}-g <grep>${RESET}      Filter by name or tag:\n"
  printf "                   @smoke         Smoke tests only\n"
  printf "                   @regression    Regression suite\n"
  printf "                   login          Tests containing 'login'\n\n"
  printf "  ${BOLD}-h${RESET}             Show this help\n\n"
  printf "${BOLD}Examples:${RESET}\n"
  printf "  ./run-tests.sh                                     # Interactive\n"
  printf "  ./run-tests.sh -b chromium -m headed               # Visible browser\n"
  printf "  ./run-tests.sh -b all -w 2                         # Both browsers\n"
  printf "  ./run-tests.sh -g @smoke -r dot                    # Smoke, compact\n"
  printf "  ./run-tests.sh -b chromium -m headed -w 1 -g login # Debug login\n\n"
}

# ── App lifecycle ─────────────────────────────────────────────────────────────
app_running() {
  curl -s -o /dev/null -w "%{http_code}" "http://localhost:$APP_PORT" 2>/dev/null | grep -q "200"
}

stop_app() {
  # Kill anything still listening on the port (handles dart/chrome child processes)
  local pids
  pids=$(lsof -ti tcp:"$APP_PORT" 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    note "Stopping Flutter dev server (port ${APP_PORT})..."
    echo "$pids" | xargs kill -TERM 2>/dev/null || true
    sleep 1
    # Force-kill any stragglers
    pids=$(lsof -ti tcp:"$APP_PORT" 2>/dev/null || true)
    [[ -n "$pids" ]] && echo "$pids" | xargs kill -9 2>/dev/null || true
    ok "Flutter dev server stopped."
  fi
  # Also clean up the tracked PID if still alive
  if [[ -n "$FLUTTER_PID" ]]; then
    kill "$FLUTTER_PID" 2>/dev/null || true
    wait "$FLUTTER_PID" 2>/dev/null || true
    FLUTTER_PID=""
  fi
}

start_app() {
  header "Flutter dev server"

  if app_running; then
    ok "Already running on port $APP_PORT — skipping start."
    return
  fi

  note "Starting Flutter dev server on port ${APP_PORT}..."
  note "Log: $APP_LOG"

  # Start flutter in the background; redirect all output to log file
  cd "$APP_DIR"
  flutter run -d chrome --web-port="$APP_PORT" \
    > "$APP_LOG" 2>&1 &
  FLUTTER_PID=$!
  cd "$SCRIPT_DIR"

  # Register cleanup on exit / interrupt / error
  trap 'stop_app' EXIT INT TERM

  # Wait up to 90 s for the server to respond
  local waited=0
  printf "  Waiting for server"
  until app_running; do
    if (( waited >= 90 )); then
      printf "\n"
      err "Flutter dev server did not start within 90 s."
      err "Check the log for details: $APP_LOG"
      exit 1
    fi
    printf "."
    sleep 3
    (( waited += 3 ))
  done
  printf "\n"
  ok "Flutter dev server ready on http://localhost:$APP_PORT"

  # Port-up ≠ Flutter ready. The HTTP server responds 200 while Dart is still
  # compiling. Debug builds take 20-40 s after port-up to finish compilation
  # and render the first frame. Sleep first, then poll for the semantics node.
  note "Waiting for Dart compilation (~30 s)..."
  sleep 30

  note "Waiting for Flutter first frame (flt-semantics-placeholder)..."
  node - <<'JSEOF'
const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(process.env.BASE_URL ?? 'http://localhost:8080');
  await page.waitForSelector('flt-semantics-placeholder', { timeout: 120_000 });
  await browser.close();
})().catch(err => { console.error('Flutter readiness check failed:', err.message); process.exit(1); });
JSEOF
  ok "Flutter first frame rendered — tests may start."
}

# ── Arg parsing ───────────────────────────────────────────────────────────────
while getopts "b:m:w:r:g:h" opt; do
  case $opt in
    b) BROWSER="$OPTARG" ;;  m) MODE="$OPTARG" ;;
    w) WORKERS="$OPTARG" ;;  r) REPORTER="$OPTARG" ;;
    g) GREP="$OPTARG" ;;     h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# ── Interactive prompts ───────────────────────────────────────────────────────
if [[ -z "$BROWSER" ]]; then
  header "Browser"
  echo "  1) chromium   Desktop Chrome  (recommended)"
  echo "  2) firefox    Desktop Firefox"
  echo "  3) all        Both browsers"
  read -rp "  Choice [1]: " c
  case "${c:-1}" in 2) BROWSER="firefox";; 3) BROWSER="all";; *) BROWSER="chromium";; esac
fi

if [[ -z "$MODE" ]]; then
  header "Display mode"
  echo "  1) headless   No browser window  (default)"
  echo "  2) headed     Visible browser window"
  read -rp "  Choice [1]: " c
  case "${c:-1}" in 2) MODE="headed";; *) MODE="headless";; esac
fi

if [[ -z "$WORKERS" ]]; then
  header "Parallel workers"
  echo "  1) auto   Playwright decides  (default)"
  echo "  2) 1      Sequential — one test at a time"
  echo "  3) 2      Two parallel workers"
  echo "  4) 5      Five parallel workers"
  read -rp "  Choice [1]: " c
  case "${c:-1}" in 2) WORKERS="1";; 3) WORKERS="2";; 4) WORKERS="5";; *) WORKERS="";; esac
fi

if [[ -z "$REPORTER" ]]; then
  header "Reporter"
  echo "  1) list   One line per test  (default)"
  echo "  2) dot    Compact dots"
  echo "  3) line   Compact single-line result"
  echo "  4) html   HTML report  (open with: npm run report)"
  echo "  5) json   JSON file"
  echo "  6) junit  JUnit XML"
  read -rp "  Choice [1]: " c
  case "${c:-1}" in 2) REPORTER="dot";; 3) REPORTER="line";; 4) REPORTER="html";;
                    5) REPORTER="json";; 6) REPORTER="junit";; *) REPORTER="list";; esac
fi

if [[ -z "$GREP" ]]; then
  header "Test filter  (leave blank to run all tests)"
  echo "  Examples: @smoke  @regression  login  register  settings"
  read -rp "  Filter [all]: " GREP
fi

# ── Start app ─────────────────────────────────────────────────────────────────
start_app

# ── Build command ─────────────────────────────────────────────────────────────
CMD="npx playwright test"
case "$BROWSER" in firefox) CMD+=" --project=firefox";; all) ;; *) CMD+=" --project=chromium";; esac
[[ "$MODE" == "headed" ]] && CMD+=" --headed"
[[ -n "$WORKERS" ]] && CMD+=" --workers=$WORKERS"
CMD+=" --reporter=$REPORTER"
[[ -n "$GREP" ]] && CMD+=" --grep=\"$GREP\""

# ── Summary ───────────────────────────────────────────────────────────────────
printf "\n${BOLD}┌─────────────────────────────────────┐${RESET}\n"
printf "${BOLD}│  SellScribe Playwright Test Run      │${RESET}\n"
printf "${BOLD}└─────────────────────────────────────┘${RESET}\n"
note "Browser:  ${BROWSER:-all}"
note "Mode:     ${MODE}"
note "Workers:  ${WORKERS:-auto}"
note "Reporter: ${REPORTER}"
note "Filter:   ${GREP:-none (all tests)}"
printf "\n${BOLD}Command:${RESET} ${CYAN}%s${RESET}\n\n" "$CMD"

# ── Run tests ─────────────────────────────────────────────────────────────────
eval "$CMD"
EXIT_CODE=$?

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
  ok "All tests passed."
  [[ "$REPORTER" == "html" ]] && note "Open the HTML report: npm run report"
else
  err "Some tests failed (exit $EXIT_CODE)."
  [[ "$REPORTER" == "html" ]] && note "Open the HTML report for details: npm run report"
fi

# stop_app is called automatically via the EXIT trap
exit $EXIT_CODE
