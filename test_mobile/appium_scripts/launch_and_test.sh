#!/bin/bash
# launch_and_test.sh — SellScribe all-in-one mobile test runner
#
# Starts emulator + Appium if not already running, runs the test suite,
# then automatically stops whatever this session started on exit.
#
# Usage: ./launch_and_test.sh [OPTIONS]
# Examples:
#   ./launch_and_test.sh                       # Run all tests
#   ./launch_and_test.sh --test test_login.py  # Single test file
#   ./launch_and_test.sh -m smoke              # Smoke tests only
#   ./launch_and_test.sh --headless            # CI mode (no window)
#   ./launch_and_test.sh --keep-running        # Don't stop services after tests

set -euo pipefail

# ── ANSI colours ──────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD='\033[1m'; CYAN='\033[36m'; GREEN='\033[32m'
  YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'
else
  BOLD=''; CYAN=''; GREEN=''; YELLOW=''; RED=''; RESET=''
fi

header()  { printf "\n${BOLD}${CYAN}%s${RESET}\n" "$1"; }
ok()      { printf "${GREEN}✔ %s${RESET}\n" "$1"; }
note()    { printf "${YELLOW}  %s${RESET}\n" "$1"; }
err()     { printf "${RED}✘ %s${RESET}\n" "$1"; }
step()    { printf "\n${BOLD}${CYAN}[%s] %s${RESET}\n" "$1" "$2"; }

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$TEST_DIR")"
REPORTS_DIR="$TEST_DIR/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ── Android SDK ───────────────────────────────────────────────────────────────
if [[ -z "${ANDROID_HOME:-}" ]]; then
  if [[ -d "$HOME/Library/Android/sdk" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
  elif [[ -d "$HOME/Android/Sdk" ]]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
  fi
fi
export PATH="$PATH:${ANDROID_HOME:-}/platform-tools:${ANDROID_HOME:-}/emulator"
ADB_CMD="${ANDROID_HOME}/platform-tools/adb"
EMULATOR_CMD="${ANDROID_HOME}/emulator/emulator"

# ── Defaults ──────────────────────────────────────────────────────────────────
PLATFORM="android"
TEST_FILE=""
MARKERS=""
HEADLESS=false
VERBOSE="-v"
RERUNS=2
KEEP_RUNNING=false

# Track what this run started (only stop what we started)
EMULATOR_STARTED=false
APPIUM_STARTED=false

# ── Cleanup (called automatically on EXIT/INT/TERM) ───────────────────────────
cleanup() {
  if [[ "$KEEP_RUNNING" == "true" ]]; then
    note "Keeping services running (--keep-running)."
    return
  fi

  echo ""
  header "Cleanup"

  if [[ "$APPIUM_STARTED" == "true" ]]; then
    note "Stopping Appium server..."
    if [[ -f /tmp/appium.pid ]]; then
      local pid
      pid=$(cat /tmp/appium.pid)
      kill "$pid" 2>/dev/null || true
      rm -f /tmp/appium.pid
    fi
    # Belt-and-suspenders: kill by port
    local port_pid
    port_pid=$(lsof -ti tcp:4723 2>/dev/null || true)
    [[ -n "$port_pid" ]] && echo "$port_pid" | xargs kill -TERM 2>/dev/null || true
    ok "Appium server stopped."
  fi

  if [[ "$EMULATOR_STARTED" == "true" ]]; then
    note "Stopping Android emulator..."
    if [[ -f /tmp/android_emulator.pid ]]; then
      local emu_pid
      emu_pid=$(cat /tmp/android_emulator.pid)
      kill "$emu_pid" 2>/dev/null || true
      rm -f /tmp/android_emulator.pid
    fi
    # Also send adb emu kill (cleaner shutdown)
    "${ADB_CMD}" emu kill 2>/dev/null || true
    ok "Android emulator stopped."
  fi
}

trap 'cleanup' EXIT INT TERM

# ── Arg parsing ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --platform)   PLATFORM="$2";    shift 2 ;;
    --test)       TEST_FILE="$2";   shift 2 ;;
    -m|--markers) MARKERS="$2";     shift 2 ;;
    --headless)   HEADLESS=true;    shift ;;
    --debug)      VERBOSE="-v -s --log-cli-level=DEBUG"; shift ;;
    -q|--quiet)   VERBOSE="";       shift ;;
    --reruns)     RERUNS="$2";      shift 2 ;;
    --keep-running) KEEP_RUNNING=true; shift ;;
    -h|--help)
      printf "\n${BOLD}SellScribe Mobile Test Runner${RESET}\n\n"
      printf "Usage:  ./launch_and_test.sh [OPTIONS]\n\n"
      printf "  ${BOLD}--platform${RESET}       android | ios  (default: android)\n"
      printf "  ${BOLD}--test FILE${RESET}      Run specific test file\n"
      printf "  ${BOLD}-m MARKERS${RESET}       Filter by marker: smoke, regression, login…\n"
      printf "  ${BOLD}--headless${RESET}       Emulator without window (CI mode)\n"
      printf "  ${BOLD}--debug${RESET}          Verbose test logging\n"
      printf "  ${BOLD}-q, --quiet${RESET}      Minimal output\n"
      printf "  ${BOLD}--reruns N${RESET}       Retry flaky tests N times  (default: 2)\n"
      printf "  ${BOLD}--keep-running${RESET}   Don't stop services after tests\n"
      printf "  ${BOLD}-h, --help${RESET}       Show this help\n\n"
      printf "${BOLD}Examples:${RESET}\n"
      printf "  ./launch_and_test.sh                       # All tests\n"
      printf "  ./launch_and_test.sh --test test_login.py  # Login tests only\n"
      printf "  ./launch_and_test.sh -m smoke              # Smoke suite\n"
      printf "  ./launch_and_test.sh --headless            # CI mode\n\n"
      exit 0
      ;;
    *) printf "${RED}Unknown option: %s${RESET}\n" "$1"; exit 1 ;;
  esac
