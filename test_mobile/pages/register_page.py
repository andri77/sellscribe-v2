"""
Register Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class RegisterPage(BasePage):
    """Page object for Registration screen"""

    # Actual content-desc values discovered via adb uiautomator dump.
    # EditText fields have empty content-desc; accessed by index (0=name, 1=email,
    # 2=password, 3=confirm password).
    REGISTER_BUTTON_CD = "Create Account"
    SIGN_IN_LINK_CD = "Sign in"

    def enter_name(self, name: str):
        """Enter name (first EditText on screen)"""
        return self._enter_field_by_index(0, name)

    def enter_email(self, email: str):
        """Enter email address (second EditText on screen)"""
        return self._enter_field_by_index(1, email)

    def enter_password(self, password: str):
        """Enter password (third EditText on screen)"""
        return self._enter_field_by_index(2, password)

    def enter_confirm_password(self, password: str):
        """Enter confirm password (fourth EditText on screen)"""
        return self._enter_field_by_index(3, password)

    def tap_register(self):
        """Tap register button"""
        self.find_by_text(self.REGISTER_BUTTON_CD).click()
        return self

    def tap_login_link(self):
        """Tap the 'Sign in' link"""
        self.find_by_text(self.SIGN_IN_LINK_CD).click()
        from .login_page import LoginPage
        return LoginPage(self.driver)

    def register(self, name: str, email: str, password: str):
        """Complete registration flow"""
        self.enter_name(name)
        self.enter_email(email)
        self.enter_password(password)
        self.enter_confirm_password(password)
        self.tap_register()
        return self

    def is_register_screen_displayed(self) -> bool:
        """Check if register screen is displayed"""
        return self.is_any_text_present(
            "Create an account", "Create Account", "Sign Up", timeout=10
        ) or self.is_element_present(
            AppiumBy.XPATH,
            f'//*[@content-desc="{self.REGISTER_BUTTON_CD}" or @text="{self.REGISTER_BUTTON_CD}"]',
            timeout=5
        )

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return self.is_any_text_present(
            "Error", "Invalid", "Email already in use", "already registered",
            "must be", "too short", "required", "Please", "weak", timeout=5
        )
