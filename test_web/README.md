# SellScribe Playwright Test Framework

Automated web testing framework for SellScribe web application using Playwright and pytest with Page Object Model (POM) architecture.

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running Tests](#running-tests)
- [Test Reports](#test-reports)
- [Writing Tests](#writing-tests)
- [Page Objects](#page-objects)
- [CI/CD Integration](#cicd-integration)

## Features

- **Page Object Model (POM)** architecture for maintainable tests
- **Multi-browser support** - Chromium, Firefox, WebKit
- **Parallel test execution** for faster test runs
- **HTML and Allure reports** for test results visualization
- **Screenshot capture** on test failure
- **Video recording** support
- **Configurable timeouts** and retries
- **Marker-based test selection** (smoke, regression, etc.)

## Project Structure

```
Playwright_Scripts/
├── config/
│   ├── __init__.py
│   └── config.py           # Configuration settings
├── pages/
│   ├── __init__.py
│   ├── base_page.py        # Base page with common methods
│   ├── login_page.py       # Login page object
│   ├── register_page.py    # Registration page object
│   ├── home_page.py        # Home/Dashboard page object
│   ├── upload_page.py      # Upload page object
│   ├── history_page.py     # History page object
│   └── settings_page.py    # Settings page object
├── tests/
│   ├── __init__.py
│   ├── conftest.py         # Pytest fixtures
│   ├── test_login.py       # Login test cases
│   ├── test_register.py    # Registration test cases
│   ├── test_home.py        # Home page test cases
│   ├── test_listing.py     # Listing test cases
│   └── test_settings.py    # Settings test cases
├── reports/
│   ├── screenshots/        # Test failure screenshots
│   └── videos/             # Test recordings
├── scripts/
│   ├── install.sh          # Installation script
│   └── run_tests.sh        # Test runner script
├── .env.example            # Environment variables template
├── requirements.txt        # Python dependencies
└── README.md               # This file
```

## Prerequisites

- **Python 3.8+**
- **pip** (Python package manager)
- **Node.js** (for Playwright browsers)

## Installation

### Quick Install

```bash
# Navigate to the Playwright_Scripts directory
cd Playwright_Scripts

# Run the installation script
./scripts/install.sh
```

### Manual Installation

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/Mac
# or
.\venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Install Playwright browsers
playwright install

# Install system dependencies (Linux)
playwright install-deps
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

Key configuration options:

| Variable | Description | Default |
|----------|-------------|---------|
| `BASE_URL` | Application URL | `http://localhost:8080` |
| `TEST_USER_EMAIL` | Test user email | `test@example.com` |
| `TEST_USER_PASSWORD` | Test user password | `Password123!` |
| `BROWSER` | Default browser | `chromium` |
| `HEADLESS` | Run headless mode | `false` |
| `DEFAULT_TIMEOUT` | Element timeout (ms) | `30000` |

## Running Tests

### Using the Test Runner Script

```bash
# Run all tests
./scripts/run_tests.sh

# Run specific test file
./scripts/run_tests.sh --test test_login.py

# Run smoke tests
./scripts/run_tests.sh -m smoke

# Run regression tests
./scripts/run_tests.sh -m regression

# Run on specific browser
./scripts/run_tests.sh --browser firefox
./scripts/run_tests.sh --browser webkit

# Run in headless mode
./scripts/run_tests.sh --headless

# Run with HTML report
./scripts/run_tests.sh --html

# Run with Allure report
./scripts/run_tests.sh --allure

# Run tests in parallel (4 workers)
./scripts/run_tests.sh -n 4

# Retry failed tests
./scripts/run_tests.sh --reruns 2

# Run with custom base URL
./scripts/run_tests.sh --base-url https://staging.sellscribe.com

# Combine options
./scripts/run_tests.sh --headless -m smoke --html --browser chromium
```

### Using pytest Directly

```bash
# Activate virtual environment first
source venv/bin/activate

# Run all tests
pytest tests/ -v

# Run with specific browser
pytest tests/ -v --browser-type=chromium

# Run in headless mode
pytest tests/ -v --headless

# Run specific markers
pytest tests/ -v -m smoke

# Run with HTML report
pytest tests/ -v --html=reports/report.html --self-contained-html

# Run with Allure report
pytest tests/ -v --alluredir=reports/allure-results
```

## Test Reports

### HTML Report

After running tests with `--html` flag, open the report:

```bash
open reports/report_*.html  # Mac
xdg-open reports/report_*.html  # Linux
```

### Allure Report

Generate and view Allure report:

```bash
# Generate report
allure generate reports/allure-results -o reports/allure-report --clean

# Open report
allure open reports/allure-report
```

### Screenshots

Failed test screenshots are saved in `reports/screenshots/` with format:
`{test_name}_{timestamp}.png`

## Writing Tests

### Test Structure

```python
import pytest
from pages import LoginPage, HomePage

@pytest.mark.smoke
@pytest.mark.login
class TestLogin:
    """Test cases for login functionality"""

    def test_login_with_valid_credentials(self, login_page: LoginPage, test_user: dict):
        """Test successful login"""
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(login_page.page, login_page.base_url)
        assert home_page.is_home_screen_displayed(), \
            "Home screen should be displayed"

        # Take screenshot for documentation
        login_page.take_screenshot("test_login_success")
```

### Available Markers

- `@pytest.mark.smoke` - Quick sanity tests
- `@pytest.mark.regression` - Full regression tests
- `@pytest.mark.login` - Login-related tests
- `@pytest.mark.register` - Registration-related tests
- `@pytest.mark.listing` - Listing-related tests
- `@pytest.mark.settings` - Settings-related tests
- `@pytest.mark.profile` - Profile-related tests

### Available Fixtures

- `page` - Playwright page object
- `browser` - Browser instance
- `context` - Browser context
- `login_page` - Login page object (navigated to login)
- `register_page` - Register page object (navigated to register)
- `logged_in_page` - Home page after login
- `test_user` - Test user credentials
- `new_user` - Unique new user data for registration

## Page Objects

### Base Page Methods

```python
# Navigation
page.navigate(url)
page.go_back()

# Element interaction
page.click(selector)
page.fill(selector, text)
page.clear_and_fill(selector, text)
page.select_option(selector, value)

# Verification
page.is_visible(selector)
page.is_text_present(text)
page.get_text(selector)
page.get_attribute(selector, attribute)

# Waits
page.wait_for_element(selector)
page.wait_for_text(text)
page.wait_for_load_state()

# Screenshots
page.take_screenshot(name)

# Assertions
page.expect_visible(selector)
page.expect_text(selector, text)
page.expect_url(url_pattern)
```

### Creating New Page Objects

```python
from pages.base_page import BasePage

class NewPage(BasePage):
    # Selectors
    ELEMENT = "[data-testid='element']"

    def __init__(self, page, base_url=""):
        super().__init__(page)
        self.base_url = base_url

    def is_screen_displayed(self) -> bool:
        return self.is_visible(self.ELEMENT)

    def perform_action(self) -> None:
        self.click(self.ELEMENT)
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Playwright Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          cd Playwright_Scripts
          pip install -r requirements.txt
          playwright install --with-deps chromium

      - name: Run tests
        run: |
          cd Playwright_Scripts
          pytest tests/ -v --headless --html=reports/report.html
        env:
          BASE_URL: ${{ secrets.BASE_URL }}
          TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
          TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}

      - name: Upload report
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-report
          path: Playwright_Scripts/reports/
```

## Troubleshooting

### Common Issues

1. **Playwright not installed**
   ```bash
   pip install playwright
   playwright install
   ```

2. **Browser launch fails**
   ```bash
   playwright install-deps  # Install system dependencies
   ```

3. **Tests timeout**
   - Increase `DEFAULT_TIMEOUT` in `.env`
   - Check network connectivity
   - Verify BASE_URL is correct

4. **Element not found**
   - Verify selector is correct
   - Check if element is in an iframe
   - Add explicit wait before interaction

### Debug Mode

Run tests with debug output:

```bash
./scripts/run_tests.sh --debug
```

Or with pytest directly:

```bash
pytest tests/ -v -s --log-cli-level=DEBUG
```

## License

This project is proprietary to SellScribe.
