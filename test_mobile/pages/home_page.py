"""
Home Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class HomePage(BasePage):
    """Page object for Home screen"""

    # Locators
    APP_TITLE = "SellScribe"
    CREDITS_TEXT = "credits"
    CREATE_LISTING_BUTTON = "Create Listing"
    VIEW_HISTORY_BUTTON = "View History"
    WELCOME_TEXT = "Welcome back"
    QUICK_ACTIONS = "Quick Actions"
    RECENT_LISTINGS = "Recent Listings"
    PROFILE_AVATAR = "person"  # Icon identifier

    def is_home_screen_displayed(self) -> bool:
        """Check if home screen is displayed"""
        return self.is_text_present(self.APP_TITLE) or self.is_text_present(self.WELCOME_TEXT)

    def get_credits_remaining(self) -> int:
        """Get remaining credits count"""
        try:
            # Find element containing credits text
            element = self.find_by_text(self.CREDITS_TEXT, exact=False)
            text = element.text
            # Extract number from text like "5 credits"
            import re
            match = re.search(r'(\d+)', text)
            if match:
                return int(match.group(1))
            return 0
        except:
            return 0

    def tap_create_listing(self):
        """Tap Create Listing button"""
        self.tap_by_text(self.CREATE_LISTING_BUTTON)
        from .upload_page import UploadPage
        return UploadPage(self.driver)

    def tap_view_history(self):
        """Tap View History button"""
        self.tap_by_text(self.VIEW_HISTORY_BUTTON)
        from .history_page import HistoryPage
        return HistoryPage(self.driver)

    def tap_profile_menu(self):
        """Tap profile avatar to open menu"""
        # Find and tap the profile avatar
        try:
            self.find_by_content_desc("person")
            self.tap(AppiumBy.XPATH, '//*[@content-desc="person"]')
        except:
            # Alternative: tap by class name or position
            self.tap_by_text("person", timeout=3)
        return self

    def tap_settings(self):
        """Open settings from profile menu"""
        self.tap_profile_menu()
        self.tap_by_text("Settings")
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)

    def tap_sign_out(self):
        """Sign out from profile menu"""
        self.tap_profile_menu()
        self.tap_by_text("Sign out")
        return self

    def confirm_sign_out(self):
        """Confirm sign out dialog"""
        if self.is_text_present("Sign Out", timeout=3):
            self.tap_by_text("Sign Out")
        from .login_page import LoginPage
        return LoginPage(self.driver)

    def get_welcome_message(self) -> str:
        """Get welcome message text"""
        try:
            element = self.find_by_text(self.WELCOME_TEXT, exact=False)
            return element.text
        except:
            return ""

    def has_recent_listings(self) -> bool:
        """Check if there are recent listings"""
        return not self.is_text_present("No listings yet")

    def tap_recent_listing(self, index: int = 0):
        """Tap on a recent listing"""
        self.scroll_to_text(self.RECENT_LISTINGS)
        # Find listing cards and tap the one at index
        listings = self.find_elements(
            AppiumBy.XPATH,
            '//*[contains(@class, "Card") or contains(@class, "ListTile")]'
        )
        if len(listings) > index:
            listings[index].click()
        return self
