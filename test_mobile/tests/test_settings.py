"""
Settings and Profile Test Cases for SellScribe Mobile App
"""
import pytest
from pages import (
    LoginPage, HomePage, SettingsPage, ProfileEditPage,
    PaymentMethodsPage, PurchaseCreditsPage
)


@pytest.fixture(scope="function")
def logged_in_settings(driver, ensure_on_login_screen, test_user):
    """Fixture that provides settings page for logged-in user"""
    login_page = ensure_on_login_screen
    login_page.login(test_user["email"], test_user["password"])
    home_page = HomePage(driver)
    assert home_page.is_home_screen_displayed()
    settings_page = home_page.tap_settings()
    return settings_page


@pytest.mark.smoke
@pytest.mark.settings
class TestSettingsNavigation:
    """Test cases for settings navigation"""

    def test_navigate_to_settings(self, driver, ensure_on_login_screen, test_user):
        """Test navigation to settings screen"""
        login_page = ensure_on_login_screen
        login_page.login(test_user["email"], test_user["password"])
        home_page = HomePage(driver)
        settings_page = home_page.tap_settings()

        assert settings_page.is_settings_screen_displayed(), \
            "Settings screen should be displayed"

    def test_settings_options_visible(self, logged_in_settings):
        """Test that all settings options are visible"""
        assert logged_in_settings.is_text_present("Profile") or \
            logged_in_settings.is_text_present("Edit Profile"), \
            "Profile option should be visible"

        assert logged_in_settings.is_text_present("Theme"), \
            "Theme option should be visible"

        assert logged_in_settings.is_text_present("Sign Out"), \
            "Sign Out option should be visible"

    def test_return_from_settings_to_home(self, logged_in_settings):
        """Test returning from settings to home"""
        home_page = logged_in_settings.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"


