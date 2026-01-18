#!/bin/bash

#===============================================================================
# SellScribe Startup Script
# 
# This script starts the SellScribe Flutter web development server.
# It validates the environment and launches the application.
#
# Usage: ./scripts/start.sh [options]
#
# Options:
#   --port PORT     Specify port number (default: 8080)
#   --release       Run in release mode
#   --no-browser    Don't open browser automatically
#   --help          Show this help message
#===============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default options
PORT=8080
MODE="debug"
OPEN_BROWSER=true

#-------------------------------------------------------------------------------
# Parse Arguments
#-------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --port)
            PORT="$2"
            shift 2
            ;;
        --release)
            MODE="release"
            shift
            ;;
        --no-browser)
            OPEN_BROWSER=false
            shift
            ;;
        --help)
            echo "SellScribe Startup Script"
            echo ""
            echo "Usage: ./scripts/start.sh [options]"
            echo ""
            echo "Options:"
            echo "  --port PORT     Specify port number (default: 8080)"
            echo "  --release       Run in release mode"
            echo "  --no-browser    Don't open browser automatically"
            echo "  --help          Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

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

#-------------------------------------------------------------------------------
# Startup
#-------------------------------------------------------------------------------

print_header "SellScribe Development Server"

cd "$PROJECT_ROOT"

#-------------------------------------------------------------------------------
# Step 1: Validate Environment
#-------------------------------------------------------------------------------

print_info "Validating environment..."

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed!"
    echo "Run ./scripts/install.sh first"
    exit 1
fi
print_success "Flutter found"

# Check .env file
if [ ! -f ".env" ]; then
    print_warning ".env file not found"
    echo ""
    echo "Creating .env from template..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success "Created .env file"
    else
        print_error "No .env.example found"
        exit 1
    fi
fi

# Check Supabase configuration
SUPABASE_URL=$(grep -E "^SUPABASE_URL=" .env | cut -d '=' -f2)
SUPABASE_KEY=$(grep -E "^SUPABASE_ANON_KEY=" .env | cut -d '=' -f2)

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
    print_warning "Supabase credentials not configured in .env"
    echo ""
    echo "The app will run but authentication and database features won't work."
    echo "Edit .env and add your Supabase credentials."
    echo ""
else
    print_success "Supabase configuration found"
fi

# Check OpenAI configuration
OPENAI_KEY=$(grep -E "^OPENAI_API_KEY=" .env | cut -d '=' -f2)

if [ -z "$OPENAI_KEY" ]; then
    print_warning "OpenAI API key not configured"
    echo "  App will run in MOCK MODE with sample AI responses"
else
    print_success "OpenAI API key configured"
fi

#-------------------------------------------------------------------------------
# Step 2: Check Dependencies
#-------------------------------------------------------------------------------

print_info "Checking dependencies..."

# Check if pubspec.lock exists and is up to date
if [ ! -f "pubspec.lock" ] || [ "pubspec.yaml" -nt "pubspec.lock" ]; then
    print_info "Running flutter pub get..."
    flutter pub get
fi

print_success "Dependencies ready"

#-------------------------------------------------------------------------------
# Step 3: Start Development Server
#-------------------------------------------------------------------------------

print_header "Starting Development Server"

echo -e "Mode:    ${CYAN}$MODE${NC}"
echo -e "Port:    ${CYAN}$PORT${NC}"
echo -e "URL:     ${CYAN}http://localhost:$PORT${NC}"
echo ""

# Build Flutter run command
FLUTTER_CMD="flutter run -d chrome --web-port=$PORT"

if [ "$MODE" = "release" ]; then
    FLUTTER_CMD="$FLUTTER_CMD --release"
fi

print_info "Starting Flutter web server..."
echo ""
echo -e "${YELLOW}Press 'r' to hot reload, 'R' to hot restart, 'q' to quit${NC}"
echo ""

# Run Flutter
$FLUTTER_CMD
