"""
Home Page Object for SellScribe Mobile App
"""
from appium.webdriver.common.appiumby import AppiumBy
from .base_page import BasePage


class HomePage(BasePage):
    """Page object for Home screen"""

    # Actual content-desc values discovered via adb uiautomator dump.
    # PopupMenuButton(tooltip:'profile-menu') renders as 'Show menu' (Material default).
    # Action cards merge child Text widgets: cd='Create Listing\n...' → match by prefix.
    APP_TITLE = "SellScribe"
    CREDITS_TEXT = "credits"
    CREATE_LISTING_TEXT = "Create Listing"
    VIEW_HISTORY_TEXT = "View History"
    WELCOME_TEXT = "Welcome back"
    QUICK_ACTIONS = "Quick Actions"
    RECENT_LISTINGS = "Recent Listings"
    PROFILE_MENU_CD = "Show menu"

    def is_home_screen_displayed(self) -> bool:
        """Check if home screen is displayed"""
        return self.is_any_text_present(
            self.APP_TITLE, self.WELCOME_TEXT, self.QUICK_ACTIONS, "Create Listing", "credits", timeout=8
        )

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
        """Tap Create Listing button (content-desc contains 'Create Listing')"""
        self.find_by_text(self.CREATE_LISTING_TEXT, exact=False).click()
        from .upload_page import UploadPage
        return UploadPage(self.driver)

    def tap_view_history(self):
        """Tap View History button (content-desc contains 'View History')"""
        self.find_by_text(self.VIEW_HISTORY_TEXT, exact=False).click()
        from .history_page import HistoryPage
        return HistoryPage(self.driver)

    def tap_profile_menu(self):
        """Tap profile menu button (Material default tooltip: 'Show menu')"""
        self.find_by_accessibility_id(self.PROFILE_MENU_CD).click()
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
