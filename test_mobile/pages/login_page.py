"""
Login Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class LoginPage(BasePage):
    """Page object for Login screen"""

    # Locators - Using content-desc for Flutter accessibility labels
    EMAIL_FIELD = "Email"
    EMAIL_HINT = "Enter your email"
    PASSWORD_FIELD = "Password"
    PASSWORD_HINT = "Enter your password"
    LOGIN_BUTTON = "Sign In"
    REGISTER_LINK = "Sign up"
    FORGOT_PASSWORD_LINK = "Forgot password?"
    ERROR_MESSAGE = "error"
    WELCOME_TEXT = "Welcome back"

    def enter_email(self, email: str):
        """Enter email address"""
        from appium.webdriver.common.appiumby import AppiumBy
        # Find EditText by hint
        email_field = self.find_element(
            AppiumBy.XPATH,
            f'//android.widget.EditText[contains(@hint, "email")]'
        )
        email_field.clear()
        email_field.send_keys(email)
        self.hide_keyboard()
        return self

    def enter_password(self, password: str):
        """Enter password"""
        from appium.webdriver.common.appiumby import AppiumBy
        # Find EditText by hint
        password_field = self.find_element(
            AppiumBy.XPATH,
            f'//android.widget.EditText[contains(@hint, "password")]'
        )
        password_field.clear()
        password_field.send_keys(password)
        self.hide_keyboard()
        return self

    def tap_login(self):
        """Tap login button"""
        self.tap_by_text(self.LOGIN_BUTTON)
        return self

    def tap_register_link(self):
        """Tap register/sign up link"""
        self.tap_by_text(self.REGISTER_LINK)
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
