"""
Settings and Profile Test Cases for SellScribe Mobile App
"""
import pytest
from pages import HomePage, SettingsPage


# First and last name are required to save the profile form
REQUIRED_NAMES = {"first_name": "Test", "last_name": "User"}


@pytest.fixture(scope="function")
def logged_in_settings(logged_in_home):
    """Settings screen for the signed-in test user"""
    settings_page = logged_in_home.tap_settings()
    assert settings_page.is_settings_screen_displayed()
    return settings_page


@pytest.fixture(scope="function")
def isolated_logged_in_settings(isolated_logged_in_home):
    """Settings screen with a session of its own, for tests that sign out"""
    settings_page = isolated_logged_in_home.tap_settings()
    assert settings_page.is_settings_screen_displayed()
    return settings_page


@pytest.mark.smoke
@pytest.mark.settings
class TestSettingsNavigation:
    """Test cases for settings navigation"""

    def test_navigate_to_settings(self, logged_in_home):
        """Test navigation to settings screen"""
        settings_page = logged_in_home.tap_settings()

        assert settings_page.is_settings_screen_displayed(), \
            "Settings screen should be displayed"

    def test_settings_options_visible(self, logged_in_settings):
        """Test that all settings options are visible"""
        for option in (SettingsPage.EDIT_PROFILE_TILE_ID, SettingsPage.THEME_BUTTON_ID,
                       SettingsPage.PAYMENT_METHODS_TILE_ID, SettingsPage.PURCHASE_CREDITS_TILE_ID,
                       SettingsPage.SIGN_OUT_BUTTON_ID):
            assert logged_in_settings.is_option_displayed(option), f"{option} should be visible"

    def test_return_from_settings_to_home(self, logged_in_settings):
        """Test returning from settings to home"""
        home_page = logged_in_settings.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"


