"""
Listing Generation Test Cases for SellScribe Mobile App
"""
import pytest
from pages import HomePage, DetailsPage


@pytest.mark.smoke
@pytest.mark.listing
class TestListingCreation:
    """Test cases for listing creation functionality"""

    def test_home_screen_shows_create_listing(self, logged_in_home):
        """Verify create listing option is visible on home screen"""
        assert logged_in_home.is_present(logged_in_home.by_id(HomePage.CREATE_LISTING_BUTTON_ID)), \
            "Create Listing option should be visible"

    def test_navigate_to_upload_screen(self, logged_in_home):
        """Test navigation to upload/create listing screen"""
        upload_page = logged_in_home.tap_create_listing()

        assert upload_page.is_upload_screen_displayed(), \
            "Upload screen should be displayed"

    def test_upload_screen_elements(self, logged_in_home):
        """Verify all elements on upload screen"""
        upload_page = logged_in_home.tap_create_listing()

        assert upload_page.is_upload_screen_displayed(), "Upload area should be visible"
        assert upload_page.is_continue_displayed(), "Continue button should be visible"

    def test_continue_without_image_opens_details(self, logged_in_home):
        """Images are optional: Continue without any goes on to the product details"""
        upload_page = logged_in_home.tap_create_listing()

        upload_page.tap_continue()

        assert DetailsPage(upload_page.driver).is_details_screen_displayed(), \
            "Details screen should open without images"

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

    @pytest.mark.skip(reason="Full generation flow requires camera mock — credits comparison not yet wired")
    def test_credits_decrease_after_generation(self, logged_in_home):
        """Test that credits decrease after generating listing"""

    @pytest.mark.skip(reason="Needs a test user with 0 credits")
    def test_no_credits_shows_purchase_option(self, logged_in_home):
        """Test that having no credits prompts purchase"""

    @pytest.mark.skip(reason="Needs a generated listing (camera/gallery mock)")
    def test_listing_saved_appears_in_history(self, logged_in_home):
        """Test that saved listing appears in history"""


@pytest.mark.smoke
@pytest.mark.listing
class TestListingHistory:
    """Test cases for listing history functionality"""

    def test_navigate_to_history(self, logged_in_home):
        """Test navigation to history screen"""
        history_page = logged_in_home.tap_view_history()

        assert history_page.is_history_screen_displayed(), \
            "History screen should be displayed"

    def test_history_shows_no_listings_initially(self, driver, ensure_on_login_screen, new_user):
        """Test that new user has no listing history"""
        register_page = ensure_on_login_screen.tap_register_link()
        register_page.register(
            name=new_user["name"],
            email=new_user["email"].replace("newuser_", "history_"),
            password=new_user["password"]
        )

        home_page = HomePage(driver)
        if not home_page.is_home_screen_displayed():
            pytest.skip("Sign-up needs email confirmation, so the new user can't reach home")

        history_page = home_page.tap_view_history()

        assert not history_page.has_listings(), \
            "New user should have no listings"

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

    def test_tap_listing_shows_details(self, logged_in_home):
        """Test tapping a listing leaves the history list for its details"""
        history_page = logged_in_home.tap_view_history()

        if not history_page.has_listings():
            pytest.skip("Test account has no listings")

        history_page.tap_first_listing()

        assert not history_page.is_history_screen_displayed(timeout=3), \
            "Listing details should be displayed"

    @pytest.mark.skip(reason="Placeholder: needs a generated listing and a clipboard check")
    def test_copy_listing_to_clipboard(self, logged_in_home):
        """Test copying listing content"""

    @pytest.mark.skip(reason="Placeholder: needs a generated listing and share-sheet handling")
    def test_share_listing(self, logged_in_home):
        """Test sharing listing content"""

    @pytest.mark.skip(reason="Deletes a listing from the shared test account; enable with "
                             "seeded, disposable data")
    def test_delete_listing_from_history(self, logged_in_home):
        """Test deleting a listing from history"""
        history_page = logged_in_home.tap_view_history()

        initial_count = history_page.get_listing_count()
        history_page.delete_listing(0)

        assert history_page.get_listing_count() == initial_count - 1, \
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
        assert logged_in_home.read_text(HomePage.CREDITS_COUNT_ID).isdigit(), \
            "Credits counter should show a whole number"

    def test_quick_actions_visible(self, logged_in_home):
        """Test that quick actions are visible on home"""
        for action in (HomePage.CREATE_LISTING_BUTTON_ID, HomePage.VIEW_HISTORY_BUTTON_ID):
            assert logged_in_home.is_present(logged_in_home.by_id(action)), \
                f"{action} should be visible"
