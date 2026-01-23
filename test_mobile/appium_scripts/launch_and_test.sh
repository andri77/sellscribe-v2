#!/bin/bash

# =============================================================================
# SellScribe Mobile Test Runner
# Launches emulator, starts Appium, runs tests, and generates HTML report
# =============================================================================
# Usage: ./launch_and_test.sh [OPTIONS]
# Examples:
#   ./launch_and_test.sh                       # Run all tests with HTML report
#   ./launch_and_test.sh --test test_login.py  # Run specific test file
#   ./launch_and_test.sh -m smoke              # Run smoke tests only
#   ./launch_and_test.sh --headless            # Run headless (CI mode)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_msg() {
    echo -e "${1}${2}${NC}"
}

print_header() {
    echo ""
    print_msg "$BLUE" "=============================================="
    print_msg "$BLUE" "$1"
    print_msg "$BLUE" "=============================================="
    echo ""
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$TEST_DIR/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Default values
PLATFORM="android"
TEST_FILE=""
MARKERS=""
HEADLESS=false
VERBOSE="-v"
RERUNS=2
CLEANUP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --test)
            TEST_FILE="$2"
            shift 2
            ;;
        -m|--markers)
            MARKERS="$2"
            shift 2
            ;;
        --headless)
            HEADLESS=true
            shift
            ;;
        --debug)
            VERBOSE="-v -s --log-cli-level=DEBUG"
            shift
            ;;
        -q|--quiet)
            VERBOSE=""
            shift
            ;;
        --reruns)
            RERUNS="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --platform PLATFORM  Target platform: android, ios (default: android)"
            echo "  --test FILE          Run specific test file (e.g., test_login.py)"
            echo "  -m, --markers MARK   Run tests with specific markers (smoke, regression, login, etc.)"
            echo "  --headless           Run emulator in headless mode (no window, for CI)"
            echo "  --debug              Enable debug logging"
            echo "  -q, --quiet          Quiet output"
            echo "  --reruns N           Retry failed tests N times (default: 2)"
            echo "  --cleanup            Stop emulator and Appium after tests"
            echo "  -h, --help           Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                           # Run all tests"
            echo "  $0 --test test_login.py     # Run login tests only"
            echo "  $0 -m smoke                  # Run smoke tests"
            echo "  $0 -m \"smoke and login\"     # Run smoke login tests"
            echo "  $0 --headless --cleanup     # CI mode"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set ANDROID_HOME if not set