done

# ── Header ────────────────────────────────────────────────────────────────────
printf "\n${BOLD}┌──────────────────────────────────────────┐${RESET}\n"
printf "${BOLD}│  SellScribe Mobile Test Runner            │${RESET}\n"
printf "${BOLD}└──────────────────────────────────────────┘${RESET}\n"
note "Platform:   $PLATFORM"
note "Test File:  ${TEST_FILE:-all tests}"
note "Markers:    ${MARKERS:-none (all)}"
note "Headless:   $HEADLESS"
note "Reruns:     $RERUNS"
note "Timestamp:  $TIMESTAMP"

mkdir -p "$REPORTS_DIR/screenshots"

# ── Step 1: Android emulator ──────────────────────────────────────────────────
if [[ "$PLATFORM" == "android" ]]; then
  step "1/3" "Android Emulator"

  RUNNING_EMU=$("${ADB_CMD}" devices 2>/dev/null | grep "emulator-" | head -1 | cut -f1 || true)

  if [[ -n "$RUNNING_EMU" ]]; then
    ok "Emulator already running: $RUNNING_EMU"
  else
    AVD_NAME=$("${EMULATOR_CMD}" -list-avds 2>/dev/null | head -1 || true)
    if [[ -z "$AVD_NAME" ]]; then
      err "No AVD found. Create one in Android Studio > Device Manager."
      exit 1
    fi

    note "Starting emulator: $AVD_NAME"
    EMU_OPTS="-no-audio"
    [[ "$HEADLESS" == "true" ]] && EMU_OPTS="$EMU_OPTS -no-window"
    "${EMULATOR_CMD}" -avd "$AVD_NAME" $EMU_OPTS &
    echo $! > /tmp/android_emulator.pid
    EMULATOR_STARTED=true

    note "Waiting for emulator to appear..."
    local_counter=0
    until "${ADB_CMD}" devices 2>/dev/null | grep -q "emulator-"; do
      sleep 2; (( local_counter += 2 ))
      if (( local_counter >= 90 )); then
        err "Emulator failed to appear within 90 s."
        exit 1
      fi
      printf "."
    done
    printf "\n"
    RUNNING_EMU=$("${ADB_CMD}" devices 2>/dev/null | grep "emulator-" | head -1 | cut -f1 || true)
    ok "Emulator started: $RUNNING_EMU"
  fi

  # Wait for full boot
  note "Waiting for boot completion..."
  boot_counter=0
  until [[ "$("${ADB_CMD}" -s "$RUNNING_EMU" shell getprop sys.boot_completed 2>/dev/null)" == "1" ]]; do
    sleep 2; (( boot_counter += 2 ))
    if (( boot_counter >= 180 )); then
      err "Emulator boot timeout."
      exit 1
    fi
    printf "."
  done
  printf "\n"
  sleep 3  # launcher settling time
  ok "Emulator fully booted!"

  # Install app if needed
  APP_PACKAGE="com.sellscribe.app"
  APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
  if ! "${ADB_CMD}" -s "$RUNNING_EMU" shell pm list packages 2>/dev/null | grep -q "$APP_PACKAGE"; then
    if [[ -f "$APK_PATH" ]]; then
      note "Installing SellScribe APK..."
      "${ADB_CMD}" -s "$RUNNING_EMU" install "$APK_PATH"
      ok "App installed."
    else
      err "APK not found at $APK_PATH"
      note "Build first: flutter build apk --debug"
      exit 1
    fi
  else
    ok "SellScribe app already installed."
  fi
