"""
Base Page Object - Common functionality for all pages
"""
from playwright.sync_api import Page, expect
from typing import Optional
import os
from datetime import datetime


class BasePage:
    """Base class for all page objects"""

    def __init__(self, page: Page):
        self.page = page
        self.timeout = 10000  # 10 seconds default timeout

    def navigate(self, url: str) -> None:
        """Navigate to a URL"""
        self.page.goto(url)

    def get_title(self) -> str:
        """Get page title"""
        return self.page.title()

    def get_url(self) -> str:
        """Get current URL"""
        return self.page.url

    # Element interaction methods
    def click(self, selector: str, timeout: Optional[int] = None) -> None:
        """Click an element"""
        self.page.click(selector, timeout=timeout or self.timeout)

    def fill(self, selector: str, text: str, timeout: Optional[int] = None) -> None:
        """Fill text into an input field"""
        self.page.fill(selector, text, timeout=timeout or self.timeout)

    def type_text(self, selector: str, text: str, delay: int = 50) -> None:
        """Type text with delay between keystrokes"""
        self.page.type(selector, text, delay=delay)

    def clear_and_fill(self, selector: str, text: str) -> None:
        """Clear field and fill with new text"""
        self.page.fill(selector, "")
        self.page.fill(selector, text)

    def get_text(self, selector: str) -> str:
        """Get text content of an element"""
        return self.page.text_content(selector) or ""

    def get_input_value(self, selector: str) -> str:
        """Get value of an input field"""
        return self.page.input_value(selector)

    def get_attribute(self, selector: str, attribute: str) -> Optional[str]:
        """Get attribute value of an element"""
        return self.page.get_attribute(selector, attribute)

    # Visibility and state checks
    def is_visible(self, selector: str, timeout: Optional[int] = None) -> bool:
        """Check if element is visible"""
        try:
            self.page.wait_for_selector(
                selector,
                state="visible",
                timeout=timeout or self.timeout
            )
            return True
        except:
            return False

    def is_hidden(self, selector: str) -> bool:
        """Check if element is hidden"""
        return not self.is_visible(selector, timeout=1000)

    def is_enabled(self, selector: str) -> bool:
        """Check if element is enabled"""
        return self.page.is_enabled(selector)

    def is_checked(self, selector: str) -> bool:
        """Check if checkbox/radio is checked"""
        return self.page.is_checked(selector)

    # Wait methods
    def wait_for_element(
        self,
        selector: str,
        state: str = "visible",
        timeout: Optional[int] = None
    ) -> None:
        """Wait for element to be in specified state"""
        self.page.wait_for_selector(
            selector,
            state=state,
            timeout=timeout or self.timeout
        )

    def wait_for_url(self, url_pattern: str, timeout: Optional[int] = None) -> None:
        """Wait for URL to match pattern"""
        self.page.wait_for_url(url_pattern, timeout=timeout or self.timeout)

    def wait_for_load_state(self, state: str = "networkidle") -> None:
        """Wait for page load state"""
        self.page.wait_for_load_state(state)

    def wait_for_text(self, text: str, timeout: Optional[int] = None) -> bool:
        """Wait for text to appear on page"""
        try:
            self.page.wait_for_selector(
                f"text={text}",
                timeout=timeout or self.timeout
            )
            return True
        except:
            return False

    # Text search methods
    def is_text_present(self, text: str, timeout: int = 3000) -> bool:
        """Check if text is present on page"""
        try:
            self.page.wait_for_selector(
                f"text={text}",
                timeout=timeout
            )
            return True
        except:
            return False

    def click_text(self, text: str) -> None:
        """Click element containing text"""
        self.page.click(f"text={text}")

    def get_by_text(self, text: str, exact: bool = False):
        """Get element by text content"""
        return self.page.get_by_text(text, exact=exact)

    def get_by_role(self, role: str, **kwargs):
        """Get element by ARIA role"""
        return self.page.get_by_role(role, **kwargs)

    def get_by_label(self, label: str):
        """Get element by label"""
        return self.page.get_by_label(label)

    def get_by_placeholder(self, placeholder: str):
        """Get element by placeholder"""
        return self.page.get_by_placeholder(placeholder)

    def get_by_test_id(self, test_id: str):
        """Get element by data-testid"""
        return self.page.get_by_test_id(test_id)

    # Screenshot and debugging
    def take_screenshot(self, name: str, full_page: bool = False) -> str:
        """Take a screenshot"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{name}_{timestamp}.png"

        # Get reports directory path
        reports_dir = os.path.join(
            os.path.dirname(os.path.dirname(__file__)),
            "reports",
            "screenshots"
        )
        os.makedirs(reports_dir, exist_ok=True)

        filepath = os.path.join(reports_dir, filename)
        self.page.screenshot(path=filepath, full_page=full_page)
        return filepath

    # Form helpers
    def select_option(self, selector: str, value: str) -> None:
        """Select option from dropdown"""
        self.page.select_option(selector, value)

    def check(self, selector: str) -> None:
        """Check a checkbox"""
        self.page.check(selector)

    def uncheck(self, selector: str) -> None:
        """Uncheck a checkbox"""
        self.page.uncheck(selector)

    # Keyboard actions
    def press_key(self, key: str) -> None:
        """Press a keyboard key"""
        self.page.keyboard.press(key)

    def press_enter(self) -> None:
        """Press Enter key"""
        self.press_key("Enter")

    def press_escape(self) -> None:
        """Press Escape key"""
        self.press_key("Escape")

    def press_tab(self) -> None:
        """Press Tab key"""
        self.press_key("Tab")

    # Mouse actions
    def hover(self, selector: str) -> None:
        """Hover over element"""
        self.page.hover(selector)

    def double_click(self, selector: str) -> None:
        """Double click element"""
        self.page.dblclick(selector)

    def right_click(self, selector: str) -> None:
        """Right click element"""
        self.page.click(selector, button="right")

    # Scroll actions
    def scroll_to_element(self, selector: str) -> None:
        """Scroll element into view"""
        self.page.locator(selector).scroll_into_view_if_needed()

    def scroll_to_bottom(self) -> None:
        """Scroll to bottom of page"""
        self.page.evaluate("window.scrollTo(0, document.body.scrollHeight)")

    def scroll_to_top(self) -> None:
        """Scroll to top of page"""
        self.page.evaluate("window.scrollTo(0, 0)")

    # Frame handling
    def switch_to_frame(self, selector: str):
        """Switch to iframe"""
        return self.page.frame_locator(selector)

    # Alert handling
    def accept_alert(self) -> None:
        """Accept browser alert"""
        self.page.on("dialog", lambda dialog: dialog.accept())

    def dismiss_alert(self) -> None:
        """Dismiss browser alert"""
        self.page.on("dialog", lambda dialog: dialog.dismiss())

    # Assertions using expect
    def expect_visible(self, selector: str) -> None:
        """Assert element is visible"""
        expect(self.page.locator(selector)).to_be_visible()

    def expect_hidden(self, selector: str) -> None:
        """Assert element is hidden"""
        expect(self.page.locator(selector)).to_be_hidden()

    def expect_text(self, selector: str, text: str) -> None:
        """Assert element contains text"""
        expect(self.page.locator(selector)).to_contain_text(text)

    def expect_value(self, selector: str, value: str) -> None:
        """Assert input has value"""
        expect(self.page.locator(selector)).to_have_value(value)

    def expect_url(self, url_pattern: str) -> None:
        """Assert URL matches pattern"""
        expect(self.page).to_have_url(url_pattern)

    def expect_title(self, title: str) -> None:
        """Assert page title"""
        expect(self.page).to_have_title(title)
