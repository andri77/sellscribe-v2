"""
Login Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class LoginPage(BasePage):
    """Page object for Login screen"""

    # Actual content-desc values discovered via adb uiautomator dump.
    # Flutter Semantics(label:) does NOT set contentDescription on EditText fields;
    # those are found by EditText index (see BasePage._enter_field_by_index).
    # Buttons use their visible text as content-desc (Flutter merges child Text widgets).
    SIGN_IN_BUTTON_CD = "Sign In"
    SIGN_UP_LINK_CD = "Sign up"
    FORGOT_PASSWORD_LINK = "Forgot password?"
    WELCOME_TEXT = "Welcome back"

    def enter_email(self, email: str):
        """Enter email address (first EditText on screen)"""
        return self._enter_field_by_index(0, email)

    def enter_password(self, password: str):
        """Enter password (second EditText on screen)"""
        return self._enter_field_by_index(1, password)

    def tap_login(self):
        """Tap login button"""
        self.find_by_text(self.SIGN_IN_BUTTON_CD).click()
        return self

    def tap_register_link(self):
        """Tap register/sign up link"""
        self.find_by_text(self.SIGN_UP_LINK_CD).click()
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
        return self.is_text_present(self.WELCOME_TEXT) or self.is_element_present(
            AppiumBy.XPATH,
            f'//*[@content-desc="{self.SIGN_IN_BUTTON_CD}" or @text="{self.SIGN_IN_BUTTON_CD}"]',
            timeout=5
        )

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
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
            if self.is_text_present("Invalid email"):
                return "Invalid email"
            if self.is_text_present("Invalid password"):
                return "Invalid password"
            if self.is_text_present("User not found"):
                return "User not found"
            return ""
        except:
            return ""
