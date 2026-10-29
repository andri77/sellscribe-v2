"""
Login Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class LoginPage(BasePage):
    """Page object for Login screen"""

    EMAIL_INPUT_ID = "email-input"
    PASSWORD_INPUT_ID = "password-input"
    SIGN_IN_BUTTON_ID = "sign-in-button"
    SIGN_UP_LINK_ID = "sign-up-link"
    FORGOT_PASSWORD_BUTTON_ID = "forgot-password-button"

    def enter_email(self, email: str):
        """Enter email address"""
        return self.type_into(self.EMAIL_INPUT_ID, email)

    def enter_password(self, password: str):
        """Enter password"""
        return self.type_into(self.PASSWORD_INPUT_ID, password)

    def tap_login(self):
        """Tap the Sign In button"""
        return self.tap(self.by_id(self.SIGN_IN_BUTTON_ID))

    def tap_register_link(self):
        """Tap the 'Sign up' link"""
        self.tap(self.by_id(self.SIGN_UP_LINK_ID))
        from .register_page import RegisterPage
        return RegisterPage(self.driver)

    def tap_register(self):
        """Alias for tap_register_link"""
        return self.tap_register_link()

    def tap_forgot_password(self):
        """Tap the 'Forgot password?' button"""
        return self.tap(self.by_id(self.FORGOT_PASSWORD_BUTTON_ID))

    def login(self, email: str, password: str):
        """Complete login flow"""
        self.enter_email(email)
        self.enter_password(password)
        self.tap_login()
        return self

    def is_login_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if login screen is displayed"""
        return self.is_present(self.by_id(self.SIGN_IN_BUTTON_ID), timeout)

    def is_password_masked(self) -> bool:
        """True if the password field hides its input"""
        self.tap(self.by_id(self.PASSWORD_INPUT_ID))
        return self.driver.switch_to.active_element.get_attribute('password') == 'true'