@pytest.mark.smoke
@pytest.mark.profile
class TestProfileEdit:
    """Test cases for profile editing (these update the shared test user's profile)"""

    def test_navigate_to_profile_edit(self, logged_in_settings):
        """Test navigation to profile edit screen"""
        profile_page = logged_in_settings.tap_edit_profile()

        assert profile_page.is_profile_edit_screen_displayed(), \
            "Profile edit screen should be displayed"

    def test_profile_edit_fields_present(self, logged_in_settings):
        """Test that all profile edit fields are present"""
        profile_page = logged_in_settings.tap_edit_profile()

        for field in (profile_page.FIRST_NAME_INPUT_ID, profile_page.LAST_NAME_INPUT_ID,
                      profile_page.MOBILE_INPUT_ID, profile_page.ADDRESS_INPUT_ID,
                      profile_page.CITY_INPUT_ID, profile_page.STATE_INPUT_ID,
                      profile_page.ZIP_CODE_INPUT_ID, profile_page.COUNTRY_INPUT_ID):
            assert profile_page.is_field_displayed(field), f"{field} should be visible"

    def test_update_first_name(self, logged_in_settings):
        """Test updating first name"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.fill_profile(first_name="John", last_name="User")
        settings_page = profile_page.tap_save()

        assert settings_page.is_settings_screen_displayed(), \
            "Saving should return to settings"

    def test_update_last_name(self, logged_in_settings):
        """Test updating last name"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.fill_profile(first_name="Test", last_name="Doe")
        settings_page = profile_page.tap_save()

        assert settings_page.is_settings_screen_displayed(), \
            "Saving should return to settings"

    def test_update_mobile_number(self, logged_in_settings):
        """Test updating mobile number"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.fill_profile(**REQUIRED_NAMES, mobile="+1234567890")
        settings_page = profile_page.tap_save()

        assert settings_page.is_settings_screen_displayed(), \
            "Saving should return to settings"

    def test_update_address(self, logged_in_settings):
        """Test updating address fields"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.fill_profile(
            **REQUIRED_NAMES,
            address="123 Main St",
            city="Springfield",
            state="IL",
            zip_code="62701",
            country="USA"
        )
        settings_page = profile_page.tap_save()

        assert settings_page.is_settings_screen_displayed(), \
            "Saving should return to settings"

    def test_update_full_profile(self, logged_in_settings):
        """Test updating all profile fields"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.fill_profile(
            first_name="Jane",
            last_name="Smith",
            mobile="+0987654321",
            address="456 Oak Ave",
            city="Metropolis",
            state="NY",
            zip_code="10001",
            country="USA"
        )
        settings_page = profile_page.tap_save()

        assert settings_page.is_settings_screen_displayed(), \
            "Saving should return to settings"

    def test_cancel_profile_edit(self, logged_in_settings):
        """Test canceling profile edit"""
        profile_page = logged_in_settings.tap_edit_profile()
        settings_page = profile_page.go_back()

        assert settings_page.is_settings_screen_displayed(), \
            "Should return to settings without saving"


@pytest.mark.smoke
@pytest.mark.settings
class TestThemeSettings:
    """Test cases for theme settings"""

    def test_theme_option_visible(self, logged_in_settings):
        """Test that theme option is visible"""
        assert logged_in_settings.is_option_displayed(SettingsPage.THEME_BUTTON_ID), \
            "Theme option should be visible"

    @pytest.mark.parametrize("theme", [SettingsPage.THEME_LIGHT, SettingsPage.THEME_DARK,
                                       SettingsPage.THEME_SYSTEM])
    def test_set_theme(self, logged_in_settings, theme):
        """Test choosing each theme"""
        logged_in_settings.select_theme(theme)

        assert logged_in_settings.is_settings_screen_displayed(), \
            "Should remain on settings after theme change"
        assert logged_in_settings.get_current_theme() == theme, \
            f"Theme tile should show {theme}"

    def test_theme_persists_after_restart(self, driver, logged_in_settings):
        """Test that the theme setting survives the app being backgrounded"""
        logged_in_settings.set_dark_theme()

        driver.background_app(2)

        assert logged_in_settings.is_settings_screen_displayed(), \
            "App should come back on settings"
        assert logged_in_settings.get_current_theme() == SettingsPage.THEME_DARK, \
            "Dark theme should still be selected"


@pytest.mark.regression
@pytest.mark.payment
class TestPaymentMethods:
    """Test cases for payment methods"""

    def test_navigate_to_payment_methods(self, logged_in_settings):
        """Test navigation to payment methods"""
        payment_page = logged_in_settings.tap_payment_methods()

        assert payment_page.is_payment_methods_screen_displayed(), \
            "Payment methods screen should be displayed"

    def test_add_card_button_visible(self, logged_in_settings):
        """Test that the add card form opens"""
        payment_page = logged_in_settings.tap_payment_methods()
        payment_page.tap_add_card()

        assert payment_page.is_add_card_form_displayed(), \
            "Add card form should open"

    @pytest.mark.skip(reason="Saves a card to the shared test account; enable once tests "
                             "clean up after themselves")
    def test_add_new_card(self, logged_in_settings):
        """Test adding a new card"""
        payment_page = logged_in_settings.tap_payment_methods()

        payment_page.add_card(
            card_number="4242424242424242",
            expiry="12/30",
            cvv="123",
            name="Test User"
        )

        assert not payment_page.is_add_card_form_displayed(timeout=3), \
            "Card form should close once the card is saved"

    def test_add_card_validation(self, logged_in_settings):
        """Test card validation"""
        payment_page = logged_in_settings.tap_payment_methods()

        payment_page.tap_add_card()
        payment_page.enter_card_number("1234")  # Invalid
        payment_page.tap_save_card()

        assert payment_page.is_add_card_form_displayed(), \
            "Form should stay open for an invalid card"

    def test_return_from_payment_methods(self, logged_in_settings):
        """Test returning from payment methods"""
        payment_page = logged_in_settings.tap_payment_methods()
        settings_page = payment_page.go_back()

        assert settings_page.is_settings_screen_displayed(), \
            "Should return to settings"


@pytest.mark.regression
@pytest.mark.payment
class TestPurchaseCredits:
    """Test cases for purchasing credits"""

    def test_navigate_to_purchase_credits(self, logged_in_settings):
        """Test navigation to purchase credits"""
        purchase_page = logged_in_settings.tap_purchase_credits()

        assert purchase_page.is_purchase_credits_screen_displayed(), \
            "Purchase credits screen should be displayed"

    def test_credit_packages_visible(self, logged_in_settings):
        """Test that credit packages are visible"""
        purchase_page = logged_in_settings.tap_purchase_credits()

        assert purchase_page.are_packages_displayed(), \
            "All credit packages should be visible"

    def test_current_credits_displayed(self, logged_in_settings):
        """Test that current credits are displayed"""
        purchase_page = logged_in_settings.tap_purchase_credits()

        assert purchase_page.get_current_credits() >= 0, \
            "Current credits should be displayed"

    def test_select_credit_package(self, logged_in_settings):
        """Test selecting a credit package"""
        purchase_page = logged_in_settings.tap_purchase_credits()

        purchase_page.select_10_credits()

        assert purchase_page.is_purchase_credits_screen_displayed(), \
            "Should remain on purchase screen"

    def test_purchase_returns_to_settings(self, logged_in_settings):
        """Purchasing is still a mock (TODO in purchase_credits_screen.dart): it confirms
        and goes back to settings without charging or adding credits"""
        purchase_page = logged_in_settings.tap_purchase_credits()
        purchase_page.select_10_credits()
        purchase_page.tap_purchase()

        assert logged_in_settings.is_settings_screen_displayed(), \
            "Should return to settings after the purchase"

    def test_return_from_purchase_credits(self, logged_in_settings):
        """Test returning from purchase credits"""
        purchase_page = logged_in_settings.tap_purchase_credits()
        settings_page = purchase_page.go_back()

        assert settings_page.is_settings_screen_displayed(), \
            "Should return to settings"


@pytest.mark.smoke
@pytest.mark.settings
class TestSignOut:
    """Test cases for sign out functionality"""

    def test_sign_out_option_visible(self, logged_in_settings):
        """Test that sign out option is visible"""
        logged_in_settings.scroll_to(logged_in_settings.by_id(SettingsPage.SIGN_OUT_BUTTON_ID))

        assert logged_in_settings.is_option_displayed(SettingsPage.SIGN_OUT_BUTTON_ID), \
            "Sign Out option should be visible"

    def test_sign_out_shows_confirmation(self, logged_in_settings):
        """Test that sign out shows confirmation dialog"""
        logged_in_settings.tap_sign_out()

        assert logged_in_settings.is_sign_out_dialog_displayed(), \
            "Confirmation dialog should appear"

    def test_sign_out_success(self, isolated_logged_in_settings):
        """Test successful sign out (own session: signing out revokes it)"""
        isolated_logged_in_settings.tap_sign_out()
        login_page = isolated_logged_in_settings.confirm_sign_out()

        assert login_page.is_login_screen_displayed(), \
            "Should return to login screen after sign out"

    def test_cancel_sign_out(self, logged_in_settings):
        """Test canceling sign out"""
        logged_in_settings.tap_sign_out()
        logged_in_settings.cancel_sign_out()

        assert logged_in_settings.is_settings_screen_displayed(), \
            "Should remain on settings after canceling"
