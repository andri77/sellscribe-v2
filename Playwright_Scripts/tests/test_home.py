"""
Home/Dashboard Test Cases for SellScribe Web Application
"""
import pytest
from pages import HomePage, LoginPage, UploadPage, HistoryPage, SettingsPage


@pytest.mark.smoke
@pytest.mark.listing
class TestHomeDashboard:
    """Test cases for home/dashboard functionality"""

    def test_home_screen_displayed_after_login(self, logged_in_page: HomePage):
        """Verify home screen is displayed after login"""
        assert logged_in_page.is_home_screen_displayed(), \
            "Home screen should be displayed after login"
        logged_in_page.take_screenshot("test_home_screen_displayed_after_login")

    def test_create_listing_button_visible(self, logged_in_page: HomePage):
        """Verify create listing button is visible"""
        assert logged_in_page.is_visible(logged_in_page.CREATE_LISTING_BUTTON, timeout=5000), \
            "Create Listing button should be visible"
        logged_in_page.take_screenshot("test_create_listing_button_visible")

    def test_navigate_to_create_listing(self, logged_in_page: HomePage):
        """Test navigation to create listing screen"""
        upload_page = logged_in_page.click_create_listing()

        assert upload_page.is_upload_screen_displayed(), \
            "Upload screen should be displayed"
        logged_in_page.take_screenshot("test_navigate_to_create_listing")

    def test_navigate_to_history(self, logged_in_page: HomePage):
        """Test navigation to history screen"""
        history_page = logged_in_page.click_history()

        assert history_page.is_history_screen_displayed(), \
            "History screen should be displayed"
        logged_in_page.take_screenshot("test_navigate_to_history")

    def test_navigate_to_settings(self, logged_in_page: HomePage):
        """Test navigation to settings screen"""
        settings_page = logged_in_page.click_settings()

        assert settings_page.is_settings_screen_displayed(), \
            "Settings screen should be displayed"
        logged_in_page.take_screenshot("test_navigate_to_settings")

    def test_credits_displayed(self, logged_in_page: HomePage):
        """Test that credits are displayed on home screen"""
        assert logged_in_page.is_credits_visible(), \
            "Credits should be visible on home screen"
        logged_in_page.take_screenshot("test_credits_displayed")

    def test_get_credits_count(self, logged_in_page: HomePage):
        """Test getting credits count"""
        credits = logged_in_page.get_credits_remaining()
        assert credits >= 0, \
            "Credits should be a non-negative number"
        logged_in_page.take_screenshot("test_get_credits_count")


@pytest.mark.regression
@pytest.mark.listing
class TestHomeNavigation:
    """Test cases for home page navigation"""

    def test_sign_out_from_home(self, logged_in_page: HomePage):
        """Test signing out from home screen"""
        login_page = logged_in_page.sign_out()

        assert login_page.is_login_screen_displayed(), \
            "Should return to login screen after sign out"
        logged_in_page.take_screenshot("test_sign_out_from_home")

    def test_quick_actions_visible(self, logged_in_page: HomePage):
        """Test that quick actions are visible"""
        assert logged_in_page.is_quick_actions_visible() or \
            logged_in_page.is_text_present("Create Listing"), \
            "Quick actions or Create Listing should be visible"
        logged_in_page.take_screenshot("test_quick_actions_visible")

    def test_return_from_upload_to_home(self, logged_in_page: HomePage):
        """Test returning from upload screen to home"""
        upload_page = logged_in_page.click_create_listing()
        home_page = upload_page.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"
        logged_in_page.take_screenshot("test_return_from_upload_to_home")

    def test_return_from_history_to_home(self, logged_in_page: HomePage):
        """Test returning from history screen to home"""
        history_page = logged_in_page.click_history()
        home_page = history_page.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"
        logged_in_page.take_screenshot("test_return_from_history_to_home")

    def test_return_from_settings_to_home(self, logged_in_page: HomePage):
        """Test returning from settings screen to home"""
        settings_page = logged_in_page.click_settings()
        home_page = settings_page.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"
        logged_in_page.take_screenshot("test_return_from_settings_to_home")
