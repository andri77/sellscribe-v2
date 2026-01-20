#!/bin/bash

# =============================================================================
# Appium Server Start Script for SellScribe Mobile Testing
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

# Set ANDROID_HOME if not set
if [ -z "$ANDROID_HOME" ]; then
    if [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_HOME="$HOME/Library/Android/sdk"
    elif [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
    fi
fi

# Add Android tools to PATH if ANDROID_HOME is set
if [ -n "$ANDROID_HOME" ]; then
    export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/tools/bin"
fi

# Default configuration
PORT=${APPIUM_PORT:-4723}
BASE_PATH="/wd/hub"
LOG_LEVEL=${APPIUM_LOG_LEVEL:-info}
LOG_FILE=""
BACKGROUND=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -l|--log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        -f|--log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        -b|--background)
            BACKGROUND=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -p, --port PORT       Appium server port (default: 4723)"
            echo "  -l, --log-level LEVEL Log level: debug, info, warn, error (default: info)"
            echo "  -f, --log-file FILE   Log to file"
            echo "  -b, --background      Run in background"
            echo "  -h, --help           Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if Appium is installed
if ! command -v appium &> /dev/null; then
    print_msg "$RED" "Error: Appium is not installed"
    print_msg "$YELLOW" "Run: npm install -g appium"
    exit 1
fi

# Check if port is already in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_msg "$YELLOW" "Warning: Port $PORT is already in use"
    read -p "Kill existing process? (y/n): " KILL_PROC
    if [ "$KILL_PROC" = "y" ] || [ "$KILL_PROC" = "Y" ]; then
        PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
        kill -9 $PID
        print_msg "$GREEN" "Killed process $PID"
        sleep 1
    else
        print_msg "$RED" "Cannot start Appium on port $PORT"
        exit 1
    fi
fi

# Build command
CMD="appium --port $PORT --base-path $BASE_PATH --log-level $LOG_LEVEL"

if [ -n "$LOG_FILE" ]; then
    CMD="$CMD --log $LOG_FILE"
fi

# Print startup info
echo ""
print_msg "$BLUE" "=============================================="
print_msg "$BLUE" "Starting Appium Server"
print_msg "$BLUE" "=============================================="
echo ""
echo "Configuration:"
echo "  Port:       $PORT"
echo "  Base Path:  $BASE_PATH"
echo "  Log Level:  $LOG_LEVEL"
if [ -n "$LOG_FILE" ]; then
    echo "  Log File:   $LOG_FILE"
fi
echo ""
print_msg "$GREEN" "Appium server starting at http://localhost:$PORT$BASE_PATH"
echo ""

# Start Appium
if [ "$BACKGROUND" = true ]; then
    print_msg "$YELLOW" "Starting in background mode..."
    nohup $CMD > /dev/null 2>&1 &
    APPIUM_PID=$!
    echo $APPIUM_PID > /tmp/appium.pid
    sleep 2

    # Verify it started
    if ps -p $APPIUM_PID > /dev/null 2>&1; then
        print_msg "$GREEN" "Appium started in background (PID: $APPIUM_PID)"
        echo "To stop: kill $APPIUM_PID"
        echo "Or run: ./stop_appium.sh"
    else
        print_msg "$RED" "Failed to start Appium"
        exit 1
    fi
else
    print_msg "$YELLOW" "Press Ctrl+C to stop the server"
    echo ""
    $CMD
fi
