#!/bin/bash

# =============================================================================
# Installation Script for SellScribe Playwright Tests
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

print_msg "$BLUE" "=============================================="
print_msg "$BLUE" "SellScribe Playwright Test Setup"
print_msg "$BLUE" "=============================================="
echo ""

cd "$PROJECT_DIR"

# Check Python version
print_msg "$BLUE" "Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    print_msg "$RED" "Error: Python 3.8 or higher is required"
    print_msg "$YELLOW" "Current version: $PYTHON_VERSION"
    exit 1
fi
print_msg "$GREEN" "Python version: $PYTHON_VERSION ✓"

# Create virtual environment
print_msg "$BLUE" "Creating virtual environment..."
if [ -d "venv" ]; then
    print_msg "$YELLOW" "Virtual environment already exists"
else
    python3 -m venv venv
    print_msg "$GREEN" "Virtual environment created ✓"
fi

# Activate virtual environment
source venv/bin/activate
print_msg "$GREEN" "Virtual environment activated ✓"

# Upgrade pip
print_msg "$BLUE" "Upgrading pip..."
pip install --upgrade pip -q

# Install dependencies
print_msg "$BLUE" "Installing dependencies..."
pip install -r requirements.txt -q
print_msg "$GREEN" "Dependencies installed ✓"

# Install Playwright browsers
print_msg "$BLUE" "Installing Playwright browsers..."
playwright install
print_msg "$GREEN" "Playwright browsers installed ✓"

# Install system dependencies (optional)
print_msg "$BLUE" "Installing Playwright system dependencies..."
playwright install-deps 2>/dev/null || true
print_msg "$GREEN" "System dependencies installed ✓"

# Create .env file if not exists
if [ ! -f ".env" ]; then
    print_msg "$BLUE" "Creating .env file from template..."
    cp .env.example .env
    print_msg "$GREEN" ".env file created ✓"
    print_msg "$YELLOW" "Please update .env with your configuration"
fi

# Create reports directories
mkdir -p reports/screenshots
mkdir -p reports/videos
mkdir -p reports/allure-results

# Make scripts executable
chmod +x scripts/*.sh

echo ""
print_msg "$BLUE" "=============================================="
print_msg "$GREEN" "Installation Complete!"
print_msg "$BLUE" "=============================================="
echo ""
echo "Next steps:"
echo "  1. Update .env with your SellScribe web app URL"
echo "  2. Activate the virtual environment:"
echo "     source venv/bin/activate"
echo "  3. Run tests:"
echo "     ./scripts/run_tests.sh"
echo ""
echo "Quick commands:"
echo "  Run all tests:    ./scripts/run_tests.sh"
echo "  Run smoke tests:  ./scripts/run_tests.sh -m smoke"
echo "  Run with report:  ./scripts/run_tests.sh --html"
echo "  Run headless:     ./scripts/run_tests.sh --headless"
echo ""
