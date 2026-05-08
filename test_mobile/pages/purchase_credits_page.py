"""
Purchase Credits Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class PurchaseCreditsPage(BasePage):
    """Page object for Purchase Credits screen"""

    # Locators
    PAGE_TITLE = "Purchase Credits"
    CURRENT_CREDITS = "Current Credits"

    # Credit packages
    CREDITS_10 = "10 Credits"
    CREDITS_25 = "25 Credits"
    CREDITS_50 = "50 Credits"
    CREDITS_100 = "100 Credits"

    # Payment
    PURCHASE_BUTTON = "Purchase"
    CONFIRM_BUTTON = "Confirm"
    CANCEL_BUTTON = "Cancel"

    def is_purchase_credits_screen_displayed(self) -> bool:
        """Check if purchase credits screen is displayed"""
        return self.is_text_present(self.PAGE_TITLE)

    def get_current_credits(self) -> int:
        """Get current credits count"""
        try:
            element = self.find_by_text(self.CURRENT_CREDITS, exact=False)
            text = element.text
            import re
            match = re.search(r'(\d+)', text)
            if match:
                return int(match.group(1))
            return 0
        except:
            return 0

    def select_10_credits(self):
        """Select 10 credits package"""
        self.tap_by_text(self.CREDITS_10)
        return self

    def select_25_credits(self):
        """Select 25 credits package"""
        self.tap_by_text(self.CREDITS_25)
        return self

    def select_50_credits(self):
        """Select 50 credits package"""
        self.tap_by_text(self.CREDITS_50)
        return self

    def select_100_credits(self):
        """Select 100 credits package"""
        self.tap_by_text(self.CREDITS_100)
        return self

    def select_credit_package(self, credits: int):
        """Select credit package by amount"""
        package_map = {
            10: self.CREDITS_10,
            25: self.CREDITS_25,
            50: self.CREDITS_50,
            100: self.CREDITS_100
        }
        if credits in package_map:
            self.tap_by_text(package_map[credits])
        return self

    def tap_purchase(self):
        """Tap purchase button"""
        self.tap_by_text(self.PURCHASE_BUTTON)
        return self

    def confirm_purchase(self):
        """Confirm purchase in dialog"""
        self.wait_for_text(self.CONFIRM_BUTTON)
        self.tap_by_text(self.CONFIRM_BUTTON)
        return self

    def cancel_purchase(self):
        """Cancel purchase in dialog"""
        if self.is_text_present(self.CANCEL_BUTTON, timeout=2):
            self.tap_by_text(self.CANCEL_BUTTON)
        return self

    def purchase_credits(self, amount: int):
        """Complete credit purchase flow"""
        self.select_credit_package(amount)
        self.tap_purchase()
        self.confirm_purchase()
        return self

    def is_success_displayed(self) -> bool:
        """Check if success message is displayed"""
        return (self.is_text_present("Success") or
                self.is_text_present("Credits added") or
                self.is_text_present("Purchase complete"))

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return (self.is_text_present("Failed") or
                self.is_text_present("Error") or
                self.is_text_present("Payment declined"))

    def is_no_payment_method_displayed(self) -> bool:
        """Check if no payment method message is displayed"""
        return self.is_text_present("No payment method")

    def get_package_price(self, credits: int) -> str:
        """Get price for a credit package"""
        try:
            package_element = self.find_by_text(f"{credits} Credits", exact=False)
            # Find associated price
            return package_element.text
        except:
            return ""

    def go_back(self):
        """Go back to settings"""
        self._back_with_wait()
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)
