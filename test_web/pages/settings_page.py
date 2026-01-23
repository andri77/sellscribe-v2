"""
Settings Page Object for SellScribe Web Application
"""
from playwright.sync_api import Page
from .base_page import BasePage


class SettingsPage(BasePage):
    """Page object for Settings screen"""

    # Selectors
    PROFILE_SECTION = "[data-testid='profile-section'], .profile-section, section:has-text('Profile')"
    EDIT_PROFILE_BUTTON = "[data-testid='edit-profile'], button:has-text('Edit Profile'), a:has-text('Edit Profile')"
    THEME_SECTION = "[data-testid='theme-section'], .theme-section, section:has-text('Theme')"
    THEME_LIGHT = "[data-testid='theme-light'], input[value='light'], button:has-text('Light')"
    THEME_DARK = "[data-testid='theme-dark'], input[value='dark'], button:has-text('Dark')"
    THEME_SYSTEM = "[data-testid='theme-system'], input[value='system'], button:has-text('System')"
    PAYMENT_METHODS = "[data-testid='payment-methods'], button:has-text('Payment'), a:has-text('Payment')"
    PURCHASE_CREDITS = "[data-testid='purchase-credits'], button:has-text('Purchase'), a:has-text('Buy Credits')"
    SIGN_OUT_BUTTON = "[data-testid='sign-out'], button:has-text('Sign Out'), button:has-text('Logout')"
    BACK_BUTTON = "[data-testid='back-button'], button:has-text('Back'), a:has-text('Back'), [aria-label='Back']"

    # Profile Edit Fields
    FIRST_NAME_INPUT = "[data-testid='first-name'], input[name='firstName'], input[placeholder*='first name' i]"
    LAST_NAME_INPUT = "[data-testid='last-name'], input[name='lastName'], input[placeholder*='last name' i]"
    EMAIL_INPUT = "[data-testid='email-input'], input[type='email'], input[name='email']"
    PHONE_INPUT = "[data-testid='phone-input'], input[type='tel'], input[name='phone'], input[name='mobile']"
    ADDRESS_INPUT = "[data-testid='address-input'], input[name='address'], textarea[name='address']"
    SAVE_BUTTON = "[data-testid='save-button'], button:has-text('Save'), button[type='submit']"
    CANCEL_BUTTON = "[data-testid='cancel-button'], button:has-text('Cancel')"

    # Confirmation Dialog
    CONFIRM_SIGN_OUT = "[data-testid='confirm-signout'], button:has-text('Confirm'), button:has-text('Yes')"
    CANCEL_SIGN_OUT = "[data-testid='cancel-signout'], button:has-text('Cancel'), button:has-text('No')"

    SUCCESS_MESSAGE = "[data-testid='success-message'], .success, .alert-success, [role='alert']:has-text('success')"
    ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']:has-text('error')"

    def __init__(self, page: Page, base_url: str = ""):
        super().__init__(page)
        self.base_url = base_url
        self.settings_url = f"{base_url}/settings" if base_url else "/settings"

    def navigate_to_settings(self) -> "SettingsPage":
        """Navigate to settings page"""
        self.navigate(self.settings_url)
        self.wait_for_load_state()
        return self

    def is_settings_screen_displayed(self) -> bool:
        """Check if settings screen is displayed"""
        return (
            self.is_text_present("Settings", timeout=5000) or
            self.is_visible(self.PROFILE_SECTION, timeout=3000) or
            self.is_visible(self.THEME_SECTION, timeout=3000)
        )

    def click_edit_profile(self) -> "SettingsPage":
        """Click edit profile button"""
        self.click(self.EDIT_PROFILE_BUTTON)
        self.wait_for_load_state()
        return self

    def is_profile_edit_displayed(self) -> bool:
        """Check if profile edit form is displayed"""
        return (
            self.is_visible(self.FIRST_NAME_INPUT, timeout=3000) or
            self.is_visible(self.LAST_NAME_INPUT, timeout=3000)
        )

    def enter_first_name(self, name: str) -> "SettingsPage":
        """Enter first name"""
        self.clear_and_fill(self.FIRST_NAME_INPUT, name)
        return self

    def enter_last_name(self, name: str) -> "SettingsPage":
        """Enter last name"""
        self.clear_and_fill(self.LAST_NAME_INPUT, name)
        return self

    def enter_phone(self, phone: str) -> "SettingsPage":
        """Enter phone number"""
        if self.is_visible(self.PHONE_INPUT, timeout=2000):
            self.clear_and_fill(self.PHONE_INPUT, phone)
        return self

    def enter_address(self, address: str) -> "SettingsPage":
        """Enter address"""
        if self.is_visible(self.ADDRESS_INPUT, timeout=2000):
            self.clear_and_fill(self.ADDRESS_INPUT, address)
        return self

    def save_profile(self) -> "SettingsPage":
        """Save profile changes"""
        self.click(self.SAVE_BUTTON)
        self.wait_for_load_state()
        return self

    def cancel_edit(self) -> "SettingsPage":
        """Cancel profile edit"""
        if self.is_visible(self.CANCEL_BUTTON, timeout=2000):
            self.click(self.CANCEL_BUTTON)
            self.wait_for_load_state()
        return self

    def set_theme(self, theme: str) -> "SettingsPage":
        """Set application theme (light, dark, system)"""
        theme_selectors = {
            "light": self.THEME_LIGHT,
            "dark": self.THEME_DARK,
            "system": self.THEME_SYSTEM
        }
        selector = theme_selectors.get(theme.lower())
        if selector and self.is_visible(selector, timeout=3000):
            self.click(selector)
            self.wait_for_load_state()
        return self

    def set_light_theme(self) -> "SettingsPage":
        """Set light theme"""
        return self.set_theme("light")

    def set_dark_theme(self) -> "SettingsPage":
        """Set dark theme"""
        return self.set_theme("dark")

    def set_system_theme(self) -> "SettingsPage":
        """Set system theme"""
        return self.set_theme("system")

    def click_payment_methods(self) -> None:
        """Navigate to payment methods"""
        self.click(self.PAYMENT_METHODS)
        self.wait_for_load_state()

    def click_purchase_credits(self) -> None:
        """Navigate to purchase credits"""
        self.click(self.PURCHASE_CREDITS)
        self.wait_for_load_state()

    def click_sign_out(self) -> "SettingsPage":
        """Click sign out button"""
        self.scroll_to_element(self.SIGN_OUT_BUTTON)
        self.click(self.SIGN_OUT_BUTTON)
        return self

    def confirm_sign_out(self) -> "LoginPage":
        """Confirm sign out action"""
        if self.is_visible(self.CONFIRM_SIGN_OUT, timeout=3000):
            self.click(self.CONFIRM_SIGN_OUT)
        self.wait_for_load_state()
        from .login_page import LoginPage
        return LoginPage(self.page, self.base_url)

    def cancel_sign_out(self) -> "SettingsPage":
        """Cancel sign out action"""
        if self.is_visible(self.CANCEL_SIGN_OUT, timeout=3000):
            self.click(self.CANCEL_SIGN_OUT)
        return self

    def sign_out(self) -> "LoginPage":
        """Complete sign out flow"""
        self.click_sign_out()
        return self.confirm_sign_out()

    def go_back(self) -> "HomePage":
        """Go back to home page"""
        if self.is_visible(self.BACK_BUTTON, timeout=2000):
            self.click(self.BACK_BUTTON)
        else:
            self.page.go_back()
        self.wait_for_load_state()
        from .home_page import HomePage
        return HomePage(self.page, self.base_url)

    def is_success_displayed(self) -> bool:
        """Check if success message is displayed"""
        return self.is_visible(self.SUCCESS_MESSAGE, timeout=3000)

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return self.is_visible(self.ERROR_MESSAGE, timeout=3000)

    def get_success_message(self) -> str:
        """Get success message text"""
        if self.is_success_displayed():
            return self.get_text(self.SUCCESS_MESSAGE)
        return ""

    def get_error_message(self) -> str:
        """Get error message text"""
        if self.is_error_displayed():
            return self.get_text(self.ERROR_MESSAGE)
        return ""
