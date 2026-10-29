"""
Payment Methods Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class PaymentMethodsPage(BasePage):
    """Page object for Payment Methods screen"""

    ADD_CARD_BUTTON_ID = "add-card-button"

    # Add card bottom sheet
    CARD_NUMBER_INPUT_ID = "card-number-input"
    EXPIRY_INPUT_ID = "card-expiry-input"
    CVV_INPUT_ID = "card-cvv-input"
    CARDHOLDER_INPUT_ID = "cardholder-name-input"
    SAVE_CARD_BUTTON_ID = "save-card-button"

    def is_payment_methods_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if payment methods screen is displayed"""
        return self.is_present(self.by_id(self.ADD_CARD_BUTTON_ID), timeout)

    def tap_add_card(self):
        """Open the add card sheet"""
        return self.tap(self.by_id(self.ADD_CARD_BUTTON_ID))

    def is_add_card_form_displayed(self, timeout: int = 5) -> bool:
        """Check if the add card sheet is open"""
        return self.is_present(self.by_id(self.SAVE_CARD_BUTTON_ID), timeout)

    def enter_card_number(self, card_number: str):
        """Enter card number"""
        return self.type_into(self.CARD_NUMBER_INPUT_ID, card_number)

    def enter_expiry(self, expiry: str):
        """Enter expiry date (MM/YY)"""
        return self.type_into(self.EXPIRY_INPUT_ID, expiry)

    def enter_cvv(self, cvv: str):
        """Enter CVV"""
        return self.type_into(self.CVV_INPUT_ID, cvv)

    def enter_cardholder_name(self, name: str):
        """Enter cardholder name"""
        return self.type_into(self.CARDHOLDER_INPUT_ID, name)

    def tap_save_card(self):
        """Tap Add Card in the sheet (closes the sheet when the card is valid)"""
        return self.tap(self.by_id(self.SAVE_CARD_BUTTON_ID))

    def add_card(self, card_number: str, expiry: str, cvv: str, name: str):
        """Add a new card"""
        self.tap_add_card()
        self.enter_card_number(card_number)
        self.enter_expiry(expiry)
        self.enter_cvv(cvv)
        self.enter_cardholder_name(name)
        self.tap_save_card()
        return self

    def go_back(self):
        """Go back to settings via the AppBar back button"""
        self.tap_back()
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)
