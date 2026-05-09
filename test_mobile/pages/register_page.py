"""
Register Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class RegisterPage(BasePage):
    """Page object for Registration screen"""

    # Locators - ACCESSIBILITY_ID maps to Semantics(label:) in Flutter source
    NAME_FIELD_ID = "name-input"
    EMAIL_FIELD_ID = "email-input"
    PASSWORD_FIELD_ID = "password-create-input"
    CONFIRM_PASSWORD_FIELD_ID = "password-confirm-input"
    REGISTER_BUTTON_ID = "create-account-button"
    SIGN_IN_LINK_ID = "sign-in-link"

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

    def enter_name(self, name: str):
        """Enter name"""
        return self._enter_field_by_id(self.NAME_FIELD_ID, name)

    def enter_email(self, email: str):
        """Enter email address"""
        return self._enter_field_by_id(self.EMAIL_FIELD_ID, email)

    def enter_password(self, password: str):
        """Enter password"""
        return self._enter_field_by_id(self.PASSWORD_FIELD_ID, password)

    def enter_confirm_password(self, password: str):
        """Enter confirm password"""
        return self._enter_field_by_id(self.CONFIRM_PASSWORD_FIELD_ID, password)

    def tap_register(self):
        """Tap register button"""
        self.find_by_accessibility_id(self.REGISTER_BUTTON_ID).click()
        return self

    def tap_login_link(self):
        """Tap the 'Sign in' link"""
        self.find_by_accessibility_id(self.SIGN_IN_LINK_ID).click()
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
        return self.is_any_text_present(
            "Error", "Invalid", "Email already in use", "already registered",
            "must be", "too short", "required", "Please", "weak", timeout=5
        )
