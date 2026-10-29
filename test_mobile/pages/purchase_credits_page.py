"""
Purchase Credits Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class PurchaseCreditsPage(BasePage):
    """Page object for Purchase Credits screen"""

    CURRENT_CREDITS_ID = "current-credits"
    PURCHASE_BUTTON_ID = "purchase-button"
    PACKAGE_SIZES = (10, 25, 50, 100)

    @staticmethod
    def package_id(credits: int) -> str:
        """Test ID of the credit package card"""
        return f"credit-package-{credits}"

    def is_purchase_credits_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if purchase credits screen is displayed"""
        return self.is_present(self.by_id(self.PURCHASE_BUTTON_ID), timeout)

    def are_packages_displayed(self) -> bool:
        """Check if every credit package is displayed"""
        return all(self.is_present(self.by_id(self.package_id(n))) for n in self.PACKAGE_SIZES)

    def get_current_credits(self) -> int:
        """Current balance shown at the top"""
        return int(self.read_text(self.CURRENT_CREDITS_ID))

    def select_credit_package(self, credits: int):
        """Select a credit package by size"""
        return self.tap(self.by_id(self.package_id(credits)))

    def select_10_credits(self):
        """Select 10 credits package"""
        return self.select_credit_package(10)

    def tap_purchase(self):
        """Tap the purchase button"""
        return self.tap(self.by_id(self.PURCHASE_BUTTON_ID))

    def go_back(self):
        """Go back to settings via the AppBar back button"""
        self.tap_back()
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)
