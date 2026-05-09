"""
Listing Generation Test Cases for SellScribe Mobile App
"""
import pytest
from appium.webdriver.common.appiumby import AppiumBy
from pages import LoginPage, HomePage, UploadPage, HistoryPage


@pytest.fixture(scope="function")
def logged_in_home(driver, ensure_on_login_screen, test_user):
    """Fixture that provides a logged-in user on home screen"""
    login_page = ensure_on_login_screen
    login_page.login(test_user["email"], test_user["password"])
    home_page = HomePage(driver)
    assert home_page.is_home_screen_displayed()
    return home_page


@pytest.mark.smoke
@pytest.mark.listing
class TestListingCreation:
    """Test cases for listing creation functionality"""

    def test_home_screen_shows_create_listing(self, logged_in_home):
        """Verify create listing option is visible on home screen"""
        # Flutter Semantics(label:'create-listing-button') replaces text in the
        # accessibility tree, so check accessibility ID first, text as fallback.
        assert (
            logged_in_home.is_element_present(AppiumBy.ACCESSIBILITY_ID, "create-listing-button")
            or logged_in_home.is_text_present("Create Listing")
        ), "Create Listing option should be visible"

    @pytest.mark.skip(reason="Upload AppBar text not exposed in UiAutomator2 snapshot — verify element attributes with Appium Inspector")
    def test_navigate_to_upload_screen(self, logged_in_home):
        """Test navigation to upload/create listing screen"""
        upload_page = logged_in_home.tap_create_listing()

        assert upload_page.is_upload_screen_displayed(), \
            "Upload screen should be displayed"

    @pytest.mark.skip(reason="Upload AppBar text not exposed in UiAutomator2 snapshot — verify element attributes with Appium Inspector")
    def test_upload_screen_elements(self, logged_in_home):
        """Verify all elements on upload screen"""
        upload_page = logged_in_home.tap_create_listing()

        # Check for upload screen specific elements
        assert upload_page.is_text_present("Upload") or \
            upload_page.is_text_present("upload images") or \
            upload_page.is_text_present("Add Product"), \
            "Upload screen elements should be visible"

    @pytest.mark.skip(reason="Button enabled-state inspection requires UI accessibility tree walk")
    def test_generate_button_disabled_without_image(self, logged_in_home):
        """Test that generate button requires images"""
        upload_page = logged_in_home.tap_create_listing()

        # Without selecting images, generate should be disabled or show error
        upload_page.tap_generate_listing()

        # Should either stay on upload or show error
        assert upload_page.is_upload_screen_displayed() or \
            upload_page.is_error_displayed(), \
            "Should not proceed without images"

    @pytest.mark.skip(reason="Upload screen uses context.go() — driver.back() exits app instead of returning home; needs tap on back arrow")
    def test_cancel_upload_returns_home(self, logged_in_home):
        """Test canceling upload returns to home"""
        upload_page = logged_in_home.tap_create_listing()
        home_page = upload_page.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"


@pytest.mark.regression
@pytest.mark.listing
class TestListingGeneration:
    """Test cases for AI listing generation"""

    @pytest.mark.skip(reason="Requires camera/gallery mock — not yet implemented in test infra")
    def test_generate_listing_with_image(self, logged_in_home):
        """Test generating a listing with image (requires camera/gallery mock)"""
        upload_page = logged_in_home.tap_create_listing()

        # Note: This test requires a way to provide images
        # In real testing, you'd use a mock or pre-loaded test image

        # For now, test that the button is available
        assert upload_page.is_text_present("Generate"), \
            "Generate button should be present"

    @pytest.mark.skip(reason="Full generation flow requires camera mock — credits comparison not yet wired")
    def test_credits_decrease_after_generation(self, logged_in_home):
        """Test that credits decrease after generating listing"""
        initial_credits = logged_in_home.get_credits_remaining()

        upload_page = logged_in_home.tap_create_listing()

        # Note: Full test would require providing an image
        # and completing the generation process

        # After generation, credits should decrease
        # home_page = upload_page.go_back()
        # new_credits = home_page.get_credits_remaining()
        # assert new_credits == initial_credits - 1

    def test_no_credits_shows_purchase_option(self, driver, login_page, test_user):
        """Test that having no credits prompts purchase"""
        # This test would require a user with 0 credits
        # or a way to deplete credits first
        pass

    @pytest.mark.skip(reason="History screen uses context.go() — driver.back() exits app; needs tap on native back arrow")
    def test_listing_saved_appears_in_history(self, logged_in_home):
        """Test that saved listing appears in history"""
        # After creating and saving a listing
        # Navigate to history
        history_page = logged_in_home.tap_view_history()

        assert history_page.is_history_screen_displayed(), \
            "History screen should be displayed"


