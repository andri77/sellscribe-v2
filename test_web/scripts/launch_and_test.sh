#!/bin/bash

# =============================================================================
# Launch Web Server and Run Playwright Tests
# =============================================================================
# This script:
# 1. Starts the Flutter web server in the background
# 2. Waits for the server to be available
# 3. Runs all Playwright tests in Chrome (visible browser)
# 4. Generates HTML test report
# 5. Stops the server when done
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_WEB_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$TEST_WEB_DIR")"

# Configuration
PORT=8080
BASE_URL="http://localhost:$PORT"
MAX_WAIT_TIME=120  # Maximum seconds to wait for server
FLUTTER_PID=""

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

cleanup() {
    echo ""
    print_info "Cleaning up..."

    # Kill Flutter process if running
    if [ -n "$FLUTTER_PID" ] && kill -0 "$FLUTTER_PID" 2>/dev/null; then
        print_info "Stopping Flutter web server (PID: $FLUTTER_PID)..."
        kill "$FLUTTER_PID" 2>/dev/null || true
        wait "$FLUTTER_PID" 2>/dev/null || true
        print_success "Flutter web server stopped"
    fi

    # Kill any remaining flutter processes on our port
    lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

wait_for_server() {
    local url="$1"
    local max_wait="$2"
    local waited=0

    print_info "Waiting for server at $url..."

    while [ $waited -lt $max_wait ]; do
        if curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q "200\|302\|301"; then
            return 0
        fi
        sleep 2
        waited=$((waited + 2))
        echo -n "."
    done

    echo ""
    return 1
}

# =============================================================================
# Main Script
# =============================================================================

print_header "SellScribe Test Runner"

# Step 1: Check if server is already running
print_info "Checking if server is already running on port $PORT..."
if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL" 2>/dev/null | grep -q "200\|302\|301"; then
    print_warning "Server already running on port $PORT"
    FLUTTER_PID=""
else
    # Step 2: Start Flutter web server
    print_header "Starting Flutter Web Server"

    cd "$PROJECT_ROOT"

    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed!"
        exit 1
    fi

    # Start Flutter in the background (web-server mode - no browser)
    print_info "Starting Flutter web server on port $PORT..."
    flutter run -d web-server --web-port=$PORT > /tmp/flutter_server.log 2>&1 &
    FLUTTER_PID=$!

    print_info "Flutter server started with PID: $FLUTTER_PID"

    # Wait for server to be available
    if wait_for_server "$BASE_URL" "$MAX_WAIT_TIME"; then
        echo ""
        print_success "Server is ready at $BASE_URL"
    else
        print_error "Server failed to start within $MAX_WAIT_TIME seconds"
        print_info "Check /tmp/flutter_server.log for details"
        exit 1
    fi
fi

# Step 3: Run Playwright tests
print_header "Running Playwright Tests"

cd "$TEST_WEB_DIR"

# Activate virtual environment if exists
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    print_success "Virtual environment activated"
elif [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    print_success "Virtual environment activated"
fi

# Check if playwright is installed
if ! python -c "import playwright" 2>/dev/null; then
    print_error "Playwright is not installed"
    print_info "Installing requirements..."
    pip install -r requirements.txt
    playwright install chromium
fi

# Create reports directory
mkdir -p reports/screenshots
mkdir -p reports/videos

# Generate timestamp for report
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Run tests with Chrome (not headless), generate HTML report
print_info "Running tests in Chrome browser..."
echo ""
echo "Test Configuration:"
echo "  Browser:    chromium"
echo "  Headless:   false"
echo "  Base URL:   $BASE_URL"
echo "  Report:     reports/report_${TIMESTAMP}.html"
echo ""

pytest tests/ -v \
    --browser-type=chromium \
    --base-url="$BASE_URL" \
    --html="reports/report_${TIMESTAMP}.html" \
    --self-contained-html \
    2>&1

TEST_EXIT_CODE=$?

# Step 4: Summary
print_header "Test Summary"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    print_success "All tests passed!"
else
    print_error "Some tests failed (exit code: $TEST_EXIT_CODE)"
fi

echo ""
print_info "HTML Report: $TEST_WEB_DIR/reports/report_${TIMESTAMP}.html"
echo ""

exit $TEST_EXIT_CODE
