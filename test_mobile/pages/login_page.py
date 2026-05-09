"""
Login Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class LoginPage(BasePage):
    """Page object for Login screen"""

    # Locators - ACCESSIBILITY_ID maps to Semantics(label:) in Flutter source
    EMAIL_FIELD_ID = "email-input"
    PASSWORD_FIELD_ID = "password-input"
    SIGN_IN_BUTTON_ID = "sign-in-button"
    SIGN_UP_LINK_ID = "sign-up-link"
    FORGOT_PASSWORD_LINK = "Forgot password?"
    ERROR_MESSAGE = "error"
    WELCOME_TEXT = "Welcome back"

    def _enter_field_by_id(self, accessibility_id: str, value: str):
        """Focus a field via its semantic ID, then type into the active element."""
        import time
        self.find_by_accessibility_id(accessibility_id).click()
        time.sleep(0.3)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(value)
        self.hide_keyboard()
        return self

    def enter_email(self, email: str):
        """Enter email address"""
        return self._enter_field_by_id(self.EMAIL_FIELD_ID, email)

    def enter_password(self, password: str):
        """Enter password"""
        return self._enter_field_by_id(self.PASSWORD_FIELD_ID, password)

    def tap_login(self):
        """Tap login button"""
        self.find_by_accessibility_id(self.SIGN_IN_BUTTON_ID).click()
        return self

    def tap_register_link(self):
        """Tap register/sign up link"""
        self.find_by_accessibility_id(self.SIGN_UP_LINK_ID).click()
        from .register_page import RegisterPage
        return RegisterPage(self.driver)

    def tap_register(self):
        """Alias for tap_register_link"""
        return self.tap_register_link()

    def tap_forgot_password(self):
        """Tap forgot password link"""
        self.tap_by_text(self.FORGOT_PASSWORD_LINK)
        return self

    def login(self, email: str, password: str):
        """Complete login flow"""
        self.enter_email(email)
        self.enter_password(password)
        self.tap_login()
        return self

    def is_login_screen_displayed(self) -> bool:
        """Check if login screen is displayed"""
        return self.is_text_present(self.WELCOME_TEXT) or self.is_text_present(self.LOGIN_BUTTON)

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        # Check for various error message patterns
        error_patterns = [
            "Invalid",
            "Error",
            "incorrect",
            "failed",
            "Please enter",
            "wrong",
            "not found"
        ]
        for pattern in error_patterns:
            if self.is_text_present(pattern, timeout=3):
                return True
        return False

    def get_error_message(self) -> str:
        """Get error message text"""
        try:
            # Look for common error indicators
            if self.is_text_present("Invalid email"):
                return "Invalid email"
            if self.is_text_present("Invalid password"):
                return "Invalid password"
            if self.is_text_present("User not found"):
                return "User not found"
            return ""
        except:
            return ""
