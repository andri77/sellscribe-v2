"""
Home Page Object for SellScribe Web Application
"""
from playwright.sync_api import Page
from .base_page import BasePage


class HomePage(BasePage):
    """Page object for Home/Dashboard screen"""

    # Selectors
    CREATE_LISTING_BUTTON = "[data-testid='create-listing'], button:has-text('Create Listing'), a:has-text('Create Listing'), button:has-text('New Listing')"
    CREDITS_DISPLAY = "[data-testid='credits-display'], .credits, [class*='credit']"
    HISTORY_LINK = "[data-testid='history-link'], a:has-text('History'), button:has-text('History'), a:has-text('My Listings')"
    SETTINGS_LINK = "[data-testid='settings-link'], a:has-text('Settings'), button:has-text('Settings'), [aria-label='Settings']"
    PROFILE_MENU = "[data-testid='profile-menu'], .profile-menu, [aria-label='Profile']"
    SIGN_OUT_BUTTON = "[data-testid='sign-out'], button:has-text('Sign Out'), a:has-text('Sign Out'), button:has-text('Logout')"
    WELCOME_MESSAGE = "[data-testid='welcome-message'], .welcome, h1:has-text('Welcome'), h2:has-text('Welcome')"
    QUICK_ACTIONS = "[data-testid='quick-actions'], .quick-actions, section:has-text('Quick Actions')"
    RECENT_LISTINGS = "[data-testid='recent-listings'], .recent-listings, section:has-text('Recent')"
    NAV_MENU = "nav, [role='navigation'], .navbar, .nav-menu"

    def __init__(self, page: Page, base_url: str = ""):
        super().__init__(page)
        self.base_url = base_url
        self.home_url = f"{base_url}/dashboard" if base_url else "/dashboard"

    def navigate_to_home(self) -> "HomePage":
        """Navigate to home page"""
        self.navigate(self.home_url)
        self.wait_for_load_state()
        return self

    def is_home_screen_displayed(self) -> bool:
        """Check if home screen is displayed"""
        return (
            self.is_visible(self.CREATE_LISTING_BUTTON, timeout=5000) or
            self.is_visible(self.WELCOME_MESSAGE, timeout=3000) or
            self.is_text_present("Dashboard", timeout=3000) or
            self.is_text_present("Create Listing", timeout=3000)
        )

    def click_create_listing(self) -> "UploadPage":
        """Click create listing button"""
        self.click(self.CREATE_LISTING_BUTTON)
        self.wait_for_load_state()
        from .upload_page import UploadPage
        return UploadPage(self.page, self.base_url)

    def get_credits_remaining(self) -> int:
        """Get number of credits remaining"""
        if self.is_visible(self.CREDITS_DISPLAY, timeout=3000):
            text = self.get_text(self.CREDITS_DISPLAY)
            # Extract number from text like "5 credits" or "Credits: 5"
            import re
            numbers = re.findall(r'\d+', text)
            if numbers:
                return int(numbers[0])
        return 0

    def click_history(self) -> "HistoryPage":
        """Navigate to history page"""
        self.click(self.HISTORY_LINK)
        self.wait_for_load_state()
        from .history_page import HistoryPage
        return HistoryPage(self.page, self.base_url)

    def click_settings(self) -> "SettingsPage":
        """Navigate to settings page"""
        self.click(self.SETTINGS_LINK)
        self.wait_for_load_state()
        from .settings_page import SettingsPage
        return SettingsPage(self.page, self.base_url)

    def open_profile_menu(self) -> "HomePage":
        """Open profile dropdown menu"""
        if self.is_visible(self.PROFILE_MENU, timeout=3000):
            self.click(self.PROFILE_MENU)
        return self

    def sign_out(self) -> "LoginPage":
        """Sign out of the application"""
        self.open_profile_menu()
        self.click(self.SIGN_OUT_BUTTON)
        self.wait_for_load_state()
        from .login_page import LoginPage
        return LoginPage(self.page, self.base_url)

    def is_credits_visible(self) -> bool:
        """Check if credits display is visible"""
        return self.is_visible(self.CREDITS_DISPLAY, timeout=3000)

    def is_quick_actions_visible(self) -> bool:
        """Check if quick actions section is visible"""
        return (
            self.is_visible(self.QUICK_ACTIONS, timeout=3000) or
            self.is_text_present("Quick Actions", timeout=2000)
        )

    def get_welcome_message(self) -> str:
        """Get welcome message text"""
        if self.is_visible(self.WELCOME_MESSAGE, timeout=3000):
            return self.get_text(self.WELCOME_MESSAGE)
        return ""

    def has_recent_listings(self) -> bool:
        """Check if there are recent listings displayed"""
        return self.is_visible(self.RECENT_LISTINGS, timeout=3000)
