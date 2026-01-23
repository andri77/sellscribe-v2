#!/bin/bash

# =============================================================================
# Launch Web Server and Run Playwright Tests
# =============================================================================
# This script:
# 1. Starts the Flutter web server in the background
# 2. Waits for the server to be available
# 3. Runs Playwright tests (headless by default)
# 4. Generates HTML test report
# 5. Stops the server when done
#
# Usage:
#   ./scripts/launch_and_test.sh [options]
#
# Options:
#   --headless      Run tests in headless mode (default)
#   --headed        Run tests with visible browser
#   --smoke         Run only smoke tests
#   --test FILE     Run specific test file (e.g., test_login.py)
#   --keep-server   Don't stop server after tests
#   --help          Show this help message
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

# Configuration defaults
PORT=8080
BASE_URL="http://localhost:$PORT"
MAX_WAIT_TIME=120
FLUTTER_PID=""
HEADLESS="true"
TEST_MARKER=""
TEST_FILE="tests/"
KEEP_SERVER="false"

# Test credentials (can be overridden by .env)
export TEST_USER_EMAIL="${TEST_USER_EMAIL:-keilor.downs.pic@gmail.com}"
export TEST_USER_PASSWORD="${TEST_USER_PASSWORD:-Set12345}"

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --headless)
            HEADLESS="true"
            shift
            ;;
        --headed)
            HEADLESS="false"
            shift
            ;;
        --smoke)
            TEST_MARKER="-m smoke"
            shift
            ;;
        --test)
            TEST_FILE="tests/$2"
            shift 2
            ;;
        --keep-server)
            KEEP_SERVER="true"
            shift
            ;;
        --help)
            echo "SellScribe Test Runner"
            echo ""
            echo "Usage: ./scripts/launch_and_test.sh [options]"
            echo ""
            echo "Options:"
            echo "  --headless      Run tests in headless mode (default)"
            echo "  --headed        Run tests with visible browser"
            echo "  --smoke         Run only smoke tests"
            echo "  --test FILE     Run specific test file (e.g., test_login.py)"
            echo "  --keep-server   Don't stop server after tests"
            echo "  --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./scripts/launch_and_test.sh                    # Run all tests headless"
            echo "  ./scripts/launch_and_test.sh --headed           # Run with visible browser"
            echo "  ./scripts/launch_and_test.sh --test test_login.py  # Run login tests only"
            echo "  ./scripts/launch_and_test.sh --smoke --headed   # Run smoke tests with browser"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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

    if [ "$KEEP_SERVER" = "true" ]; then
        print_info "Keeping server running (--keep-server flag)"
        return
    fi

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

# Load .env file if exists
if [ -f "$TEST_WEB_DIR/.env" ]; then
    # Parse .env file, ignoring comments and empty lines
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        # Remove inline comments and trim whitespace
        value="${value%%#*}"
        value="${value%"${value##*[![:space:]]}"}"
        key="${key%"${key##*[![:space:]]}"}"
        # Export if key is valid
        if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            export "$key=$value"
        fi
    done < "$TEST_WEB_DIR/.env"
    print_success "Loaded configuration from .env"
fi

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

# Build pytest command
PYTEST_ARGS="-v"
PYTEST_ARGS="$PYTEST_ARGS --browser-type=chromium"
PYTEST_ARGS="$PYTEST_ARGS --base-url=$BASE_URL"
PYTEST_ARGS="$PYTEST_ARGS --html=reports/report_${TIMESTAMP}.html"
PYTEST_ARGS="$PYTEST_ARGS --self-contained-html"

if [ "$HEADLESS" = "true" ]; then
    PYTEST_ARGS="$PYTEST_ARGS --headless"
fi

if [ -n "$TEST_MARKER" ]; then
    PYTEST_ARGS="$PYTEST_ARGS $TEST_MARKER"
fi

# Display test configuration
echo ""
echo "Test Configuration:"
echo "  Browser:      chromium"
echo "  Headless:     $HEADLESS"
echo "  Base URL:     $BASE_URL"
echo "  Test File:    $TEST_FILE"
echo "  Test User:    $TEST_USER_EMAIL"
echo "  Report:       reports/report_${TIMESTAMP}.html"
if [ -n "$TEST_MARKER" ]; then
    echo "  Marker:       $TEST_MARKER"
fi
echo ""

# Run tests
print_info "Running tests..."
echo ""

pytest $TEST_FILE $PYTEST_ARGS 2>&1

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
