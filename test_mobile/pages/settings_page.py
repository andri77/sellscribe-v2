"""
Settings Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class SettingsPage(BasePage):
    """Page object for Settings screen"""

    # Actual content-desc values discovered via adb uiautomator dump.
    # Tile content-descs merge all child text: e.g. 'Theme\nSystem'.
    # We match by prefix with exact=False so the subtitle doesn't break the locator.
    SETTINGS_TITLE = "Settings"
    SIGN_OUT_CD = "Sign Out"
    THEME_PREFIX = "Theme"
    PAYMENT_METHODS_PREFIX = "Payment Methods"
    PURCHASE_CREDITS_PREFIX = "Purchase Credits"
    THEME_LIGHT = "Light"
    THEME_DARK = "Dark"
    THEME_SYSTEM = "System"

    def is_settings_screen_displayed(self) -> bool:
        """Check if settings screen is displayed"""
        return self.is_any_text_present(
            self.SETTINGS_TITLE, self.SIGN_OUT_CD, "Appearance", self.THEME_PREFIX, timeout=5
        )

    def tap_edit_profile(self):
        """Tap edit profile tile (first tappable tile; contains user name/email)"""
        # The edit-profile tile's content-desc is 'T\nTEST AGENT\ntest@sellscribe.com'
        # (avatar initial + name + email). Tap the first clickable tile on the screen
        # since it's always the profile tile.
        elements = self.driver.find_elements(
            AppiumBy.XPATH,
            '//*[@clickable="true" and contains(@content-desc, "@")]'
        )
        if elements:
            elements[0].click()
        else:
            # Fallback: tap by partial text match on email domain
            self.find_by_text("sellscribe.com", exact=False).click()
        from .profile_edit_page import ProfileEditPage
        return ProfileEditPage(self.driver)

    def tap_theme(self):
        """Tap theme option tile"""
        self.find_by_text(self.THEME_PREFIX, exact=False).click()
        return self

    def select_theme(self, theme: str):
        """Select theme from bottom sheet"""
        import time
        self.tap_theme()
        self.wait_for_text("Select Theme")
        self.tap_by_text(theme)
        time.sleep(2.5)
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
            theme_element = self.find_by_text(self.THEME_PREFIX, exact=False)
            return theme_element.text
        except:
            return ""

    def tap_payment_methods(self):
        """Tap payment methods tile"""
        self.find_by_text(self.PAYMENT_METHODS_PREFIX, exact=False).click()
        from .payment_methods_page import PaymentMethodsPage
        return PaymentMethodsPage(self.driver)

    def tap_purchase_credits(self):
        """Tap purchase credits tile"""
        self.find_by_text(self.PURCHASE_CREDITS_PREFIX, exact=False).click()
        from .purchase_credits_page import PurchaseCreditsPage
        return PurchaseCreditsPage(self.driver)

    def tap_sign_out(self):
        """Tap sign out button (content-desc='Sign Out')"""
        self.find_by_text(self.SIGN_OUT_CD).click()
        return self

    def confirm_sign_out(self):
        """Confirm sign out in dialog"""
        import time
        time.sleep(1)
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
        """Go back to home via AppBar back button or Android back"""
        import time
        try:
            # Flutter AppBar back button content-desc is typically 'Navigate up' or 'Back'
            back = self.driver.find_elements(
                AppiumBy.XPATH,
                '//*[@content-desc="Navigate up" or @content-desc="Back"]'
            )
            if back:
                back[0].click()
            else:
                self.driver.back()
        except Exception:
            self.driver.back()
        time.sleep(3.0)
        from .home_page import HomePage
        return HomePage(self.driver)
