#!/bin/bash

# =============================================================================
# Appium Installation Script for SellScribe Mobile Testing
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_msg() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

print_header() {
    echo ""
    print_msg "$BLUE" "=============================================="
    print_msg "$BLUE" "$1"
    print_msg "$BLUE" "=============================================="
    echo ""
}

print_success() {
    print_msg "$GREEN" "✓ $1"
}

print_warning() {
    print_msg "$YELLOW" "⚠ $1"
}

print_error() {
    print_msg "$RED" "✗ $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

OS=$(detect_os)
print_header "Appium Installation Script"
echo "Detected OS: $OS"

# =============================================================================
# Step 1: Check Node.js
# =============================================================================
print_header "Step 1: Checking Node.js"

if command_exists node; then
    NODE_VERSION=$(node --version)
    print_success "Node.js is installed: $NODE_VERSION"
else
    print_warning "Node.js is not installed"
    echo "Installing Node.js..."

    if [ "$OS" = "macos" ]; then
        if command_exists brew; then
            brew install node
        else
            print_error "Homebrew not found. Please install Homebrew first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    elif [ "$OS" = "linux" ]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        print_error "Please install Node.js manually from https://nodejs.org/"
        exit 1
    fi

    print_success "Node.js installed: $(node --version)"
fi

# =============================================================================
# Step 2: Install/Update Appium
# =============================================================================
print_header "Step 2: Installing Appium"

if command_exists appium; then
    CURRENT_VERSION=$(appium --version)
    print_warning "Appium is already installed: $CURRENT_VERSION"
    read -p "Do you want to update Appium? (y/n): " UPDATE_APPIUM
    if [ "$UPDATE_APPIUM" = "y" ] || [ "$UPDATE_APPIUM" = "Y" ]; then
        npm update -g appium
        print_success "Appium updated to: $(appium --version)"
    fi
else
    npm install -g appium
    print_success "Appium installed: $(appium --version)"
fi

# =============================================================================
# Step 3: Install Appium Drivers
# =============================================================================
print_header "Step 3: Installing Appium Drivers"

# Install UiAutomator2 driver for Android
echo "Installing UiAutomator2 driver (Android)..."
if appium driver list --installed 2>/dev/null | grep -q "uiautomator2"; then
    print_warning "UiAutomator2 driver already installed"
else
    appium driver install uiautomator2
    print_success "UiAutomator2 driver installed"
fi

# Install XCUITest driver for iOS (macOS only)
if [ "$OS" = "macos" ]; then
    echo "Installing XCUITest driver (iOS)..."
    if appium driver list --installed 2>/dev/null | grep -q "xcuitest"; then
        print_warning "XCUITest driver already installed"
    else
        appium driver install xcuitest
        print_success "XCUITest driver installed"
    fi
else
    print_warning "Skipping iOS driver (not on macOS)"
fi

echo ""
echo "Installed drivers:"
appium driver list --installed

# =============================================================================
# Step 4: Install Appium Doctor
# =============================================================================
print_header "Step 4: Installing Appium Doctor"

if command_exists appium-doctor; then
    print_warning "Appium Doctor already installed"
else
    npm install -g @appium/doctor
    print_success "Appium Doctor installed"
fi

# =============================================================================
# Step 5: Check Android SDK
# =============================================================================
print_header "Step 5: Checking Android SDK"

if [ -n "$ANDROID_HOME" ]; then
    print_success "ANDROID_HOME is set: $ANDROID_HOME"
else
    print_warning "ANDROID_HOME is not set"

    # Try to find Android SDK
    if [ "$OS" = "macos" ]; then
        POSSIBLE_PATH="$HOME/Library/Android/sdk"
    else
        POSSIBLE_PATH="$HOME/Android/Sdk"
    fi

    if [ -d "$POSSIBLE_PATH" ]; then
        print_warning "Found Android SDK at: $POSSIBLE_PATH"
        echo ""
        echo "Add these lines to your shell profile (~/.bashrc or ~/.zshrc):"
        echo ""
        echo "  export ANDROID_HOME=$POSSIBLE_PATH"
        echo "  export PATH=\$PATH:\$ANDROID_HOME/emulator"
        echo "  export PATH=\$PATH:\$ANDROID_HOME/platform-tools"
        echo "  export PATH=\$PATH:\$ANDROID_HOME/tools"
        echo "  export PATH=\$PATH:\$ANDROID_HOME/tools/bin"
    else
        print_error "Android SDK not found. Please install Android Studio."
    fi
fi

if command_exists adb; then
    print_success "ADB is available: $(adb --version | head -n 1)"
else
    print_warning "ADB not found in PATH"
fi

# =============================================================================
# Step 6: Setup Python Virtual Environment
# =============================================================================
print_header "Step 6: Setting up Python Environment"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(dirname "$SCRIPT_DIR")"

cd "$TEST_DIR"

if [ -d "venv" ]; then
    print_warning "Virtual environment already exists"
else
    echo "Creating Python virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
fi

echo "Activating virtual environment..."
source venv/bin/activate

echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r appium_scripts/requirements.txt
print_success "Python dependencies installed"

# =============================================================================
# Step 7: Verify Setup
# =============================================================================
print_header "Step 7: Verifying Setup"

echo "Running Appium Doctor (Android)..."
appium-doctor --android || true

if [ "$OS" = "macos" ]; then
    echo ""
    echo "Running Appium Doctor (iOS)..."
    appium-doctor --ios || true
fi

# =============================================================================
# Summary
# =============================================================================
print_header "Installation Complete!"

echo "Summary:"
echo "  - Node.js: $(node --version)"
echo "  - npm: $(npm --version)"
echo "  - Appium: $(appium --version)"
echo ""
echo "Next steps:"
echo "  1. Ensure ANDROID_HOME is set in your shell profile"
echo "  2. Start an Android emulator or connect a device"
echo "  3. Install the SellScribe APK:"
echo "     adb install build/app/outputs/flutter-apk/app-profile.apk"
echo "  4. Start Appium server:"
echo "     ./appium_scripts/start_appium.sh"
echo "  5. Run tests:"
echo "     ./appium_scripts/run_tests.sh"
echo ""
print_success "Setup completed successfully!"
