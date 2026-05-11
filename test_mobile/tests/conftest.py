"""
Pytest Configuration and Fixtures for SellScribe Mobile Testing
"""
import pytest
import os
import sys
from datetime import datetime
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.options.ios import XCUITestOptions

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.config import Config
from pages import (
    LoginPage, RegisterPage, HomePage, SettingsPage,
    ProfileEditPage, UploadPage, HistoryPage,
    PaymentMethodsPage, PurchaseCreditsPage
)


def pytest_addoption(parser):
    """Add custom command line options"""
    parser.addoption(
        "--platform",
        action="store",
        default="android",
        help="Platform to test: android or ios"
    )
    parser.addoption(
        "--device",
        action="store",
        default=None,
        help="Device name or UDID"
    )
    parser.addoption(
        "--app-path",
        action="store",
        default=None,
        help="Path to the app file"
    )


@pytest.fixture(scope="session")
def platform(request):
    """Get platform from command line"""
    return request.config.getoption("--platform").lower()


@pytest.fixture(scope="session")
def device_name(request):
    """Get device name from command line"""
    return request.config.getoption("--device")


@pytest.fixture(scope="session")
def app_path(request):
    """Get app path from command line"""
    return request.config.getoption("--app-path")


@pytest.fixture(scope="function")
def driver(platform, device_name, app_path):
    """
    Create and configure Appium driver for each test.

    This fixture is function-scoped, so each test gets a fresh driver
    for better stability and isolation.
    """
    # Get capabilities based on platform
    if platform == "ios":
        caps = Config.get_ios_capabilities()
        options = XCUITestOptions()
    else:
        caps = Config.get_android_capabilities()
        options = UiAutomator2Options()

    # Override with command line options
    if device_name:
        caps['deviceName'] = device_name
    if app_path:
        caps['app'] = app_path

    # Set capabilities
    for key, value in caps.items():
        if hasattr(options, key):
            setattr(options, key, value)
        else:
            options.set_capability(key, value)

    # Create driver
    driver = webdriver.Remote(
        command_executor=Config.APPIUM_SERVER,
        options=options
    )

    # Set implicit wait
    driver.implicitly_wait(Config.IMPLICIT_WAIT)

    yield driver

    # Teardown
    driver.quit()


def _wait_for_login_screen(driver, timeout=30):
    """Restart app and block until login screen is visible (Welcome back text)."""
    import time
    from pages import LoginPage

    app_id = 'com.sellscribe.app'
    try:
        driver.terminate_app(app_id)
        time.sleep(2)
    except Exception:
        pass
    try:
        driver.activate_app(app_id)
    except Exception:
        pass

    login_page = LoginPage(driver)
    # Splash screen takes 2 s + Supabase network init — wait up to `timeout` s
    try:
        login_page.wait_for_text('Welcome back', timeout=timeout)
    except Exception:
        # Fallback: try waiting for the email field directly
        try:
            from appium.webdriver.common.appiumby import AppiumBy
            from selenium.webdriver.support.ui import WebDriverWait
            from selenium.webdriver.support import expected_conditions as EC
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located(
                    (AppiumBy.ACCESSIBILITY_ID, 'email-input')
                )
            )
        except Exception:
            pass  # Let individual test assertions catch the failure
    return login_page


@pytest.fixture(scope="function")
def reset_app(driver):
    """Reset app state before each test"""
    _wait_for_login_screen(driver)
    yield


@pytest.fixture(scope="function")
def ensure_on_login_screen(driver):
    """
    Ensure we're on the login screen before tests that need it.
    Restarts the app and waits for the login screen to be ready.
    """
    return _wait_for_login_screen(driver)


@pytest.fixture(scope="function")
def login_page(driver):
    """Return LoginPage — waits for login screen to be ready after app launch."""
    return _wait_for_login_screen(driver)


@pytest.fixture(scope="function")
def register_page(driver):
    """Return RegisterPage instance"""
    return RegisterPage(driver)


@pytest.fixture(scope="function")
def home_page(driver):
    """Return HomePage instance"""
    return HomePage(driver)


@pytest.fixture(scope="function")
def settings_page(driver):
    """Return SettingsPage instance"""
    return SettingsPage(driver)


@pytest.fixture(scope="function")
def profile_edit_page(driver):
    """Return ProfileEditPage instance"""
    return ProfileEditPage(driver)


@pytest.fixture(scope="function")
def upload_page(driver):
    """Return UploadPage instance"""
    return UploadPage(driver)


@pytest.fixture(scope="function")
def history_page(driver):
    """Return HistoryPage instance"""
    return HistoryPage(driver)


@pytest.fixture(scope="function")
def payment_methods_page(driver):
    """Return PaymentMethodsPage instance"""
    return PaymentMethodsPage(driver)


@pytest.fixture(scope="function")
def purchase_credits_page(driver):
    """Return PurchaseCreditsPage instance"""
    return PurchaseCreditsPage(driver)


@pytest.fixture(scope="session")
def test_user():
    """Test user credentials from config"""
    return {
        "email": Config.TEST_EMAIL,
        "password": Config.TEST_PASSWORD,
        "name": "Test User"
    }


@pytest.fixture(scope="session")
def new_user():
    """Generate unique user for registration tests"""
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    return {
        "email": f"newuser_{timestamp}@example.com",
        "password": "NewPass123!",
        "name": f"New User {timestamp}"
    }


# Hooks for reporting

def pytest_configure(config):
    """Configure pytest"""
    # Add custom markers
    config.addinivalue_line("markers", "smoke: mark test as smoke test")
    config.addinivalue_line("markers", "regression: mark test as regression test")
    config.addinivalue_line("markers", "login: mark test as login related")
    config.addinivalue_line("markers", "register: mark test as registration related")
    config.addinivalue_line("markers", "listing: mark test as listing related")
    config.addinivalue_line("markers", "settings: mark test as settings related")
    config.addinivalue_line("markers", "profile: mark test as profile related")
    config.addinivalue_line("markers", "payment: mark test as payment related")


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Hook to capture screenshots on test failure"""
    outcome = yield
    report = outcome.get_result()

    if report.when == "call" and report.failed:
        driver = item.funcargs.get("driver")
        if driver:
            try:
                # Create screenshots directory
                screenshot_dir = os.path.join(
                    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                    "reports",
                    "screenshots"
                )
                os.makedirs(screenshot_dir, exist_ok=True)

                # Save screenshot
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                screenshot_path = os.path.join(
                    screenshot_dir,
                    f"{item.name}_{timestamp}.png"
                )
                driver.save_screenshot(screenshot_path)

                # Add screenshot to report
                if hasattr(report, "extra"):
                    report.extra.append(
                        pytest.html.extras.png(screenshot_path)
                    )
            except Exception as e:
                # Silently ignore screenshot failures
                pass