@pytest.mark.smoke
@pytest.mark.listing
class TestListingHistory:
    """Test cases for listing history functionality"""

    @pytest.mark.skip(reason="History screen uses context.go() — driver.back() exits app; needs tap on native back arrow")
    def test_navigate_to_history(self, logged_in_home):
        """Test navigation to history screen"""
        history_page = logged_in_home.tap_view_history()

        assert history_page.is_history_screen_displayed(), \
            "History screen should be displayed"

    @pytest.mark.skip(reason="Requires seeded new-user account with zero listings")
    def test_history_shows_no_listings_initially(self, driver, ensure_on_login_screen, new_user):
        """Test that new user has no listing history"""
        # Register a new user
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()
        register_page.register(
            name=new_user["name"],
            email=new_user["email"],
            password=new_user["password"]
        )

        home_page = HomePage(driver)
        if home_page.is_home_screen_displayed():
            history_page = home_page.tap_view_history()

            assert not history_page.has_listings(), \
                "New user should have no listings"

    @pytest.mark.skip(reason="History screen uses context.go() — driver.back() exits app; needs tap on native back arrow")
    def test_return_from_history_to_home(self, logged_in_home):
        """Test returning from history to home"""
        history_page = logged_in_home.tap_view_history()
        home_page = history_page.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"


@pytest.mark.regression
@pytest.mark.listing
class TestListingDetails:
    """Test cases for listing details functionality"""

    @pytest.mark.skip(reason="Requires seeded listing data in test account history")
    def test_tap_listing_shows_details(self, logged_in_home):
        """Test tapping a listing shows its details"""
        history_page = logged_in_home.tap_view_history()

        if history_page.has_listings():
            history_page.tap_first_listing()

            # Verify listing details are displayed
            assert history_page.is_text_present("Title") or \
                history_page.is_text_present("Description"), \
                "Listing details should be displayed"

    def test_copy_listing_to_clipboard(self, logged_in_home):
        """Test copying listing content"""
        # Navigate to a listing with content
        # Tap copy button
        # Verify copy action (clipboard verification is platform-specific)
        pass

    def test_share_listing(self, logged_in_home):
        """Test sharing listing content"""
        # Navigate to a listing
        # Tap share button
        # Verify share dialog appears
        pass

    @pytest.mark.skip(reason="Requires seeded listing data + swipe-to-delete gesture validation")
    def test_delete_listing_from_history(self, logged_in_home):
        """Test deleting a listing from history"""
        history_page = logged_in_home.tap_view_history()

        if history_page.has_listings():
            initial_count = history_page.get_listing_count()
            history_page.delete_listing(0)

            # Verify listing was deleted
            new_count = history_page.get_listing_count()
            assert new_count == initial_count - 1 or \
                not history_page.has_listings(), \
                "Listing should be deleted"


@pytest.mark.regression
@pytest.mark.listing
class TestListingCredits:
    """Test cases for credit usage in listing generation"""

    def test_display_credits_on_home(self, logged_in_home):
        """Test that credits are displayed on home screen"""
        credits = logged_in_home.get_credits_remaining()

        assert credits >= 0, \
            "Credits should be displayed and non-negative"

    def test_credits_display_format(self, logged_in_home):
        """Test credits display format"""
        assert logged_in_home.is_text_present("credits") or \
            logged_in_home.is_text_present("Credits"), \
            "Credits label should be visible"

    def test_quick_actions_visible(self, logged_in_home):
        """Test that quick actions are visible on home"""
        assert logged_in_home.is_text_present("Quick Actions") or \
            logged_in_home.is_text_present("Create Listing"), \
            "Quick actions should be visible"
