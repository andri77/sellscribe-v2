"""
History Page Object for SellScribe Web Application
"""
from playwright.sync_api import Page
from .base_page import BasePage


class HistoryPage(BasePage):
    """Page object for Listing History screen"""

    # Selectors
    LISTING_ITEM = "[data-testid='listing-item'], .listing-item, .listing-card, [class*='listing']"
    LISTING_TITLE = "[data-testid='listing-title'], .listing-title, h3, h4"
    LISTING_DATE = "[data-testid='listing-date'], .listing-date, .date, time"
    VIEW_BUTTON = "[data-testid='view-listing'], button:has-text('View'), a:has-text('View')"
    COPY_BUTTON = "[data-testid='copy-listing'], button:has-text('Copy'), button[aria-label='Copy']"
    SHARE_BUTTON = "[data-testid='share-listing'], button:has-text('Share'), button[aria-label='Share']"
    DELETE_BUTTON = "[data-testid='delete-listing'], button:has-text('Delete'), button[aria-label='Delete']"
    BACK_BUTTON = "[data-testid='back-button'], button:has-text('Back'), a:has-text('Back'), [aria-label='Back']"
    SEARCH_INPUT = "[data-testid='search-input'], input[type='search'], input[placeholder*='search' i]"
    FILTER_SELECT = "[data-testid='filter-select'], select[name='filter'], .filter-dropdown"
    SORT_SELECT = "[data-testid='sort-select'], select[name='sort'], .sort-dropdown"
    EMPTY_STATE = "[data-testid='empty-state'], .empty-state, .no-listings, p:has-text('No listings')"
    PAGINATION = "[data-testid='pagination'], .pagination, nav[aria-label='Pagination']"
    CONFIRM_DELETE = "[data-testid='confirm-delete'], button:has-text('Confirm'), button:has-text('Yes')"
    CANCEL_DELETE = "[data-testid='cancel-delete'], button:has-text('Cancel'), button:has-text('No')"

    def __init__(self, page: Page, base_url: str = ""):
        super().__init__(page)
        self.base_url = base_url
        self.history_url = f"{base_url}/history" if base_url else "/history"

    def navigate_to_history(self) -> "HistoryPage":
        """Navigate to history page"""
        self.navigate(self.history_url)
        self.wait_for_load_state()
        return self

    def is_history_screen_displayed(self) -> bool:
        """Check if history screen is displayed"""
        return (
            self.is_text_present("History", timeout=5000) or
            self.is_text_present("My Listings", timeout=3000) or
            self.is_visible(self.LISTING_ITEM, timeout=3000) or
            self.is_visible(self.EMPTY_STATE, timeout=3000)
        )

    def has_listings(self) -> bool:
        """Check if there are any listings"""
        return self.is_visible(self.LISTING_ITEM, timeout=3000)

    def get_listing_count(self) -> int:
        """Get number of listings displayed"""
        listings = self.page.query_selector_all(self.LISTING_ITEM)
        return len(listings)

    def get_listing_titles(self) -> list:
        """Get all listing titles"""
        titles = []
        items = self.page.query_selector_all(f"{self.LISTING_ITEM} {self.LISTING_TITLE}")
        for item in items:
            text = item.text_content()
            if text:
                titles.append(text.strip())
        return titles

    def click_listing(self, index: int = 0) -> None:
        """Click on a listing by index"""
        listings = self.page.query_selector_all(self.LISTING_ITEM)
        if listings and index < len(listings):
            listings[index].click()
            self.wait_for_load_state()

    def click_first_listing(self) -> None:
        """Click on the first listing"""
        self.click_listing(0)

    def view_listing(self, index: int = 0) -> None:
        """Click view button on a listing"""
        listings = self.page.query_selector_all(self.LISTING_ITEM)
        if listings and index < len(listings):
            view_btn = listings[index].query_selector(self.VIEW_BUTTON)
            if view_btn:
                view_btn.click()
                self.wait_for_load_state()

    def copy_listing(self, index: int = 0) -> None:
        """Click copy button on a listing"""
        listings = self.page.query_selector_all(self.LISTING_ITEM)
        if listings and index < len(listings):
            copy_btn = listings[index].query_selector(self.COPY_BUTTON)
            if copy_btn:
                copy_btn.click()

    def share_listing(self, index: int = 0) -> None:
        """Click share button on a listing"""
        listings = self.page.query_selector_all(self.LISTING_ITEM)
        if listings and index < len(listings):
            share_btn = listings[index].query_selector(self.SHARE_BUTTON)
            if share_btn:
                share_btn.click()

    def delete_listing(self, index: int = 0) -> None:
        """Delete a listing by index"""
        listings = self.page.query_selector_all(self.LISTING_ITEM)
        if listings and index < len(listings):
            delete_btn = listings[index].query_selector(self.DELETE_BUTTON)
            if delete_btn:
                delete_btn.click()
                # Confirm deletion
                if self.is_visible(self.CONFIRM_DELETE, timeout=3000):
                    self.click(self.CONFIRM_DELETE)
                    self.wait_for_load_state()

    def search_listings(self, query: str) -> "HistoryPage":
        """Search listings"""
        if self.is_visible(self.SEARCH_INPUT, timeout=3000):
            self.clear_and_fill(self.SEARCH_INPUT, query)
            self.press_enter()
            self.wait_for_load_state()
        return self

    def filter_by(self, filter_value: str) -> "HistoryPage":
        """Filter listings"""
        if self.is_visible(self.FILTER_SELECT, timeout=3000):
            self.select_option(self.FILTER_SELECT, filter_value)
            self.wait_for_load_state()
        return self

    def sort_by(self, sort_value: str) -> "HistoryPage":
        """Sort listings"""
        if self.is_visible(self.SORT_SELECT, timeout=3000):
            self.select_option(self.SORT_SELECT, sort_value)
            self.wait_for_load_state()
        return self

    def go_back(self) -> "HomePage":
        """Go back to home page"""
        if self.is_visible(self.BACK_BUTTON, timeout=2000):
            self.click(self.BACK_BUTTON)
        else:
            self.page.go_back()
        self.wait_for_load_state()
        from .home_page import HomePage
        return HomePage(self.page, self.base_url)

    def is_empty_state_displayed(self) -> bool:
        """Check if empty state is displayed"""
        return self.is_visible(self.EMPTY_STATE, timeout=3000)

    def has_pagination(self) -> bool:
        """Check if pagination is visible"""
        return self.is_visible(self.PAGINATION, timeout=3000)
