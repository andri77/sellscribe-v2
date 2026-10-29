"""
Settings Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class SettingsPage(BasePage):
    """Page object for Settings screen"""

    EDIT_PROFILE_TILE_ID = "edit-profile-tile"
    THEME_BUTTON_ID = "theme-button"
    PAYMENT_METHODS_TILE_ID = "payment-methods-tile"
    PURCHASE_CREDITS_TILE_ID = "purchase-credits-tile"
    SIGN_OUT_BUTTON_ID = "sign-out-button"
    CONFIRM_SIGN_OUT_BUTTON_ID = "confirm-sign-out-button"
    CANCEL_SIGN_OUT_BUTTON_ID = "cancel-sign-out-button"

    # Theme bottom sheet options
    THEME_OPTION_IDS = {
        "Light": "theme-light-option",
        "Dark": "theme-dark-option",
        "System": "theme-system-option",
    }
    THEME_LIGHT = "Light"
    THEME_DARK = "Dark"
    THEME_SYSTEM = "System"

    def is_settings_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if settings screen is displayed"""
        return self.is_present(self.by_id(self.EDIT_PROFILE_TILE_ID), timeout)

    def is_option_displayed(self, test_id: str) -> bool:
        """Check if a settings tile is displayed"""
        return self.is_present(self.by_id(test_id))

    def tap_edit_profile(self):
        """Tap the edit profile tile"""
        self.tap(self.by_id(self.EDIT_PROFILE_TILE_ID))
        from .profile_edit_page import ProfileEditPage
        return ProfileEditPage(self.driver)

    def tap_theme(self):
        """Open the theme picker"""
        return self.tap(self.by_id(self.THEME_BUTTON_ID))

    def select_theme(self, theme: str):
        """Pick a theme from the bottom sheet"""
        option = self.by_id(self.THEME_OPTION_IDS[theme])
        self.tap_theme()
        self.tap(option)
        self.is_gone(option)  # sheet closed
        return self

    def set_light_theme(self):
        """Set light theme"""
        return self.select_theme(self.THEME_LIGHT)

    def set_dark_theme(self):
        """Set dark theme"""
        return self.select_theme(self.THEME_DARK)

    def set_system_theme(self):
        """Set system theme"""
        return self.select_theme(self.THEME_SYSTEM)

    def get_current_theme(self) -> str:
        """Current theme, shown as the theme tile's subtitle"""
        tile = self.find(self.by_id(self.THEME_BUTTON_ID))
        # Flutter merges the tile's text into one description: "<id>\nTheme\n<mode>"
        return (tile.get_attribute('content-desc') or '').split('\n')[-1]

    def tap_payment_methods(self):
        """Tap the payment methods tile"""
        self.tap(self.by_id(self.PAYMENT_METHODS_TILE_ID))
        from .payment_methods_page import PaymentMethodsPage
        return PaymentMethodsPage(self.driver)

    def tap_purchase_credits(self):
        """Tap the purchase credits tile"""
        self.tap(self.by_id(self.PURCHASE_CREDITS_TILE_ID))
        from .purchase_credits_page import PurchaseCreditsPage
        return PurchaseCreditsPage(self.driver)

    def tap_sign_out(self):
        """Tap the sign out tile (opens the confirmation dialog)"""
        return self.tap(self.by_id(self.SIGN_OUT_BUTTON_ID))

    def is_sign_out_dialog_displayed(self) -> bool:
        """Check if the sign out confirmation dialog is displayed"""
        return self.is_present(self.by_id(self.CONFIRM_SIGN_OUT_BUTTON_ID))

    def confirm_sign_out(self):
        """Confirm sign out in the dialog"""
        self.tap(self.by_id(self.CONFIRM_SIGN_OUT_BUTTON_ID))
        from .login_page import LoginPage
        return LoginPage(self.driver)

    def cancel_sign_out(self):
        """Cancel sign out in the dialog"""
        cancel = self.by_id(self.CANCEL_SIGN_OUT_BUTTON_ID)
        self.tap(cancel)
        self.is_gone(cancel)
        return self

    def go_back(self):
        """Go back to home via the AppBar back button"""
        self.tap_back()
        from .home_page import HomePage
        return HomePage(self.driver)
