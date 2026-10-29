"""
Home Page Object for SellScribe Mobile App
"""
from .base_page import BasePage


class HomePage(BasePage):
    """Page object for Home screen"""

    CREATE_LISTING_BUTTON_ID = "create-listing-button"
    VIEW_HISTORY_BUTTON_ID = "view-history-button"
    CREDITS_COUNT_ID = "credits-count"
    PROFILE_MENU_TOOLTIP = "profile-menu"
    SETTINGS_MENU_ITEM_ID = "settings-menu-item"
    SIGN_OUT_MENU_ITEM_ID = "sign-out-menu-item"

    def is_home_screen_displayed(self, timeout: int = 20) -> bool:
        """Check if home screen is displayed (allows for the sign-in round trip)"""
        return self.is_present(self.by_id(self.CREATE_LISTING_BUTTON_ID), timeout)

    def is_credits_displayed(self) -> bool:
        """Check if the credits counter is displayed"""
        return self.is_present(self.by_id(self.CREDITS_COUNT_ID))

    def get_credits_remaining(self) -> int:
        """Remaining credits shown in the AppBar"""
        return int(self.read_text(self.CREDITS_COUNT_ID))

    def tap_create_listing(self):
        """Tap the Create Listing card"""
        self.tap(self.by_id(self.CREATE_LISTING_BUTTON_ID))
        from .upload_page import UploadPage
        return UploadPage(self.driver)

    def tap_view_history(self):
        """Tap the View History card"""
        self.tap(self.by_id(self.VIEW_HISTORY_BUTTON_ID))
        from .history_page import HistoryPage
        return HistoryPage(self.driver)

    def tap_profile_menu(self):
        """Open the profile menu"""
        return self.tap(self.by_tooltip(self.PROFILE_MENU_TOOLTIP))

    def tap_settings(self):
        """Open settings from the profile menu"""
        self.tap_profile_menu()
        self.tap(self.by_id(self.SETTINGS_MENU_ITEM_ID))
        from .settings_page import SettingsPage
        return SettingsPage(self.driver)

    def tap_sign_out(self):
        """Sign out from the profile menu (signs out straight away, no dialog)"""
        self.tap_profile_menu()
        self.tap(self.by_id(self.SIGN_OUT_MENU_ITEM_ID))
        from .login_page import LoginPage
        return LoginPage(self.driver)
