"""
Base Page Object for SellScribe Mobile App
"""
from appium.webdriver.webdriver import WebDriver
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException

from config.config import Config


class BasePage:
    """Base class for all page objects"""

    def __init__(self, driver: WebDriver):
        self.driver = driver
        self.wait = WebDriverWait(driver, Config.EXPLICIT_WAIT)

    # Element Locator Strategies
    # Flutter uses accessibility labels, text, and semantic identifiers

    def find_element(self, locator_type: str, locator_value: str, timeout: int = None):
        """Find element with explicit wait"""
        wait_time = timeout or Config.EXPLICIT_WAIT
        wait = WebDriverWait(self.driver, wait_time)
        return wait.until(
            EC.presence_of_element_located((locator_type, locator_value))
        )

    def find_elements(self, locator_type: str, locator_value: str, timeout: int = None):
        """Find multiple elements"""
        wait_time = timeout or Config.EXPLICIT_WAIT
        wait = WebDriverWait(self.driver, wait_time)
        return wait.until(
            EC.presence_of_all_elements_located((locator_type, locator_value))
        )

    def find_by_text(self, text: str, exact: bool = True, timeout: int = None):
        """Find element by text content (supports both native text and Flutter content-desc)"""
        if exact:
            # Try content-desc first (Flutter), then text (native)
            locator = f'//*[@content-desc="{text}" or @text="{text}"]'
        else:
            locator = f'//*[contains(@content-desc, "{text}") or contains(@text, "{text}")]'
        return self.find_element(AppiumBy.XPATH, locator, timeout)

    def find_by_accessibility_id(self, accessibility_id: str, timeout: int = None):
        """Find element by accessibility ID (preferred for Flutter)"""
        return self.find_element(
            AppiumBy.ACCESSIBILITY_ID, accessibility_id, timeout
        )

    def find_by_content_desc(self, content_desc: str, timeout: int = None):
        """Find element by content description"""
        return self.find_element(
            AppiumBy.XPATH,
            f'//*[@content-desc="{content_desc}"]',
            timeout
        )

    # Actions

    def tap(self, locator_type: str, locator_value: str, timeout: int = None):
        """Tap on element"""
        element = self.find_element(locator_type, locator_value, timeout)
        element.click()
        return self

    def tap_by_text(self, text: str, timeout: int = None):
        """Tap on element by text"""
        element = self.find_by_text(text, timeout=timeout)
        element.click()
        return self

    def enter_text(self, locator_type: str, locator_value: str, text: str, clear: bool = True):
        """Enter text into input field"""
        element = self.find_element(locator_type, locator_value)
        if clear:
            element.clear()
        element.send_keys(text)
        return self

    def get_text(self, locator_type: str, locator_value: str) -> str:
        """Get text from element"""
        element = self.find_element(locator_type, locator_value)
        return element.text

    def is_element_present(self, locator_type: str, locator_value: str, timeout: int = 5) -> bool:
        """Check if element is present"""
        try:
            self.find_element(locator_type, locator_value, timeout)
            return True
        except (TimeoutException, NoSuchElementException):
            return False

    def is_text_present(self, text: str, timeout: int = 5) -> bool:
        """Check if text is present on screen"""
        try:
            self.find_by_text(text, timeout=timeout)
            return True
        except (TimeoutException, NoSuchElementException):
            return False

    def wait_for_element_visible(self, locator_type: str, locator_value: str, timeout: int = None):
        """Wait for element to be visible"""
        wait_time = timeout or Config.EXPLICIT_WAIT
        wait = WebDriverWait(self.driver, wait_time)
        return wait.until(
            EC.visibility_of_element_located((locator_type, locator_value))
        )

    def wait_for_text(self, text: str, timeout: int = None):
        """Wait for text to appear on screen (supports Flutter content-desc)"""
        wait_time = timeout or Config.EXPLICIT_WAIT
        wait = WebDriverWait(self.driver, wait_time)
        return wait.until(
            EC.presence_of_element_located(
                (AppiumBy.XPATH, f'//*[contains(@content-desc, "{text}") or contains(@text, "{text}")]')
            )
        )

    def scroll_down(self):
        """Scroll down on screen"""
        size = self.driver.get_window_size()
        start_x = size['width'] // 2
        start_y = size['height'] * 0.8
        end_y = size['height'] * 0.2
        self.driver.swipe(start_x, int(start_y), start_x, int(end_y), 800)
        return self

    def scroll_up(self):
        """Scroll up on screen"""
        size = self.driver.get_window_size()
        start_x = size['width'] // 2
        start_y = size['height'] * 0.2
        end_y = size['height'] * 0.8
        self.driver.swipe(start_x, int(start_y), start_x, int(end_y), 800)
        return self

    def scroll_to_text(self, text: str, max_scrolls: int = 5):
        """Scroll until text is found"""
        for _ in range(max_scrolls):
            if self.is_text_present(text, timeout=2):
                return self
            self.scroll_down()
        raise Exception(f"Text '{text}' not found after {max_scrolls} scrolls")

    def pull_to_refresh(self):
        """Pull to refresh gesture"""
        size = self.driver.get_window_size()
        start_x = size['width'] // 2
        start_y = size['height'] * 0.3
        end_y = size['height'] * 0.8
        self.driver.swipe(start_x, int(start_y), start_x, int(end_y), 800)
        return self

    def go_back(self):
        """Press back button"""
        self.driver.back()
        return self

    def hide_keyboard(self):
        """Hide keyboard if visible"""
        try:
            self.driver.hide_keyboard()
        except:
            pass  # Keyboard might not be visible
        return self

    def take_screenshot(self, name: str):
        """Take screenshot"""
        self.driver.save_screenshot(f'screenshots/{name}.png')
        return self

    def get_page_source(self) -> str:
        """Get page source for debugging"""
        return self.driver.page_source
