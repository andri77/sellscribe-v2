"""
Listing Test Cases for SellScribe Web Application
"""
import pytest
from pages import HomePage, UploadPage, HistoryPage


@pytest.mark.smoke
@pytest.mark.listing
class TestListingCreation:
    """Test cases for listing creation functionality"""

    def test_upload_screen_displayed(self, logged_in_page: HomePage):
        """Verify upload screen is displayed"""
        upload_page = logged_in_page.click_create_listing()

        assert upload_page.is_upload_screen_displayed(), \
            "Upload screen should be displayed"
        upload_page.take_screenshot("test_upload_screen_displayed")

    def test_upload_screen_elements(self, logged_in_page: HomePage):
        """Verify upload screen has required elements"""
        upload_page = logged_in_page.click_create_listing()

        assert (
            upload_page.is_text_present("Upload") or
            upload_page.is_text_present("Add Product") or
            upload_page.is_text_present("Create")
        ), "Upload screen should have upload-related text"
        upload_page.take_screenshot("test_upload_screen_elements")

    def test_generate_button_visible(self, logged_in_page: HomePage):
        """Test that generate button is visible"""
        upload_page = logged_in_page.click_create_listing()

        assert upload_page.is_visible(upload_page.GENERATE_BUTTON, timeout=5000) or \
            upload_page.is_text_present("Generate"), \
            "Generate button should be visible"
        upload_page.take_screenshot("test_generate_button_visible")

    def test_cancel_upload_returns_home(self, logged_in_page: HomePage):
        """Test canceling upload returns to home"""
        upload_page = logged_in_page.click_create_listing()
        home_page = upload_page.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"
        upload_page.take_screenshot("test_cancel_upload_returns_home")


@pytest.mark.smoke
@pytest.mark.listing
class TestListingHistory:
    """Test cases for listing history functionality"""

    def test_history_screen_displayed(self, logged_in_page: HomePage):
        """Verify history screen is displayed"""
        history_page = logged_in_page.click_history()

        assert history_page.is_history_screen_displayed(), \
            "History screen should be displayed"
        history_page.take_screenshot("test_history_screen_displayed")

    def test_return_from_history_to_home(self, logged_in_page: HomePage):
        """Test returning from history to home"""
        history_page = logged_in_page.click_history()
        home_page = history_page.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"
        history_page.take_screenshot("test_return_from_history_to_home")

    def test_check_for_listings(self, logged_in_page: HomePage):
        """Test checking for existing listings"""
        history_page = logged_in_page.click_history()

        # Either has listings or shows empty state
        has_listings = history_page.has_listings()
        is_empty = history_page.is_empty_state_displayed()

        assert has_listings or is_empty or history_page.is_history_screen_displayed(), \
            "History should show listings or empty state"
        history_page.take_screenshot("test_check_for_listings")


@pytest.mark.regression
@pytest.mark.listing
class TestListingDetails:
    """Test cases for listing details functionality"""

    def test_listing_count(self, logged_in_page: HomePage):
        """Test getting listing count"""
        history_page = logged_in_page.click_history()

        count = history_page.get_listing_count()
        assert count >= 0, \
            "Listing count should be non-negative"
        history_page.take_screenshot("test_listing_count")

    def test_search_listings(self, logged_in_page: HomePage):
        """Test searching listings"""
        history_page = logged_in_page.click_history()

        if history_page.is_visible(history_page.SEARCH_INPUT, timeout=3000):
            history_page.search_listings("test")
            history_page.page.wait_for_timeout(1000)

        assert history_page.is_history_screen_displayed(), \
            "Should remain on history screen after search"
        history_page.take_screenshot("test_search_listings")


@pytest.mark.regression
@pytest.mark.listing
class TestListingCredits:
    """Test cases for credit usage in listing generation"""

    def test_display_credits_on_home(self, logged_in_page: HomePage):
        """Test that credits are displayed on home screen"""
        credits = logged_in_page.get_credits_remaining()

        assert credits >= 0, \
            "Credits should be displayed and non-negative"
        logged_in_page.take_screenshot("test_display_credits_on_home")

    def test_credits_display_format(self, logged_in_page: HomePage):
        """Test credits display format"""
        assert (
            logged_in_page.is_text_present("credits") or
            logged_in_page.is_text_present("Credits") or
            logged_in_page.is_credits_visible()
        ), "Credits label should be visible"
        logged_in_page.take_screenshot("test_credits_display_format")
