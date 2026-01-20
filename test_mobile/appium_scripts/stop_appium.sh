#!/bin/bash

# =============================================================================
# Appium Server Stop Script
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_msg() {
    echo -e "${1}${2}${NC}"
}

# Check for PID file
if [ -f /tmp/appium.pid ]; then
    PID=$(cat /tmp/appium.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        rm /tmp/appium.pid
        print_msg "$GREEN" "Appium server stopped (PID: $PID)"
        exit 0
    else
        rm /tmp/appium.pid
        print_msg "$YELLOW" "PID file exists but process not running"
    fi
fi

# Try to find and kill appium process on default port
PORT=${1:-4723}
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
    kill -9 $PID
    print_msg "$GREEN" "Killed Appium process on port $PORT (PID: $PID)"
else
    print_msg "$YELLOW" "No Appium server found running on port $PORT"
fi

# Also try to find any appium node processes
APPIUM_PIDS=$(pgrep -f "appium" 2>/dev/null || true)
if [ -n "$APPIUM_PIDS" ]; then
    echo "Found other Appium processes:"
    echo "$APPIUM_PIDS"
    read -p "Kill all? (y/n): " KILL_ALL
    if [ "$KILL_ALL" = "y" ] || [ "$KILL_ALL" = "Y" ]; then
        echo "$APPIUM_PIDS" | xargs kill -9
        print_msg "$GREEN" "All Appium processes killed"
    fi
fi
