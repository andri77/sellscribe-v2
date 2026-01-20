#!/bin/bash

# =============================================================================
# Android Emulator Startup Script for SellScribe Mobile Testing
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

# Default configuration
EMULATOR_NAME=""
WAIT_BOOT=true
TIMEOUT=120
COLD_BOOT=false
WIPE_DATA=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            EMULATOR_NAME="$2"
            shift 2
            ;;
        --no-wait)
            WAIT_BOOT=false
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --cold-boot)
            COLD_BOOT=true
            shift
            ;;
        --wipe)
            WIPE_DATA=true
            shift
            ;;
        -l|--list)
            echo "Available emulators:"
            $ANDROID_HOME/emulator/emulator -list-avds
            exit 0
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -n, --name NAME    Emulator name (AVD name)"
            echo "  -l, --list         List available emulators"
            echo "  --no-wait          Don't wait for boot completion"
            echo "  --timeout SEC      Boot timeout in seconds (default: 120)"
            echo "  --cold-boot        Perform cold boot"
            echo "  --wipe             Wipe user data"
            echo "  -h, --help         Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check ANDROID_HOME
if [ -z "$ANDROID_HOME" ]; then
    # Try common paths
    if [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_HOME="$HOME/Library/Android/sdk"
    elif [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
    else
        print_msg "$RED" "Error: ANDROID_HOME is not set"
        echo "Please set ANDROID_HOME environment variable"
        exit 1
    fi
fi

EMULATOR_CMD="$ANDROID_HOME/emulator/emulator"
ADB_CMD="$ANDROID_HOME/platform-tools/adb"

# Check if emulator exists
if [ ! -f "$EMULATOR_CMD" ]; then
    print_msg "$RED" "Error: emulator not found at $EMULATOR_CMD"
    exit 1
fi

# Check if already running
check_emulator_running() {
    $ADB_CMD devices 2>/dev/null | grep -q "emulator-"
}

get_running_emulator() {
    $ADB_CMD devices 2>/dev/null | grep "emulator-" | cut -f1
}

# Print header
echo ""
print_msg "$BLUE" "=============================================="
print_msg "$BLUE" "Android Emulator Startup Script"
print_msg "$BLUE" "=============================================="
echo ""

# Check if emulator is already running
if check_emulator_running; then
    RUNNING=$(get_running_emulator)
    print_msg "$GREEN" "Emulator already running: $RUNNING"

    # Check if it's booted
    BOOT_STATUS=$($ADB_CMD -s $RUNNING shell getprop sys.boot_completed 2>/dev/null || echo "")
    if [ "$BOOT_STATUS" = "1" ]; then
        print_msg "$GREEN" "Emulator is fully booted and ready"
        exit 0
    else
        print_msg "$YELLOW" "Emulator is starting, waiting for boot..."
    fi
else
    # Get list of available emulators
    AVDS=$($EMULATOR_CMD -list-avds 2>/dev/null)

    if [ -z "$AVDS" ]; then
        print_msg "$RED" "Error: No emulators found"
        echo ""
        echo "Create an emulator using Android Studio:"
        echo "  1. Open Android Studio"
        echo "  2. Go to Tools > Device Manager"
        echo "  3. Click 'Create Device'"
        echo "  4. Select a device and system image"
        exit 1
    fi

    # If no emulator specified, use first available
    if [ -z "$EMULATOR_NAME" ]; then
        EMULATOR_NAME=$(echo "$AVDS" | head -n 1)
        print_msg "$YELLOW" "No emulator specified, using: $EMULATOR_NAME"
    fi

    # Verify emulator exists
    if ! echo "$AVDS" | grep -q "^$EMULATOR_NAME$"; then
        print_msg "$RED" "Error: Emulator '$EMULATOR_NAME' not found"
        echo ""
        echo "Available emulators:"
        echo "$AVDS"
        exit 1
    fi

    # Build emulator command
    EMU_CMD="$EMULATOR_CMD -avd $EMULATOR_NAME"

    if [ "$COLD_BOOT" = true ]; then
        EMU_CMD="$EMU_CMD -no-snapshot-load"
    fi

    if [ "$WIPE_DATA" = true ]; then
        EMU_CMD="$EMU_CMD -wipe-data"
    fi

    # Start emulator in background
    print_msg "$BLUE" "Starting emulator: $EMULATOR_NAME"
    $EMU_CMD -no-audio -no-window &
    EMULATOR_PID=$!
    echo $EMULATOR_PID > /tmp/android_emulator.pid

    # Wait for emulator to appear in adb devices
    print_msg "$YELLOW" "Waiting for emulator to start..."
    COUNTER=0
    while ! check_emulator_running; do
        sleep 2
        COUNTER=$((COUNTER + 2))
        if [ $COUNTER -ge 60 ]; then
            print_msg "$RED" "Error: Emulator failed to start within 60 seconds"
            kill $EMULATOR_PID 2>/dev/null || true
            exit 1
        fi
        echo -n "."
    done
    echo ""
    print_msg "$GREEN" "Emulator started"
fi

# Wait for boot completion
if [ "$WAIT_BOOT" = true ]; then
    DEVICE=$(get_running_emulator)
    print_msg "$YELLOW" "Waiting for boot completion (timeout: ${TIMEOUT}s)..."

    COUNTER=0
    while true; do
        BOOT_STATUS=$($ADB_CMD -s $DEVICE shell getprop sys.boot_completed 2>/dev/null || echo "")

        if [ "$BOOT_STATUS" = "1" ]; then
            break
        fi

        sleep 2
        COUNTER=$((COUNTER + 2))

        if [ $COUNTER -ge $TIMEOUT ]; then
            print_msg "$RED" "Error: Boot timeout after ${TIMEOUT} seconds"
            exit 1
        fi

        echo -n "."
    done
    echo ""

    # Additional wait for launcher
    sleep 3

    print_msg "$GREEN" "Emulator is fully booted and ready!"
fi

# Show device info
echo ""
echo "Device Information:"
DEVICE=$(get_running_emulator)
echo "  Device ID: $DEVICE"
echo "  Android Version: $($ADB_CMD -s $DEVICE shell getprop ro.build.version.release 2>/dev/null)"
echo "  SDK Version: $($ADB_CMD -s $DEVICE shell getprop ro.build.version.sdk 2>/dev/null)"
echo ""

# Check if app is installed
APP_PACKAGE="com.sellscribe.app"
if $ADB_CMD -s $DEVICE shell pm list packages 2>/dev/null | grep -q "$APP_PACKAGE"; then
    print_msg "$GREEN" "SellScribe app is installed"
else
    print_msg "$YELLOW" "SellScribe app is not installed"

    # Check if APK exists
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
    APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"

    if [ -f "$APK_PATH" ]; then
        echo "Installing app from: $APK_PATH"
        $ADB_CMD -s $DEVICE install "$APK_PATH"
        print_msg "$GREEN" "App installed successfully"
    else
        echo "APK not found at: $APK_PATH"
        echo "Build the app first: flutter build apk --debug"
    fi
fi

echo ""
print_msg "$GREEN" "Emulator is ready for testing!"
