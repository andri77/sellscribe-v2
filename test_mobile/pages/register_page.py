"""
Register Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class RegisterPage(BasePage):
    """Page object for Registration screen"""

    NAME_INPUT_ID = "name-input"
    EMAIL_INPUT_ID = "email-input"
    PASSWORD_INPUT_ID = "password-create-input"
    CONFIRM_PASSWORD_INPUT_ID = "password-confirm-input"
    CREATE_ACCOUNT_BUTTON_ID = "create-account-button"
    SIGN_IN_LINK_ID = "sign-in-link"

    def enter_name(self, name: str):
        """Enter name"""
        return self.type_into(self.NAME_INPUT_ID, name)

    def enter_email(self, email: str):
        """Enter email address"""
        return self.type_into(self.EMAIL_INPUT_ID, email)

    def enter_password(self, password: str):
        """Enter password"""
        return self.type_into(self.PASSWORD_INPUT_ID, password)

    def enter_confirm_password(self, password: str):
        """Enter confirm password"""
        return self.type_into(self.CONFIRM_PASSWORD_INPUT_ID, password)

    def tap_register(self):
        """Tap the Create Account button"""
        return self.tap(self.by_id(self.CREATE_ACCOUNT_BUTTON_ID))

    def tap_login_link(self):
        """Tap the 'Sign in' link"""
        self.tap(self.by_id(self.SIGN_IN_LINK_ID))
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

    def is_register_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if register screen is displayed"""
        return self.is_present(self.by_id(self.CREATE_ACCOUNT_BUTTON_ID), timeout)