if [ -z "$ANDROID_HOME" ]; then
    if [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_HOME="$HOME/Library/Android/sdk"
    elif [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
    fi
fi

export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

ADB_CMD="$ANDROID_HOME/platform-tools/adb"
EMULATOR_CMD="$ANDROID_HOME/emulator/emulator"

print_header "SellScribe Mobile Test Runner"

echo "Configuration:"
echo "  Platform:     $PLATFORM"
echo "  Test File:    ${TEST_FILE:-all tests}"
echo "  Markers:      ${MARKERS:-none}"
echo "  Headless:     $HEADLESS"
echo "  Reruns:       $RERUNS"
echo "  Timestamp:    $TIMESTAMP"
echo ""

# =============================================================================
# Step 1: Check/Start Emulator
# =============================================================================
print_msg "$CYAN" "[Step 1/4] Checking Android Emulator..."

RUNNING_EMU=$($ADB_CMD devices 2>/dev/null | grep "emulator-" | head -1 | cut -f1)

if [ -z "$RUNNING_EMU" ]; then
    print_msg "$YELLOW" "No emulator running. Starting emulator..."

    # Get first available AVD
    AVD_NAME=$($EMULATOR_CMD -list-avds 2>/dev/null | head -1)
    if [ -z "$AVD_NAME" ]; then
        print_msg "$RED" "Error: No AVD found. Create one in Android Studio first."
        exit 1
    fi

    print_msg "$BLUE" "Starting emulator: $AVD_NAME"

    # Build emulator options
    EMU_OPTS="-no-audio"
    if [ "$HEADLESS" = true ]; then
        EMU_OPTS="$EMU_OPTS -no-window"
    fi

    $EMULATOR_CMD -avd "$AVD_NAME" $EMU_OPTS &
    EMULATOR_PID=$!
    echo $EMULATOR_PID > /tmp/android_emulator.pid

    # Wait for emulator to appear
    print_msg "$YELLOW" "Waiting for emulator to start..."
    COUNTER=0
    while [ -z "$($ADB_CMD devices 2>/dev/null | grep 'emulator-')" ]; do
        sleep 2
        COUNTER=$((COUNTER + 2))
        if [ $COUNTER -ge 60 ]; then
            print_msg "$RED" "Error: Emulator failed to start within 60 seconds"
            exit 1
        fi
        echo -n "."
    done
    echo ""

    RUNNING_EMU=$($ADB_CMD devices 2>/dev/null | grep "emulator-" | head -1 | cut -f1)
fi

print_msg "$GREEN" "Emulator running: $RUNNING_EMU"

# Wait for boot completion
print_msg "$YELLOW" "Waiting for emulator boot completion..."
COUNTER=0
while [ "$($ADB_CMD -s $RUNNING_EMU shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
    sleep 2
    COUNTER=$((COUNTER + 2))
    if [ $COUNTER -ge 180 ]; then
        print_msg "$RED" "Error: Emulator boot timeout"
        exit 1
    fi
    echo -n "."
done
echo ""
sleep 3  # Extra time for launcher
print_msg "$GREEN" "Emulator fully booted!"

# =============================================================================
# Step 2: Check/Start Appium
# =============================================================================
print_msg "$CYAN" "[Step 2/4] Checking Appium Server..."

if ! lsof -Pi :4723 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_msg "$YELLOW" "Appium not running. Starting Appium server..."

    # Start Appium in background with logging
    mkdir -p "$REPORTS_DIR"
    nohup appium --port 4723 --base-path /wd/hub --log-level info > "$REPORTS_DIR/appium_${TIMESTAMP}.log" 2>&1 &
    APPIUM_PID=$!
    echo $APPIUM_PID > /tmp/appium.pid

    # Wait for Appium to be ready
    COUNTER=0
    while ! lsof -Pi :4723 -sTCP:LISTEN -t >/dev/null 2>&1; do
        sleep 1
        COUNTER=$((COUNTER + 1))
        if [ $COUNTER -ge 30 ]; then
            print_msg "$RED" "Error: Appium failed to start"
            cat "$REPORTS_DIR/appium_${TIMESTAMP}.log"
            exit 1
        fi
        echo -n "."
    done
    echo ""
    print_msg "$GREEN" "Appium started (PID: $APPIUM_PID)"
else
    print_msg "$GREEN" "Appium already running on port 4723"
fi

# =============================================================================
# Step 3: Run Tests
# =============================================================================
print_msg "$CYAN" "[Step 3/4] Running Tests..."
echo ""

cd "$TEST_DIR"

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    print_msg "$GREEN" "Virtual environment activated"
fi

# Create reports directory
mkdir -p "$REPORTS_DIR/screenshots"

# Build pytest command
PYTEST_CMD="pytest"

# Add test path
if [ -n "$TEST_FILE" ]; then
    PYTEST_CMD="$PYTEST_CMD tests/$TEST_FILE"
else
    PYTEST_CMD="$PYTEST_CMD tests/"
fi

# Add options
PYTEST_CMD="$PYTEST_CMD $VERBOSE"
PYTEST_CMD="$PYTEST_CMD --platform=$PLATFORM"

# Add markers
if [ -n "$MARKERS" ]; then
    PYTEST_CMD="$PYTEST_CMD -m \"$MARKERS\""
fi

# Add reruns for flaky tests
if [ "$RERUNS" -gt 0 ]; then
    PYTEST_CMD="$PYTEST_CMD --reruns $RERUNS --reruns-delay 2"
fi

# Add HTML report
HTML_REPORT="$REPORTS_DIR/report_${TIMESTAMP}.html"
PYTEST_CMD="$PYTEST_CMD --html=$HTML_REPORT --self-contained-html"

# Print command
echo "Running: $PYTEST_CMD"
echo ""

# Run tests and capture exit code
set +e
eval $PYTEST_CMD
TEST_EXIT_CODE=$?
set -e

# =============================================================================
# Step 4: Generate Report Summary
# =============================================================================
print_msg "$CYAN" "[Step 4/4] Generating Report..."

echo ""
print_header "Test Results Summary"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    print_msg "$GREEN" "STATUS: ALL TESTS PASSED"
else
    print_msg "$RED" "STATUS: SOME TESTS FAILED (exit code: $TEST_EXIT_CODE)"
fi

echo ""
echo "Reports:"
echo "  HTML Report: $HTML_REPORT"
echo "  Appium Log:  $REPORTS_DIR/appium_${TIMESTAMP}.log"
echo "  Screenshots: $REPORTS_DIR/screenshots/"
echo ""

# Open HTML report (macOS only)
if [ "$(uname)" = "Darwin" ] && [ -f "$HTML_REPORT" ]; then
    print_msg "$BLUE" "Opening HTML report..."
    open "$HTML_REPORT" 2>/dev/null || true
fi

# =============================================================================
# Cleanup (if requested)
# =============================================================================
if [ "$CLEANUP" = true ]; then
    print_msg "$YELLOW" "Cleaning up..."

    # Stop Appium
    if [ -f /tmp/appium.pid ]; then
        APPIUM_PID=$(cat /tmp/appium.pid)
        kill $APPIUM_PID 2>/dev/null || true
        rm /tmp/appium.pid
        print_msg "$GREEN" "Appium stopped"
    fi

    # Stop emulator
    if [ -f /tmp/android_emulator.pid ]; then
        EMULATOR_PID=$(cat /tmp/android_emulator.pid)
        kill $EMULATOR_PID 2>/dev/null || true
        rm /tmp/android_emulator.pid
        print_msg "$GREEN" "Emulator stopped"
    fi
fi

print_header "Done!"

exit $TEST_EXIT_CODE
