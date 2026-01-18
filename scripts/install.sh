#!/bin/bash

#===============================================================================
# SellScribe Installation Script
# 
# This script installs all required dependencies for the SellScribe application.
# It handles Flutter SDK detection, dependency installation, and environment setup.
#
# Usage: ./scripts/install.sh
#===============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}============================================================${NC}"
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

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Main Installation
#-------------------------------------------------------------------------------

print_header "SellScribe Installation"

echo "Project directory: $PROJECT_ROOT"
echo ""

#-------------------------------------------------------------------------------
# Step 1: Check Operating System
#-------------------------------------------------------------------------------

print_info "Detecting operating system..."

OS="unknown"
case "$(uname -s)" in
    Darwin*)    OS="macos";;
    Linux*)     OS="linux";;
    MINGW*|MSYS*|CYGWIN*) OS="windows";;
esac

print_success "Operating system: $OS"

#-------------------------------------------------------------------------------
# Step 2: Check for Flutter
#-------------------------------------------------------------------------------

print_header "Checking Flutter Installation"

if check_command flutter; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_success "Flutter is installed: $FLUTTER_VERSION"
else
    print_error "Flutter is not installed!"
    echo ""
    echo "Please install Flutter from: https://docs.flutter.dev/get-started/install"
    echo ""
    echo "Quick install options:"
    echo ""
    
    if [ "$OS" = "macos" ]; then
        echo "  Using Homebrew:"
        echo "    brew install --cask flutter"
        echo ""
        echo "  Or download from:"
        echo "    https://docs.flutter.dev/get-started/install/macos"
    elif [ "$OS" = "linux" ]; then
        echo "  Using Snap:"
        echo "    sudo snap install flutter --classic"
        echo ""
        echo "  Or download from:"
        echo "    https://docs.flutter.dev/get-started/install/linux"
    else
        echo "  Download from:"
        echo "    https://docs.flutter.dev/get-started/install/windows"
    fi
    
    echo ""
    echo "After installation, run this script again."
    exit 1
fi

#-------------------------------------------------------------------------------
# Step 3: Check Flutter Web Support
#-------------------------------------------------------------------------------

print_info "Checking Flutter web support..."

if flutter devices 2>/dev/null | grep -q "Chrome\|chrome\|Web"; then
    print_success "Flutter web support is enabled"
else
    print_warning "Enabling Flutter web support..."
    flutter config --enable-web
    print_success "Flutter web support enabled"
fi

#-------------------------------------------------------------------------------
# Step 4: Run Flutter Doctor
#-------------------------------------------------------------------------------

print_header "Running Flutter Doctor"

flutter doctor -v

echo ""
print_info "Note: You only need Chrome/Edge for web development."
print_info "Android/iOS toolchains are optional for this project."

#-------------------------------------------------------------------------------
# Step 5: Install Flutter Dependencies
#-------------------------------------------------------------------------------

print_header "Installing Flutter Dependencies"

cd "$PROJECT_ROOT"

print_info "Running 'flutter pub get'..."
flutter pub get

print_success "Flutter dependencies installed"

#-------------------------------------------------------------------------------
# Step 6: Setup Environment File
#-------------------------------------------------------------------------------

print_header "Setting Up Environment"

ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

if [ -f "$ENV_FILE" ]; then
    print_warning ".env file already exists"
    echo ""
    read -p "Do you want to overwrite it? (y/N): " overwrite
    if [ "$overwrite" = "y" ] || [ "$overwrite" = "Y" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        print_success "Created new .env file from template"
    else
        print_info "Keeping existing .env file"
    fi
else
    if [ -f "$ENV_EXAMPLE" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        print_success "Created .env file from template"
    else
        # Create .env file manually
        cat > "$ENV_FILE" << 'ENVEOF'
# Supabase Configuration
# Get these from your Supabase project settings
SUPABASE_URL=
SUPABASE_ANON_KEY=

# OpenAI Configuration (optional - leave empty for mock mode)
OPENAI_API_KEY=
ENVEOF
        print_success "Created .env file"
    fi
fi

#-------------------------------------------------------------------------------
# Step 7: Check for Optional Tools
#-------------------------------------------------------------------------------

print_header "Checking Optional Tools"

# Check for Supabase CLI
if check_command supabase; then
    SUPABASE_VERSION=$(supabase --version 2>/dev/null || echo "unknown")
    print_success "Supabase CLI: $SUPABASE_VERSION"
else
    print_warning "Supabase CLI not installed (optional)"
    echo "  Install with: npm install -g supabase"
fi

# Check for Node.js (needed for some deployment tools)
if check_command node; then
    NODE_VERSION=$(node --version)
    print_success "Node.js: $NODE_VERSION"
else
    print_warning "Node.js not installed (optional, needed for deployment tools)"
fi

# Check for Chrome
if [ "$OS" = "macos" ]; then
    if [ -d "/Applications/Google Chrome.app" ]; then
        print_success "Google Chrome is installed"
    else
        print_warning "Google Chrome not found (recommended for development)"
    fi
fi

#-------------------------------------------------------------------------------
# Step 8: Verify Project Structure
#-------------------------------------------------------------------------------

print_header "Verifying Project Structure"

required_files=(
    "lib/main.dart"
    "lib/config/app_config.dart"
    "lib/config/routes.dart"
    "lib/config/theme.dart"
    "pubspec.yaml"
    "web/index.html"
)

all_present=true
for file in "${required_files[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        print_success "$file"
    else
        print_error "Missing: $file"
        all_present=false
    fi
done

if [ "$all_present" = false ]; then
    print_error "Some required files are missing!"
    exit 1
fi

#-------------------------------------------------------------------------------
# Installation Complete
#-------------------------------------------------------------------------------

print_header "Installation Complete!"

echo -e "Next steps:"
echo ""
echo -e "  ${BLUE}1.${NC} Configure Supabase:"
echo "     - Create a project at https://supabase.com"
echo "     - Copy your project URL and anon key"
echo "     - Edit .env and add your credentials"
echo ""
echo -e "  ${BLUE}2.${NC} Set up the database:"
echo "     - Open Supabase SQL Editor"
echo "     - Run supabase/migrations/001_initial_schema.sql"
echo "     - Run supabase/migrations/002_storage_bucket.sql"
echo ""
echo -e "  ${BLUE}3.${NC} Start the application:"
echo "     ./scripts/start.sh"
echo ""
echo -e "  ${BLUE}4.${NC} (Optional) Add OpenAI API key for real AI generation:"
echo "     - Get key from https://platform.openai.com/api-keys"
echo "     - Add to .env file"
echo ""
echo -e "${GREEN}For detailed instructions, see INSTRUCTIONS.md${NC}"
echo ""
