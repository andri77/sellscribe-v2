#!/bin/bash

#===============================================================================
# SellScribe Mobile Build Script
#
# This script builds the SellScribe Flutter app for iOS and Android.
#
# Usage: ./scripts/build-mobile.sh [platform] [options]
#
# Platforms:
#   ios           Build for iOS
#   android       Build for Android
#   all           Build for both (default)
#
# Options:
#   --release     Build release version
#   --debug       Build debug version (default)
#   --clean       Clean before building
#   --help        Show this help message
#===============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Defaults
PLATFORM="all"
BUILD_TYPE="debug"
DO_CLEAN=false

#-------------------------------------------------------------------------------
# Parse Arguments
#-------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        ios|android|all)
            PLATFORM=$1
            shift
            ;;
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --clean)
            DO_CLEAN=true
            shift
            ;;
        --help)
            echo "SellScribe Mobile Build Script"
            echo ""
            echo "Usage: ./scripts/build-mobile.sh [platform] [options]"
            echo ""
            echo "Platforms:"
            echo "  ios           Build for iOS"
            echo "  android       Build for Android"
            echo "  all           Build for both (default)"
            echo ""
            echo "Options:"
            echo "  --release     Build release version"
            echo "  --debug       Build debug version (default)"
            echo "  --clean       Clean before building"
            echo "  --help        Show this help message"
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

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

#-------------------------------------------------------------------------------
# Build Process
#-------------------------------------------------------------------------------

print_header "SellScribe Mobile Build"

cd "$PROJECT_ROOT"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed!${NC}"
    exit 1
fi

# Clean if requested
if [ "$DO_CLEAN" = true ]; then
    print_info "Cleaning..."
    flutter clean
    flutter pub get
    print_success "Clean complete"
fi

# Get dependencies
print_info "Getting dependencies..."
flutter pub get

# Build Android
if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "all" ]; then
    print_header "Building Android ($BUILD_TYPE)"

    if [ "$BUILD_TYPE" = "release" ]; then
        flutter build apk --release
        print_success "Android APK built: build/app/outputs/flutter-apk/app-release.apk"

        # Also build app bundle for Play Store
        flutter build appbundle --release
        print_success "Android App Bundle built: build/app/outputs/bundle/release/app-release.aab"
    else
        flutter build apk --debug
        print_success "Android APK built: build/app/outputs/flutter-apk/app-debug.apk"
    fi
fi

# Build iOS
if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "all" ]; then
    print_header "Building iOS ($BUILD_TYPE)"

    # Check if on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "iOS builds require macOS. Skipping iOS build."
    else
        if [ "$BUILD_TYPE" = "release" ]; then
            flutter build ios --release --no-codesign
            print_success "iOS build complete (no code signing)"
            print_info "To archive for App Store, open ios/Runner.xcworkspace in Xcode"
        else
            flutter build ios --debug --no-codesign
            print_success "iOS debug build complete"
        fi
    fi
fi

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------

print_header "Build Summary"

echo "Platform:   $PLATFORM"
echo "Build type: $BUILD_TYPE"
echo ""

if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "all" ]; then
    echo "Android outputs:"
    if [ "$BUILD_TYPE" = "release" ]; then
        echo "  - APK: build/app/outputs/flutter-apk/app-release.apk"
        echo "  - AAB: build/app/outputs/bundle/release/app-release.aab"
    else
        echo "  - APK: build/app/outputs/flutter-apk/app-debug.apk"
    fi
    echo ""
fi

if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "all" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "iOS outputs:"
        echo "  - Build: build/ios/iphoneos/Runner.app"
        echo "  - For App Store: Open ios/Runner.xcworkspace in Xcode"
    fi
fi

print_success "Build complete!"