fi

# ── Step 2: Appium server ─────────────────────────────────────────────────────
step "2/3" "Appium Server"

if lsof -Pi :4723 -sTCP:LISTEN -t >/dev/null 2>&1; then
  ok "Appium already running on port 4723."
else
  if ! command -v appium &>/dev/null; then
    err "Appium not installed. Run: npm install -g appium"
    exit 1
  fi

  note "Starting Appium server..."
  nohup appium --port 4723 --base-path /wd/hub --log-level info \
    > "$REPORTS_DIR/appium_${TIMESTAMP}.log" 2>&1 &
  echo $! > /tmp/appium.pid
  APPIUM_STARTED=true

  appium_counter=0
  until lsof -Pi :4723 -sTCP:LISTEN -t >/dev/null 2>&1; do
    sleep 1; (( appium_counter += 1 ))
    if (( appium_counter >= 30 )); then
      err "Appium failed to start. Check: $REPORTS_DIR/appium_${TIMESTAMP}.log"
      exit 1
    fi
    printf "."
  done
  printf "\n"
  ok "Appium server started (PID: $(cat /tmp/appium.pid))."
fi

# ── Step 3: Run tests ─────────────────────────────────────────────────────────
step "3/3" "Running Tests"
echo ""

cd "$TEST_DIR"
[[ -f venv/bin/activate ]] && source venv/bin/activate

PYTEST_CMD="pytest"
[[ -n "$TEST_FILE" ]] && PYTEST_CMD="$PYTEST_CMD tests/$TEST_FILE" || PYTEST_CMD="$PYTEST_CMD tests/"
PYTEST_CMD="$PYTEST_CMD $VERBOSE --platform=$PLATFORM"
[[ -n "$MARKERS" ]]   && PYTEST_CMD="$PYTEST_CMD -m \"$MARKERS\""
(( RERUNS > 0 ))       && PYTEST_CMD="$PYTEST_CMD --reruns $RERUNS --reruns-delay 2"

HTML_REPORT="$REPORTS_DIR/report_${TIMESTAMP}.html"
PYTEST_CMD="$PYTEST_CMD --html=$HTML_REPORT --self-contained-html"

note "Command: $PYTEST_CMD"
echo ""

set +e
eval "$PYTEST_CMD"
TEST_EXIT_CODE=$?
set -e

# ── Results ───────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}┌──────────────────────────────────────────┐${RESET}\n"
printf "${BOLD}│  Results                                  │${RESET}\n"
printf "${BOLD}└──────────────────────────────────────────┘${RESET}\n"
if [[ $TEST_EXIT_CODE -eq 0 ]]; then
  ok "All tests passed."
else
  err "Some tests failed (exit $TEST_EXIT_CODE)."
fi
note "HTML report: $HTML_REPORT"
[[ "$APPIUM_STARTED" == "true" ]] && note "Appium log: $REPORTS_DIR/appium_${TIMESTAMP}.log"

# Open report on macOS
if [[ "$(uname)" == "Darwin" ]] && [[ -f "$HTML_REPORT" ]]; then
  open "$HTML_REPORT" 2>/dev/null || true
fi

# cleanup() is called by EXIT trap
exit $TEST_EXIT_CODE
