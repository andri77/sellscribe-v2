"""
History Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class HistoryPage(BasePage):
    """Page object for Listing History screen"""

    NEW_LISTING_BUTTON_ID = "new-listing-button"
    LISTING_CARD_ID = "listing-card"
    CREATE_FIRST_LISTING_BUTTON_ID = "create-first-listing-button"  # empty state
    VIEW_BUTTON_ID = "listing-view-button"
    EDIT_BUTTON_ID = "listing-edit-button"
    DELETE_BUTTON_ID = "listing-delete-button"
    CONFIRM_DELETE_BUTTON_ID = "confirm-delete-listing-button"
    CANCEL_DELETE_BUTTON_ID = "cancel-delete-listing-button"

    def is_history_screen_displayed(self, timeout: int = 10) -> bool:
        """Check if history screen is displayed"""
        return self.is_present(self.by_id(self.NEW_LISTING_BUTTON_ID), timeout)

    def has_listings(self) -> bool:
        """True if any listing card is shown (False when the empty state is shown)"""
        cards, empty = self.by_id(self.LISTING_CARD_ID), self.by_id(self.CREATE_FIRST_LISTING_BUTTON_ID)
        self.find_either(cards, empty)
        return bool(self.find_all(cards))

    def find_either(self, *locators, timeout: int = 15):
        """Wait until one of the locators is present (the list has loaded)"""
        from selenium.webdriver.support.ui import WebDriverWait
        WebDriverWait(self.driver, timeout).until(
            lambda d: any(d.find_elements(*loc) for loc in locators)
        )

    def get_listing_count(self) -> int:
        """Number of listing cards on screen"""
        return len(self.find_all(self.by_id(self.LISTING_CARD_ID))) if self.has_listings() else 0

    def tap_listing(self, index: int = 0):
        """Open a listing by index"""
        self.find_all(self.by_id(self.VIEW_BUTTON_ID))[index].click()
        return self

    def tap_first_listing(self):
        """Open the first listing"""
        return self.tap_listing(0)

    def delete_listing(self, index: int = 0):
        """Delete a listing by index and confirm"""
        self.find_all(self.by_id(self.DELETE_BUTTON_ID))[index].click()
        return self.tap(self.by_id(self.CONFIRM_DELETE_BUTTON_ID))

    def go_back(self):
        """Go back to home via the AppBar back button"""
        self.tap_back()
        from .home_page import HomePage
        return HomePage(self.driver)
