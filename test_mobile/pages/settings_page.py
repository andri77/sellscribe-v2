"""
Settings Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class SettingsPage(BasePage):
    """Page object for Settings screen"""

    # ACCESSIBILITY_ID locators — map to Semantics(label:) in Flutter source
    BACK_BUTTON_ID = "Back"
    EDIT_PROFILE_TILE_ID = "edit-profile-tile"
    THEME_BUTTON_ID = "theme-button"
    SIGN_OUT_BUTTON_ID = "sign-out-button"
    PAYMENT_METHODS_TILE_ID = "payment-methods-tile"
    PURCHASE_CREDITS_TILE_ID = "purchase-credits-tile"

    # Text-based helpers (screen detection, theme sheet options)
    SETTINGS_TITLE = "Settings"
    THEME_LIGHT = "Light"
    THEME_DARK = "Dark"
    THEME_SYSTEM = "System"

    def is_settings_screen_displayed(self) -> bool:
        """Check if settings screen is displayed"""
        return self.is_any_text_present(
            self.SETTINGS_TITLE, "Sign Out", "Appearance", "Theme", timeout=5
        )

    def tap_edit_profile(self):
        """Tap to edit profile"""
        self.find_by_accessibility_id(self.EDIT_PROFILE_TILE_ID).click()
        from .profile_edit_page import ProfileEditPage
        return ProfileEditPage(self.driver)

    def tap_theme(self):
        """Tap theme option"""
        self.find_by_accessibility_id(self.THEME_BUTTON_ID).click()
        return self

    def select_theme(self, theme: str):
        """Select theme from bottom sheet"""
        import time
        self.tap_theme()
        # Wait for bottom sheet
        self.wait_for_text("Select Theme")
        self.tap_by_text(theme)
        time.sleep(2.5)  # wait for bottom sheet to close and settings to re-render
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
        """Get current theme setting"""
        try:
            # Find the theme row and get the subtitle text
            theme_element = self.find_by_text("Theme", exact=False)
            # Get parent and find subtitle
            return theme_element.text
        except:
            return ""

    def tap_payment_methods(self):
        """Tap payment methods"""
        self.find_by_accessibility_id(self.PAYMENT_METHODS_TILE_ID).click()
        from .payment_methods_page import PaymentMethodsPage
        return PaymentMethodsPage(self.driver)

    def tap_purchase_credits(self):
        """Tap purchase credits"""
        self.find_by_accessibility_id(self.PURCHASE_CREDITS_TILE_ID).click()
        from .purchase_credits_page import PurchaseCreditsPage
        return PurchaseCreditsPage(self.driver)

    def tap_sign_out(self):
        """Tap sign out"""
        self.find_by_accessibility_id(self.SIGN_OUT_BUTTON_ID).click()
        return self

    def confirm_sign_out(self):
        """Confirm sign out in dialog"""
        import time
        time.sleep(1)  # wait for dialog to render
        for label in ["Sign Out", "Confirm", "Yes"]:
            if self.is_text_present(label, timeout=3):
                buttons = self.find_elements(
                    AppiumBy.XPATH,
                    f'//*[@text="{label}" or @content-desc="{label}"]'
                )
                if buttons:
                    buttons[-1].click()
                    break
        time.sleep(1)
        from .login_page import LoginPage
        return LoginPage(self.driver)

    def go_back(self):
        """Go back to home via AppBar back button (tooltip='Back' set in Flutter source)"""
        import time
        try:
            self.find_by_accessibility_id(self.BACK_BUTTON_ID, timeout=3).click()
        except Exception:
            self.driver.back()
        time.sleep(3.0)  # wait for Flutter pop animation + home re-render (loadHistory network call)
        from .home_page import HomePage
        return HomePage(self.driver)