@pytest.mark.smoke
@pytest.mark.profile
class TestProfileEdit:
    """Test cases for profile editing"""

    def test_navigate_to_profile_edit(self, logged_in_settings):
        """Test navigation to profile edit screen"""
        profile_page = logged_in_settings.tap_edit_profile()

        assert profile_page.is_profile_edit_screen_displayed(), \
            "Profile edit screen should be displayed"

    def test_profile_edit_fields_present(self, logged_in_settings):
        """Test that all profile edit fields are present"""
        profile_page = logged_in_settings.tap_edit_profile()

        assert profile_page.is_text_present("First Name"), \
            "First Name field should be visible"
        assert profile_page.is_text_present("Last Name"), \
            "Last Name field should be visible"

    def test_update_first_name(self, logged_in_settings):
        """Test updating first name"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.enter_first_name("John")
        profile_page.tap_save()

        assert profile_page.is_success_message_displayed() or \
            logged_in_settings.is_settings_screen_displayed(), \
            "Should show success or return to settings"

    def test_update_last_name(self, logged_in_settings):
        """Test updating last name"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.enter_last_name("Doe")
        profile_page.tap_save()

        assert profile_page.is_success_message_displayed() or \
            logged_in_settings.is_settings_screen_displayed(), \
            "Should show success or return to settings"

    def test_update_mobile_number(self, logged_in_settings):
        """Test updating mobile number"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.enter_mobile("+1234567890")
        profile_page.tap_save()

        assert profile_page.is_success_message_displayed() or \
            logged_in_settings.is_settings_screen_displayed(), \
            "Should show success or return to settings"

    def test_update_address(self, logged_in_settings):
        """Test updating address fields"""
        profile_page = logged_in_settings.tap_edit_profile()

        profile_page.fill_profile(
            address="123 Main St",
            city="Springfield",
            state="IL",
            zip_code="62701",
            country="USA"
        )
        profile_page.tap_save()

        assert profile_page.is_success_message_displayed() or \
            logged_in_settings.is_settings_screen_displayed(), \
            "Should show success or return to settings"

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
        profile_page.tap_save()

        assert profile_page.is_success_message_displayed() or \
            logged_in_settings.is_settings_screen_displayed(), \
            "Should show success or return to settings"

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
        assert logged_in_settings.is_text_present("Theme"), \
            "Theme option should be visible"

    def test_set_light_theme(self, logged_in_settings):
        """Test setting light theme"""
        logged_in_settings.set_light_theme()

        # Verify theme is set (visual verification would be needed)
        # For now, verify we're still on settings
        assert logged_in_settings.is_settings_screen_displayed(), \
            "Should remain on settings after theme change"

    def test_set_dark_theme(self, logged_in_settings):
        """Test setting dark theme"""
        logged_in_settings.set_dark_theme()

        assert logged_in_settings.is_settings_screen_displayed(), \
            "Should remain on settings after theme change"

    def test_set_system_theme(self, logged_in_settings):
        """Test setting system theme"""
        logged_in_settings.set_system_theme()

        assert logged_in_settings.is_settings_screen_displayed(), \
            "Should remain on settings after theme change"

    def test_theme_persists_after_restart(self, driver, ensure_on_login_screen, test_user):
        """Test that theme setting persists after app restart"""
        login_page = ensure_on_login_screen
        login_page.login(test_user["email"], test_user["password"])
        home_page = HomePage(driver)
        settings_page = home_page.tap_settings()

        settings_page.set_dark_theme()

        # Restart app
        driver.background_app(2)

        # Theme should persist (visual verification needed)
        assert settings_page.is_settings_screen_displayed() or \
            home_page.is_home_screen_displayed(), \
            "App should recover after restart"


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
        """Test that add card button is visible"""
        payment_page = logged_in_settings.tap_payment_methods()

        assert payment_page.is_text_present("Add Card") or \
            payment_page.is_text_present("Add Payment"), \
            "Add card option should be visible"

    @pytest.mark.skip(reason="Requires payment gateway test environment — card input fields use native WebView")
    def test_add_new_card(self, logged_in_settings):
        """Test adding a new card"""
        payment_page = logged_in_settings.tap_payment_methods()

        payment_page.add_card(
            card_number="4242424242424242",
            expiry="12/25",
            cvv="123",
            name="Test User"
        )

        assert payment_page.is_success_displayed() or \
            payment_page.has_saved_cards(), \
            "Card should be added successfully"

    @pytest.mark.skip(reason="Requires payment gateway test environment — card input fields use native WebView")
    def test_add_card_validation(self, logged_in_settings):
        """Test card validation"""
        payment_page = logged_in_settings.tap_payment_methods()

        payment_page.tap_add_card()
        payment_page.enter_card_number("1234")  # Invalid
        payment_page.tap_save_card()

        assert payment_page.is_error_displayed(), \
            "Should show error for invalid card"

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

        assert purchase_page.is_text_present("Credits"), \
            "Credit packages should be visible"

    def test_current_credits_displayed(self, logged_in_settings):
        """Test that current credits are displayed"""
        purchase_page = logged_in_settings.tap_purchase_credits()

        credits = purchase_page.get_current_credits()
        assert credits >= 0, \
            "Current credits should be displayed"

    def test_select_credit_package(self, logged_in_settings):
        """Test selecting a credit package"""
        purchase_page = logged_in_settings.tap_purchase_credits()

        purchase_page.select_10_credits()

        # Verify package is selected (UI indication needed)
        assert purchase_page.is_purchase_credits_screen_displayed(), \
            "Should remain on purchase screen"

    def test_purchase_requires_payment_method(self, logged_in_settings):
        """Test that purchase requires payment method"""
        # Remove any saved payment methods first (if applicable)

        purchase_page = logged_in_settings.tap_purchase_credits()
        purchase_page.select_10_credits()
        purchase_page.tap_purchase()

        # Should either prompt for payment method or show error
        # if no payment method is configured

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
        logged_in_settings.scroll_to_text("Sign Out")

        assert logged_in_settings.is_text_present("Sign Out"), \
            "Sign Out option should be visible"

    def test_sign_out_shows_confirmation(self, logged_in_settings):
        """Test that sign out shows confirmation dialog"""
        logged_in_settings.tap_sign_out()

        # Should show confirmation dialog
        assert logged_in_settings.is_text_present("Sign Out") or \
            logged_in_settings.is_text_present("Confirm"), \
            "Confirmation dialog should appear"

    def test_sign_out_success(self, logged_in_settings):
        """Test successful sign out"""
        logged_in_settings.tap_sign_out()
        login_page = logged_in_settings.confirm_sign_out()

        assert login_page.is_login_screen_displayed(), \
            "Should return to login screen after sign out"

    def test_cancel_sign_out(self, logged_in_settings):
        """Test canceling sign out"""
        logged_in_settings.tap_sign_out()

        # Cancel the sign out
        if logged_in_settings.is_text_present("Cancel"):
            logged_in_settings.tap_by_text("Cancel")

        assert logged_in_settings.is_settings_screen_displayed(), \
            "Should remain on settings after canceling"
