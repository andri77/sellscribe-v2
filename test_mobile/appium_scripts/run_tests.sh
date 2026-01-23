#!/bin/bash

# =============================================================================
# Test Runner Script for SellScribe Mobile Testing
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_msg() {
    echo -e "${1}${2}${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$TEST_DIR")"

# Default values
PLATFORM="android"
TEST_FILE=""
MARKERS=""
PARALLEL=""
HTML_REPORT=false
ALLURE_REPORT=false
VERBOSE="-v"
RERUNS=0
HEADLESS=false
START_EMULATOR=false

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
        -n|--parallel)
            PARALLEL="$2"
            shift 2
            ;;
        --html)
            HTML_REPORT=true
            shift
            ;;
        --allure)
            ALLURE_REPORT=true
            shift
            ;;
        --reruns)
            RERUNS="$2"
            shift 2
            ;;
        -q|--quiet)
            VERBOSE=""
            shift
            ;;
        --debug)
            VERBOSE="-v -s --log-cli-level=DEBUG"
            shift
            ;;
        --headless)
            HEADLESS=true
            shift
            ;;
        --start-emulator)
            START_EMULATOR=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --platform PLATFORM  Target platform: android, ios (default: android)"
            echo "  --test FILE          Run specific test file"
            echo "  -m, --markers MARK   Run tests with specific markers (e.g., smoke, regression)"
            echo "  -n, --parallel N     Run N tests in parallel"
            echo "  --html              Generate HTML report"
            echo "  --allure            Generate Allure report"
            echo "  --reruns N          Retry failed tests N times"
            echo "  -q, --quiet         Quiet output"
            echo "  --debug             Enable debug logging"
            echo "  --headless          Run emulator in headless mode (no window)"
            echo "  --start-emulator    Start emulator automatically if not running"
            echo "  -h, --help          Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                           # Run all tests"
            echo "  $0 --test test_login.py     # Run specific test"
            echo "  $0 -m smoke                  # Run smoke tests"
            echo "  $0 --platform ios            # Run on iOS"
            echo "  $0 -n 4 --html              # Run 4 tests parallel with HTML report"
            echo "  $0 --start-emulator --headless -m smoke  # Run headless (CI mode)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Print header
echo ""
print_msg "$BLUE" "=============================================="
print_msg "$BLUE" "SellScribe Mobile Test Runner"
print_msg "$BLUE" "=============================================="
echo ""

# Change to test directory
cd "$TEST_DIR"

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    print_msg "$GREEN" "Virtual environment activated"
else
    print_msg "$YELLOW" "Warning: Virtual environment not found"
    print_msg "$YELLOW" "Run install_appium.sh first"
fi

