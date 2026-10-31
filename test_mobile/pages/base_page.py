"""
Base Page Object for SellScribe Mobile App

Elements are located only by their semantic test IDs (see AGENTS.md), never by
XPath, display text or position:

- by_id(test_id): Flutter's Semantics(identifier:), which becomes the Android
  resource-id (iOS: accessibilityIdentifier). Every semantic ID in the app sets it.
- by_tooltip(name): an IconButton tooltip ('Back', 'profile-menu'), exposed as the
  accessibility id (content-desc).
"""
from appium.webdriver.webdriver import WebDriver
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException

from config.config import Config


class BasePage:
    """Base class for all page objects"""

    BACK_BUTTON = "Back"  # AppBar back button tooltip

    def __init__(self, driver: WebDriver):
        self.driver = driver

    # Locators

    def by_id(self, test_id: str):
        """Locator for a Semantics(identifier:) test ID"""
        if self.driver.capabilities.get('platformName', '').lower() == 'ios':
            return AppiumBy.ACCESSIBILITY_ID, test_id
        # UiAutomator2's plain ID strategy prefixes the app package ("<pkg>:id/..."),
        # which Flutter's raw resource-ids don't have, so match the resource-id exactly
        return AppiumBy.ANDROID_UIAUTOMATOR, f'new UiSelector().resourceId("{test_id}")'

    def by_tooltip(self, tooltip: str):
        """Locator for an IconButton / PopupMenuButton tooltip"""
        return AppiumBy.ACCESSIBILITY_ID, tooltip

    # Finding

    def find(self, locator, timeout: int = None):
        """Wait for an element to be present and return it"""
        return WebDriverWait(self.driver, timeout or Config.EXPLICIT_WAIT).until(
            EC.presence_of_element_located(locator)
        )

    def find_all(self, locator):
        """All matching elements, without waiting (empty list when none)"""
        return self.driver.find_elements(*locator)

    def is_present(self, locator, timeout: int = 5) -> bool:
        """True if the element appears within `timeout` seconds"""
        try:
            self.find(locator, timeout)
            return True
        except (TimeoutException, NoSuchElementException):
            return False

    def is_gone(self, locator, timeout: int = 5) -> bool:
        """True if the element is absent, or disappears within `timeout` seconds"""
        try:
            WebDriverWait(self.driver, timeout).until(
                lambda d: not d.find_elements(*locator)
            )
            return True
        except TimeoutException:
            return False

    def wait_until_settled(self, locator, timeout: int = 10):
        """Wait until the element stops moving, e.g. a bottom sheet finishing its slide.

        A tap during the animation uses the element's old position and can land on the
        scrim behind a sheet, which closes it.
        """
        import time
        previous = None
        end = time.time() + timeout
        while time.time() < end:
            rect = self.find(locator, timeout).rect
            if rect == previous:
                return self
            previous = rect
            time.sleep(0.3)
        return self

    # Actions

    def tap(self, locator, timeout: int = None):
        """Tap an element once it is present"""
        self.find(locator, timeout).click()
        return self

    def tap_back(self):
        """Tap the AppBar back button"""
        return self.tap(self.by_tooltip(self.BACK_BUTTON))

    def type_into(self, test_id: str, value: str):
        """Type into the text field with this test ID.

        The ID sits on Flutter's Semantics wrapper, so tap it to focus the real input
        underneath, then type into the focused (active) element.

        Doesn't hide the keyboard afterwards: the test emulator uses a hardware
        keyboard, and Appium "hides" a keyboard it believes is showing by pressing Back,
        which closed bottom sheets and even left the app.
        """
        import time
        self.tap(self.by_id(test_id))
        time.sleep(0.3)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(value)
        return self

    def read_text(self, test_id: str) -> str:
        """Visible text of the element with this test ID"""
        element = self.find(self.by_id(test_id))
        return element.get_attribute('content-desc') or element.text or ''

    def hide_keyboard(self):
        """Hide the soft keyboard if it is showing.

        Caution: Appium does this by pressing Back, so if it misjudges the keyboard as
        showing it closes sheets or leaves the screen.
        """
        try:
            if self.driver.is_keyboard_shown():
                self.driver.hide_keyboard()
        except Exception:
            pass  # No soft keyboard (e.g. emulator with hardware keyboard)
        return self

    def scroll_down(self):
        """Scroll down on screen"""
        size = self.driver.get_window_size()
        x = size['width'] // 2
        self.driver.swipe(x, int(size['height'] * 0.8), x, int(size['height'] * 0.2), 800)
        return self

    def scroll_to(self, locator, max_scrolls: int = 5):
        """Scroll down until the element is present"""
        for _ in range(max_scrolls):
            if self.is_present(locator, timeout=2):
                return self
            self.scroll_down()
        raise NoSuchElementException(f"{locator[1]} not found after {max_scrolls} scrolls")

    def take_screenshot(self, name: str):
        """Take screenshot"""
        self.driver.save_screenshot(f'screenshots/{name}.png')
        return self
