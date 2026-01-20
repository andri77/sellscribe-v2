"""
Payment Methods Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class PaymentMethodsPage(BasePage):
    """Page object for Payment Methods screen"""

    # Locators
    PAGE_TITLE = "Payment Methods"
    ADD_CARD_BUTTON = "Add Card"
    NO_CARDS_TEXT = "No payment methods"

    # Card form fields
    CARD_NUMBER_FIELD = "Card Number"
    EXPIRY_FIELD = "Expiry"
    CVV_FIELD = "CVV"
    CARDHOLDER_FIELD = "Cardholder Name"
    SAVE_CARD_BUTTON = "Save Card"
    CANCEL_BUTTON = "Cancel"

    def is_payment_methods_screen_displayed(self) -> bool:
        """Check if payment methods screen is displayed"""
        return self.is_text_present(self.PAGE_TITLE)

    def has_saved_cards(self) -> bool:
        """Check if there are saved cards"""
        return not self.is_text_present(self.NO_CARDS_TEXT, timeout=3)

    def tap_add_card(self):
        """Tap add card button"""
        self.tap_by_text(self.ADD_CARD_BUTTON)
        return self

    def enter_card_number(self, card_number: str):
        """Enter card number"""
        self.tap_by_text(self.CARD_NUMBER_FIELD)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(card_number)
        self.hide_keyboard()
        return self

    def enter_expiry(self, expiry: str):
        """Enter expiry date (MM/YY)"""
        self.tap_by_text(self.EXPIRY_FIELD)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(expiry)
        self.hide_keyboard()
        return self

    def enter_cvv(self, cvv: str):
        """Enter CVV"""
        self.tap_by_text(self.CVV_FIELD)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(cvv)
        self.hide_keyboard()
        return self

    def enter_cardholder_name(self, name: str):
        """Enter cardholder name"""
        self.tap_by_text(self.CARDHOLDER_FIELD)
        active = self.driver.switch_to.active_element
        active.clear()
        active.send_keys(name)
        self.hide_keyboard()
        return self

    def tap_save_card(self):
        """Tap save card button"""
        self.tap_by_text(self.SAVE_CARD_BUTTON)
        return self

    def tap_cancel(self):
        """Tap cancel button"""
        self.tap_by_text(self.CANCEL_BUTTON)
        return self

    def add_card(self, card_number: str, expiry: str, cvv: str, name: str):
        """Add a new card"""
        self.tap_add_card()
        self.enter_card_number(card_number)
        self.enter_expiry(expiry)
        self.enter_cvv(cvv)
        self.enter_cardholder_name(name)
        self.tap_save_card()
        return self

    def get_card_count(self) -> int:
        """Get count of saved cards"""
        try:
            cards = self.find_elements(
                AppiumBy.XPATH,
                '//*[contains(@text, "****") or contains(@text, "ending")]'
            )
            return len(cards)
        except:
            return 0

    def delete_card(self, index: int = 0):
        """Delete a card by index"""
        try:
            cards = self.find_elements(
                AppiumBy.XPATH,
                '//*[contains(@text, "****") or contains(@text, "ending")]'
            )
            if len(cards) > index:
                # Long press to reveal delete option
                self.long_press(cards[index])
                if self.is_text_present("Delete", timeout=2):
                    self.tap_by_text("Delete")
                    # Confirm deletion
                    if self.is_text_present("Confirm", timeout=2):
                        self.tap_by_text("Confirm")
        except:
            pass
        return self

    def long_press(self, element, duration: int = 1000):
        """Perform long press on element"""
        from selenium.webdriver.common.action_chains import ActionChains
        actions = ActionChains(self.driver)
        actions.click_and_hold(element)
        actions.pause(duration / 1000)
        actions.release()
        actions.perform()

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return (self.is_text_present("Invalid") or
                self.is_text_present("Error"))

    def is_success_displayed(self) -> bool:
        """Check if success message is displayed"""
        return self.is_text_present("Card added")

    def go_back(self):
        """Go back to settings"""
        self.driver.back()
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)
