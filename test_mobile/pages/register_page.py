"""
Register Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class RegisterPage(BasePage):
    """Page object for Registration screen"""

    # Locators
    NAME_FIELD = "Name"
    EMAIL_FIELD = "Email"
    PASSWORD_FIELD = "Password"
    CONFIRM_PASSWORD_FIELD = "Confirm Password"
    REGISTER_BUTTON = "Create Account"
    LOGIN_LINK = "Sign In"

    def enter_name(self, name: str):
        """Enter name"""
        import time
        # Find EditText by hint - "Enter your name"
        name_field = self.find_element(
            AppiumBy.XPATH,
            '//android.widget.EditText[contains(@hint, "your name")]'
        )
        name_field.click()
        time.sleep(0.3)
        name_field.send_keys(name)
        time.sleep(0.3)
        self.hide_keyboard()
        return self

    def enter_email(self, email: str):
        """Enter email address"""
        import time
        # Find EditText by hint - "Enter your email"
        email_field = self.find_element(
            AppiumBy.XPATH,
            '//android.widget.EditText[contains(@hint, "your email")]'
        )
        email_field.click()
        time.sleep(0.3)
        email_field.send_keys(email)
        time.sleep(0.3)
        self.hide_keyboard()
        return self

    def enter_password(self, password: str):
        """Enter password"""
        import time
        # Find EditText by hint - "Create a password"
        password_field = self.find_element(
            AppiumBy.XPATH,
            '//android.widget.EditText[contains(@hint, "Create a password")]'
        )
        password_field.click()
        time.sleep(0.3)
        password_field.send_keys(password)
        time.sleep(0.3)
        self.hide_keyboard()
        return self

    def enter_confirm_password(self, password: str):
        """Enter confirm password"""
        import time
        # Find EditText by hint - "Confirm your password"
        confirm_field = self.find_element(
            AppiumBy.XPATH,
            '//android.widget.EditText[contains(@hint, "Confirm your password")]'
        )
        confirm_field.click()
        time.sleep(0.3)
        confirm_field.send_keys(password)
        time.sleep(0.3)
        self.hide_keyboard()
        return self

    def tap_register(self):
        """Tap register button"""
        self.tap_by_text(self.REGISTER_BUTTON)
        return self

    def tap_login_link(self):
        """Tap login link"""
        self.tap_by_text(self.LOGIN_LINK)
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
        return self.is_text_present(self.REGISTER_BUTTON)

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return self.is_text_present("Error") or self.is_text_present("Invalid")