# Start emulator if requested
if [ "$START_EMULATOR" = true ] && [ "$PLATFORM" = "android" ]; then
    print_msg "$BLUE" "Checking Android emulator..."

    # Set ANDROID_HOME if not set
    if [ -z "$ANDROID_HOME" ]; then
        if [ -d "$HOME/Library/Android/sdk" ]; then
            export ANDROID_HOME="$HOME/Library/Android/sdk"
        elif [ -d "$HOME/Android/Sdk" ]; then
            export ANDROID_HOME="$HOME/Android/Sdk"
        fi
    fi

    # Check if emulator is running
    RUNNING_EMU=$($ANDROID_HOME/platform-tools/adb devices 2>/dev/null | grep "emulator-" | head -1)
    if [ -z "$RUNNING_EMU" ]; then
        print_msg "$YELLOW" "No emulator running. Starting emulator..."

        # Get first available AVD
        AVD_NAME=$($ANDROID_HOME/emulator/emulator -list-avds 2>/dev/null | head -1)
        if [ -z "$AVD_NAME" ]; then
            print_msg "$RED" "Error: No AVD found. Create one in Android Studio first."
            exit 1
        fi

        # Start emulator (headless if requested)
        EMU_OPTS="-no-audio"
        if [ "$HEADLESS" = true ]; then
            EMU_OPTS="$EMU_OPTS -no-window"
        fi

        print_msg "$BLUE" "Starting emulator: $AVD_NAME"
        $ANDROID_HOME/emulator/emulator -avd "$AVD_NAME" $EMU_OPTS &

        # Wait for emulator to start
        print_msg "$YELLOW" "Waiting for emulator to boot..."
        COUNTER=0
        while [ -z "$($ANDROID_HOME/platform-tools/adb devices 2>/dev/null | grep 'emulator-')" ]; do
            sleep 2
            COUNTER=$((COUNTER + 2))
            if [ $COUNTER -ge 60 ]; then
                print_msg "$RED" "Error: Emulator failed to start"
                exit 1
            fi
            echo -n "."
        done
        echo ""

        # Wait for boot completion
        DEVICE=$($ANDROID_HOME/platform-tools/adb devices 2>/dev/null | grep "emulator-" | cut -f1)
        COUNTER=0
        while [ "$($ANDROID_HOME/platform-tools/adb -s $DEVICE shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
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

        print_msg "$GREEN" "Emulator is ready!"

        # Install APK if not installed
        APP_PACKAGE="com.sellscribe.app"
        if ! $ANDROID_HOME/platform-tools/adb -s $DEVICE shell pm list packages 2>/dev/null | grep -q "$APP_PACKAGE"; then
            APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
            if [ -f "$APK_PATH" ]; then
                print_msg "$BLUE" "Installing app..."
                $ANDROID_HOME/platform-tools/adb -s $DEVICE install "$APK_PATH"
                print_msg "$GREEN" "App installed"
            else
                print_msg "$YELLOW" "Warning: APK not found at $APK_PATH"
                print_msg "$YELLOW" "Build the app first: flutter build apk --debug"
            fi
        fi
    else
        print_msg "$GREEN" "Emulator already running"
    fi
fi

# Check if Appium is running
if ! lsof -Pi :4723 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_msg "$YELLOW" "Appium server not running on port 4723"
    if [ "$START_EMULATOR" = true ]; then
        print_msg "$BLUE" "Starting Appium server..."
        "$SCRIPT_DIR/start_appium.sh" -b
        sleep 3
    else
        read -p "Start Appium server? (y/n): " START_APPIUM
        if [ "$START_APPIUM" = "y" ] || [ "$START_APPIUM" = "Y" ]; then
            "$SCRIPT_DIR/start_appium.sh" -b
            sleep 3
        fi
    fi
fi

# Check device connectivity
echo ""
echo "Checking device connectivity..."
if [ "$PLATFORM" = "android" ]; then
    DEVICES=$(adb devices 2>/dev/null | grep -v "List" | grep -v "^$" | wc -l)
    if [ "$DEVICES" -eq 0 ]; then
        print_msg "$RED" "Error: No Android devices found"
        echo "Please connect a device or start an emulator"
        exit 1
    else
        print_msg "$GREEN" "Found $DEVICES Android device(s)"
        adb devices
    fi
elif [ "$PLATFORM" = "ios" ]; then
    if [ "$(uname)" != "Darwin" ]; then
        print_msg "$RED" "Error: iOS testing requires macOS"
        exit 1
    fi
    # Check for iOS simulator or device
    SIMULATORS=$(xcrun simctl list devices | grep -c "Booted" || true)
    if [ "$SIMULATORS" -eq 0 ]; then
        print_msg "$YELLOW" "Warning: No iOS simulators running"
    else
        print_msg "$GREEN" "Found $SIMULATORS iOS simulator(s)"
    fi
fi

# Create reports directory
mkdir -p reports

# Build pytest command
PYTEST_CMD="pytest"

# Add test path
if [ -n "$TEST_FILE" ]; then
    PYTEST_CMD="$PYTEST_CMD tests/$TEST_FILE"
else
    PYTEST_CMD="$PYTEST_CMD tests/"
fi

# Add verbose flag
PYTEST_CMD="$PYTEST_CMD $VERBOSE"

# Add platform
PYTEST_CMD="$PYTEST_CMD --platform=$PLATFORM"

# Add markers
if [ -n "$MARKERS" ]; then
    PYTEST_CMD="$PYTEST_CMD -m $MARKERS"
fi

# Add parallel execution
if [ -n "$PARALLEL" ]; then
    PYTEST_CMD="$PYTEST_CMD -n $PARALLEL"
fi

# Add reruns
if [ "$RERUNS" -gt 0 ]; then
    PYTEST_CMD="$PYTEST_CMD --reruns $RERUNS"
fi

# Add HTML report
if [ "$HTML_REPORT" = true ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    PYTEST_CMD="$PYTEST_CMD --html=reports/report_${TIMESTAMP}.html --self-contained-html"
fi

# Add Allure report
if [ "$ALLURE_REPORT" = true ]; then
    PYTEST_CMD="$PYTEST_CMD --alluredir=reports/allure-results"
fi

# Print test configuration
echo ""
echo "Test Configuration:"
echo "  Platform:   $PLATFORM"
echo "  Test File:  ${TEST_FILE:-all tests}"
echo "  Markers:    ${MARKERS:-none}"
echo "  Parallel:   ${PARALLEL:-no}"
echo "  Reruns:     $RERUNS"
echo "  HTML:       $HTML_REPORT"
echo "  Allure:     $ALLURE_REPORT"
echo ""
echo "Running: $PYTEST_CMD"
echo ""
print_msg "$BLUE" "=============================================="
echo ""

# Run tests
$PYTEST_CMD
TEST_EXIT_CODE=$?

# Generate Allure report if enabled
if [ "$ALLURE_REPORT" = true ] && command -v allure &> /dev/null; then
    echo ""
    print_msg "$BLUE" "Generating Allure report..."
    allure generate reports/allure-results -o reports/allure-report --clean
    print_msg "$GREEN" "Report generated: reports/allure-report/index.html"
fi

# Print summary
echo ""
print_msg "$BLUE" "=============================================="
if [ $TEST_EXIT_CODE -eq 0 ]; then
    print_msg "$GREEN" "All tests passed!"
else
    print_msg "$RED" "Some tests failed (exit code: $TEST_EXIT_CODE)"
fi
print_msg "$BLUE" "=============================================="

exit $TEST_EXIT_CODE
