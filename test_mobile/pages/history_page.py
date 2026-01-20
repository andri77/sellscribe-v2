"""
History Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class HistoryPage(BasePage):
    """Page object for Listing History screen"""

    # Locators
    PAGE_TITLE = "History"
    NO_LISTINGS_TEXT = "No listings yet"
    LISTING_CARD = "listing_card"

    def is_history_screen_displayed(self) -> bool:
        """Check if history screen is displayed"""
        return self.is_text_present(self.PAGE_TITLE)

    def has_listings(self) -> bool:
        """Check if there are any listings"""
        return not self.is_text_present(self.NO_LISTINGS_TEXT, timeout=3)

    def get_listing_count(self) -> int:
        """Get count of listings displayed"""
        try:
            cards = self.find_elements(
                AppiumBy.XPATH,
                '//*[contains(@class, "Card") or contains(@class, "ListTile")]'
            )
            return len(cards)
        except:
            return 0

    def tap_listing(self, index: int = 0):
        """Tap on a listing by index"""
        try:
            cards = self.find_elements(
                AppiumBy.XPATH,
                '//*[contains(@class, "Card") or contains(@class, "ListTile")]'
            )
            if len(cards) > index:
                cards[index].click()
        except:
            pass
        return self

    def tap_first_listing(self):
        """Tap on the first listing"""
        return self.tap_listing(0)

    def search_listing(self, query: str):
        """Search for a listing"""
        if self.is_text_present("Search"):
            self.tap_by_text("Search")
            active = self.driver.switch_to.active_element
            active.send_keys(query)
            self.hide_keyboard()
        return self

    def scroll_to_listing(self, title: str):
        """Scroll to find a listing by title"""
        self.scroll_to_text(title)
        return self

    def is_listing_displayed(self, title: str) -> bool:
        """Check if a specific listing is displayed"""
        return self.is_text_present(title)

    def delete_listing(self, index: int = 0):
        """Delete a listing by index (swipe to delete)"""
        try:
            cards = self.find_elements(
                AppiumBy.XPATH,
                '//*[contains(@class, "Card") or contains(@class, "ListTile")]'
            )
            if len(cards) > index:
                card = cards[index]
                # Perform swipe left to reveal delete
                self.swipe_element_left(card)
                if self.is_text_present("Delete", timeout=2):
                    self.tap_by_text("Delete")
        except:
            pass
        return self

    def swipe_element_left(self, element):
        """Swipe element to the left"""
        location = element.location
        size = element.size
        start_x = location['x'] + size['width'] - 10
        end_x = location['x'] + 10
        y = location['y'] + size['height'] // 2
        self.driver.swipe(start_x, y, end_x, y, 300)

    def refresh_list(self):
        """Pull to refresh the list"""
        self.pull_to_refresh()
        return self

    def go_back(self):
        """Go back to home"""
        self.driver.back()
        from .home_page import HomePage
        return HomePage(self.driver)
