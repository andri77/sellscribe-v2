#!/bin/bash

# =============================================================================
# Test Runner Script for SellScribe Playwright Tests
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
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
BROWSER="chromium"
TEST_FILE=""
MARKERS=""
PARALLEL=""
HTML_REPORT=false
ALLURE_REPORT=false
VERBOSE="-v"
RERUNS=0
HEADLESS=false
BASE_URL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --browser)
            BROWSER="$2"
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
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --browser BROWSER    Browser to use: chromium, firefox, webkit (default: chromium)"
            echo "  --test FILE          Run specific test file"
            echo "  -m, --markers MARK   Run tests with specific markers (e.g., smoke, regression)"
            echo "  -n, --parallel N     Run N tests in parallel"
            echo "  --html               Generate HTML report"
            echo "  --allure             Generate Allure report"
            echo "  --reruns N           Retry failed tests N times"
            echo "  -q, --quiet          Quiet output"
            echo "  --debug              Enable debug logging"
            echo "  --headless           Run browser in headless mode"
            echo "  --base-url URL       Base URL for the application"
            echo "  -h, --help           Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                              # Run all tests"
            echo "  $0 --test test_login.py        # Run specific test"
            echo "  $0 -m smoke                     # Run smoke tests"
            echo "  $0 --browser firefox            # Run on Firefox"
            echo "  $0 -n 4 --html                  # Run 4 tests parallel with HTML report"
            echo "  $0 --headless -m smoke          # Run headless smoke tests"
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
print_msg "$BLUE" "SellScribe Playwright Test Runner"
print_msg "$BLUE" "=============================================="
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Activate virtual environment if exists
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    print_msg "$GREEN" "Virtual environment activated"
elif [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    print_msg "$GREEN" "Virtual environment activated"
fi

# Check if playwright is installed
if ! python -c "import playwright" 2>/dev/null; then
    print_msg "$RED" "Error: Playwright is not installed"
    print_msg "$YELLOW" "Run: pip install -r requirements.txt && playwright install"
    exit 1
fi

# Create reports directory
mkdir -p reports/screenshots
mkdir -p reports/videos

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

# Add browser type
PYTEST_CMD="$PYTEST_CMD --browser-type=$BROWSER"

# Add headless flag
if [ "$HEADLESS" = true ]; then
    PYTEST_CMD="$PYTEST_CMD --headless"
fi

# Add base URL
if [ -n "$BASE_URL" ]; then
    PYTEST_CMD="$PYTEST_CMD --base-url=$BASE_URL"
fi

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
echo "  Browser:    $BROWSER"
echo "  Test File:  ${TEST_FILE:-all tests}"
echo "  Markers:    ${MARKERS:-none}"
echo "  Parallel:   ${PARALLEL:-no}"
echo "  Headless:   $HEADLESS"
echo "  Reruns:     $RERUNS"
echo "  HTML:       $HTML_REPORT"
echo "  Allure:     $ALLURE_REPORT"
if [ -n "$BASE_URL" ]; then
    echo "  Base URL:   $BASE_URL"
fi
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
