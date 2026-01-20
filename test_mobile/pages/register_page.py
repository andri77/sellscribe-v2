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
        self.tap_by_text(self.NAME_FIELD)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(name)
        self.hide_keyboard()
        return self

    def enter_email(self, email: str):
        """Enter email address"""
        self.tap_by_text(self.EMAIL_FIELD)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(email)
        self.hide_keyboard()
        return self

    def enter_password(self, password: str):
        """Enter password"""
        self.tap_by_text(self.PASSWORD_FIELD)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(password)
        self.hide_keyboard()
        return self

    def enter_confirm_password(self, password: str):
        """Enter confirm password"""
        # Scroll down if needed
        self.scroll_down()
        self.tap_by_text(self.CONFIRM_PASSWORD_FIELD)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(password)
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
