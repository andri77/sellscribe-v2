"""
Pytest Configuration and Fixtures for Playwright Tests
"""
import pytest
from playwright.sync_api import sync_playwright, Browser, BrowserContext, Page
from typing import Generator
import os
import sys
from datetime import datetime
import urllib.request
import urllib.error

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pages import LoginPage, RegisterPage, HomePage
from config.config import Config


def enable_flutter_accessibility(page) -> None:
    """
    Enable Flutter web accessibility mode.

    Flutter web renders to canvas by default and doesn't expose DOM elements.
    This function clicks the accessibility placeholder to enable the semantic tree,
    which exposes ARIA elements that Playwright can interact with.
    """
    try:
        placeholder = page.query_selector("flt-semantics-placeholder")
        if placeholder:
            page.evaluate('''() => {
                const elem = document.querySelector("flt-semantics-placeholder");
                if (elem) {
                    elem.focus();
                    elem.click();
                }
            }''')
            # Wait for Flutter to render the semantic tree
            page.wait_for_timeout(1000)
    except Exception:
        pass  # Accessibility may already be enabled


def is_server_available(url: str, timeout: int = 5) -> bool:
    """Check if the server is available"""
    try:
        urllib.request.urlopen(url, timeout=timeout)
        return True
    except (urllib.error.URLError, urllib.error.HTTPError, OSError):
        return False


# Global flag to track server availability
_server_available = None


def get_server_status(base_url: str) -> bool:
    """Get cached server status"""
    global _server_available
    if _server_available is None:
        _server_available = is_server_available(base_url)
    return _server_available


def pytest_addoption(parser):
    """Add custom command line options"""
    parser.addoption(
        "--browser-type",
        action="store",
        default="chromium",
        help="Browser to run tests: chromium, firefox, webkit"
    )
    parser.addoption(
        "--headless",
        action="store_true",
        default=False,
        help="Run browser in headless mode"
    )
    parser.addoption(
        "--slow-mo",
        action="store",
        default=0,
        type=int,
        help="Slow down execution by specified milliseconds"
    )
    # Note: --base-url is already provided by pytest-playwright plugin


@pytest.fixture(scope="session")
def browser_type(request) -> str:
    """Get browser type from command line"""
    return request.config.getoption("--browser-type")


@pytest.fixture(scope="session")
def headless(request) -> bool:
    """Get headless mode from command line"""
    return request.config.getoption("--headless")


@pytest.fixture(scope="session")
def slow_mo(request) -> int:
    """Get slow motion delay from command line"""
    return request.config.getoption("--slow-mo")


@pytest.fixture(scope="session")
def base_url(request) -> str:
    """Get base URL from command line or config"""
    # Try to get from pytest-playwright's --base-url option
    try:
        url = request.config.getoption("--base-url")
        if url:
            return url
    except ValueError:
        pass
    return Config.BASE_URL


@pytest.fixture(scope="session", autouse=True)
def check_server_availability(base_url: str):
    """Check if server is available and skip all tests if not"""
    if not get_server_status(base_url):
        pytest.skip(
            f"Server not available at {base_url}. "
            "Start the web application or provide a valid --base-url",
            allow_module_level=True
        )


@pytest.fixture(scope="session")
def playwright_instance():
    """Create playwright instance for the session"""
    with sync_playwright() as playwright:
        yield playwright


@pytest.fixture(scope="session")
def browser(
    playwright_instance,
    browser_type: str,
    headless: bool,
    slow_mo: int
) -> Generator[Browser, None, None]:
    """Create browser instance"""
    browser_launcher = getattr(playwright_instance, browser_type)

    browser = browser_launcher.launch(
        headless=headless,
        slow_mo=slow_mo,
        args=["--start-maximized"] if not headless else []
    )

    yield browser
    browser.close()


@pytest.fixture(scope="function")
def context(browser: Browser) -> Generator[BrowserContext, None, None]:
    """Create browser context for each test"""
    context = browser.new_context(
        viewport={"width": 1920, "height": 1080},
        ignore_https_errors=True,
        record_video_dir="reports/videos" if Config.RECORD_VIDEO else None
    )

    # Set default timeout
    context.set_default_timeout(Config.DEFAULT_TIMEOUT)

    yield context
    context.close()


@pytest.fixture(scope="function")
def page(context: BrowserContext, base_url: str) -> Generator[Page, None, None]:
    """Create page for each test with Flutter accessibility enabled"""
    page = context.new_page()
    # Navigate to base URL to enable Flutter accessibility
    page.goto(base_url)
    page.wait_for_load_state("networkidle")
    page.wait_for_timeout(2000)  # Wait for Flutter to fully render
    enable_flutter_accessibility(page)
    yield page
    page.close()


@pytest.fixture(scope="function")
def login_page(page: Page, base_url: str) -> LoginPage:
    """Provide login page object"""
    login = LoginPage(page, base_url)
    login.navigate_to_login()
    return login


@pytest.fixture(scope="function")
def register_page(page: Page, base_url: str) -> RegisterPage:
    """Provide register page object"""
    register = RegisterPage(page, base_url)
    register.navigate_to_register()
    return register


@pytest.fixture(scope="function")
def logged_in_page(page: Page, base_url: str, test_user: dict) -> HomePage:
    """Provide logged-in home page"""
    login = LoginPage(page, base_url)
    login.navigate_to_login()
    login.login(test_user["email"], test_user["password"])
    home = HomePage(page, base_url)
    return home


@pytest.fixture(scope="session")
def test_user() -> dict:
    """Provide test user credentials"""
    return {
        "email": Config.TEST_USER_EMAIL,
        "password": Config.TEST_USER_PASSWORD,
        "name": Config.TEST_USER_NAME
    }


@pytest.fixture(scope="function")
def new_user() -> dict:
    """Provide unique new user data for registration tests"""
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    return {
        "email": f"test_{timestamp}@example.com",
        "password": "TestPass123!",
        "name": f"Test User {timestamp}",
        "first_name": "Test",
        "last_name": f"User{timestamp}"
    }


# Hooks for screenshots on failure
@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Take screenshot on test failure"""
    outcome = yield
    rep = outcome.get_result()

    if rep.when == "call" and rep.failed:
        try:
            page = item.funcargs.get("page")
            if page:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                screenshot_dir = os.path.join(
                    os.path.dirname(os.path.dirname(__file__)),
                    "reports",
                    "screenshots"
                )
                os.makedirs(screenshot_dir, exist_ok=True)

                test_name = item.name.replace("[", "_").replace("]", "_")
                screenshot_path = os.path.join(
                    screenshot_dir,
                    f"{test_name}_{timestamp}.png"
                )
                page.screenshot(path=screenshot_path, full_page=True)
                print(f"\nScreenshot saved: {screenshot_path}")
        except Exception as e:
            print(f"\nFailed to take screenshot: {e}")


def pytest_configure(config):
    """Configure pytest markers"""
    config.addinivalue_line("markers", "smoke: mark test as smoke test")
    config.addinivalue_line("markers", "regression: mark test as regression test")
    config.addinivalue_line("markers", "login: mark test as login related")
    config.addinivalue_line("markers", "register: mark test as registration related")
    config.addinivalue_line("markers", "listing: mark test as listing related")
    config.addinivalue_line("markers", "settings: mark test as settings related")
    config.addinivalue_line("markers", "profile: mark test as profile related")
