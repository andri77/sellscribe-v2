#!/bin/bash

#===============================================================================
# SellScribe Build Script
# 
# This script builds the SellScribe Flutter web application for production.
# Output is placed in build/web/ directory.
#
# Usage: ./scripts/build.sh [options]
#
# Options:
#   --clean         Clean build before building
#   --analyze       Run flutter analyze before building
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

# Options
DO_CLEAN=false
DO_ANALYZE=false

#-------------------------------------------------------------------------------
# Parse Arguments
#-------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            DO_CLEAN=true
            shift
            ;;
        --analyze)
            DO_ANALYZE=true
            shift
            ;;
        --help)
            echo "SellScribe Build Script"
            echo ""
            echo "Usage: ./scripts/build.sh [options]"
            echo ""
            echo "Options:"
            echo "  --clean         Clean build before building"
            echo "  --analyze       Run flutter analyze before building"
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
# Build Process
#-------------------------------------------------------------------------------

print_header "SellScribe Production Build"

cd "$PROJECT_ROOT"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed!"
    exit 1
fi

#-------------------------------------------------------------------------------
# Step 1: Clean (Optional)
#-------------------------------------------------------------------------------

if [ "$DO_CLEAN" = true ]; then
    print_info "Cleaning previous build..."
    flutter clean
    flutter pub get
    print_success "Clean complete"
fi

#-------------------------------------------------------------------------------
# Step 2: Analyze (Optional)
#-------------------------------------------------------------------------------

if [ "$DO_ANALYZE" = true ]; then
    print_info "Running Flutter analyze..."
    if flutter analyze; then
        print_success "Analysis passed"
    else
        print_warning "Analysis found issues (continuing anyway)"
    fi
fi

#-------------------------------------------------------------------------------
# Step 3: Check Environment
#-------------------------------------------------------------------------------

print_info "Checking environment..."

if [ ! -f ".env" ]; then
    print_warning ".env file not found - build may have missing configurations"
fi

#-------------------------------------------------------------------------------
# Step 4: Build
#-------------------------------------------------------------------------------

print_info "Building for web (release mode)..."
echo ""

flutter build web --release

print_success "Build complete!"

#-------------------------------------------------------------------------------
# Step 5: Build Summary
#-------------------------------------------------------------------------------

print_header "Build Summary"

BUILD_DIR="$PROJECT_ROOT/build/web"

if [ -d "$BUILD_DIR" ]; then
    # Calculate build size
    BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
    FILE_COUNT=$(find "$BUILD_DIR" -type f | wc -l | tr -d ' ')
    
    echo -e "Output directory: ${CYAN}$BUILD_DIR${NC}"
    echo -e "Total size:       ${CYAN}$BUILD_SIZE${NC}"
    echo -e "File count:       ${CYAN}$FILE_COUNT files${NC}"
    echo ""
    
    echo "Main files:"
    ls -lh "$BUILD_DIR"/*.html "$BUILD_DIR"/*.js 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    
    print_success "Build ready for deployment"
else
    print_error "Build directory not found"
    exit 1
fi

#-------------------------------------------------------------------------------
# Deployment Instructions
#-------------------------------------------------------------------------------

echo ""
echo -e "${BLUE}Deployment Options:${NC}"
echo ""
echo "  Vercel:"
echo "    cd build/web && vercel"
echo ""
echo "  Firebase:"
echo "    firebase deploy --only hosting"
echo ""
echo "  Manual:"
echo "    Upload contents of build/web/ to your web server"
echo ""
