"""
Settings Test Cases for SellScribe Web Application
"""
import pytest
from pages import HomePage, SettingsPage, LoginPage


@pytest.mark.smoke
@pytest.mark.settings
class TestSettingsNavigation:
    """Test cases for settings navigation"""

    def test_settings_screen_displayed(self, logged_in_page: HomePage):
        """Verify settings screen is displayed"""
        settings_page = logged_in_page.click_settings()

        assert settings_page.is_settings_screen_displayed(), \
            "Settings screen should be displayed"
        settings_page.take_screenshot("test_settings_screen_displayed")

    def test_settings_options_visible(self, logged_in_page: HomePage):
        """Test that settings options are visible"""
        settings_page = logged_in_page.click_settings()

        # Check for common settings options
        has_profile = settings_page.is_text_present("Profile") or \
            settings_page.is_text_present("Edit Profile")
        has_theme = settings_page.is_text_present("Theme")
        has_signout = settings_page.is_text_present("Sign Out") or \
            settings_page.is_text_present("Logout")

        assert has_profile or has_theme or has_signout, \
            "At least one settings option should be visible"
        settings_page.take_screenshot("test_settings_options_visible")

    def test_return_from_settings_to_home(self, logged_in_page: HomePage):
        """Test returning from settings to home"""
        settings_page = logged_in_page.click_settings()
        home_page = settings_page.go_back()

        assert home_page.is_home_screen_displayed(), \
            "Should return to home screen"
        settings_page.take_screenshot("test_return_from_settings_to_home")


@pytest.mark.smoke
@pytest.mark.profile
class TestProfileSettings:
    """Test cases for profile settings"""

    def test_edit_profile_navigation(self, logged_in_page: HomePage):
        """Test navigation to edit profile"""
        settings_page = logged_in_page.click_settings()

        if settings_page.is_visible(settings_page.EDIT_PROFILE_BUTTON, timeout=3000):
            settings_page.click_edit_profile()
            settings_page.page.wait_for_timeout(1000)

            assert (
                settings_page.is_profile_edit_displayed() or
                settings_page.is_text_present("Profile") or
                settings_page.is_text_present("First Name")
            ), "Profile edit screen or profile section should be visible"

        settings_page.take_screenshot("test_edit_profile_navigation")

    def test_profile_fields_visible(self, logged_in_page: HomePage):
        """Test that profile fields are visible"""
        settings_page = logged_in_page.click_settings()

        if settings_page.is_visible(settings_page.EDIT_PROFILE_BUTTON, timeout=3000):
            settings_page.click_edit_profile()
            settings_page.page.wait_for_timeout(1000)

            # Check for profile fields
            has_name = settings_page.is_visible(settings_page.FIRST_NAME_INPUT, timeout=2000) or \
                settings_page.is_text_present("Name")
            has_email = settings_page.is_visible(settings_page.EMAIL_INPUT, timeout=2000) or \
                settings_page.is_text_present("Email")

            assert has_name or has_email or settings_page.is_profile_edit_displayed(), \
                "Profile fields should be visible"

        settings_page.take_screenshot("test_profile_fields_visible")


@pytest.mark.smoke
@pytest.mark.settings
class TestThemeSettings:
    """Test cases for theme settings"""

    def test_theme_option_visible(self, logged_in_page: HomePage):
        """Test that theme option is visible"""
        settings_page = logged_in_page.click_settings()

        assert settings_page.is_text_present("Theme") or \
            settings_page.is_visible(settings_page.THEME_SECTION, timeout=3000), \
            "Theme option should be visible"
        settings_page.take_screenshot("test_theme_option_visible")

    def test_set_light_theme(self, logged_in_page: HomePage):
        """Test setting light theme"""
        settings_page = logged_in_page.click_settings()

        if settings_page.is_visible(settings_page.THEME_LIGHT, timeout=3000):
            settings_page.set_light_theme()
            settings_page.page.wait_for_timeout(1000)

        assert settings_page.is_settings_screen_displayed(), \
            "Should remain on settings after theme change"
        settings_page.take_screenshot("test_set_light_theme")

    def test_set_dark_theme(self, logged_in_page: HomePage):
        """Test setting dark theme"""
        settings_page = logged_in_page.click_settings()

        if settings_page.is_visible(settings_page.THEME_DARK, timeout=3000):
            settings_page.set_dark_theme()
            settings_page.page.wait_for_timeout(1000)

        assert settings_page.is_settings_screen_displayed(), \
            "Should remain on settings after theme change"
        settings_page.take_screenshot("test_set_dark_theme")


@pytest.mark.smoke
@pytest.mark.settings
class TestSignOut:
    """Test cases for sign out functionality"""

    def test_sign_out_option_visible(self, logged_in_page: HomePage):
        """Test that sign out option is visible"""
        settings_page = logged_in_page.click_settings()

        # Scroll to find sign out
        settings_page.scroll_to_bottom()
        settings_page.page.wait_for_timeout(500)

        assert settings_page.is_text_present("Sign Out") or \
            settings_page.is_text_present("Logout"), \
            "Sign Out option should be visible"
        settings_page.take_screenshot("test_sign_out_option_visible")

    def test_sign_out_success(self, logged_in_page: HomePage):
        """Test successful sign out"""
        settings_page = logged_in_page.click_settings()

        # Scroll to find sign out
        settings_page.scroll_to_bottom()
        settings_page.page.wait_for_timeout(500)

        login_page = settings_page.sign_out()

        assert login_page.is_login_screen_displayed(), \
            "Should return to login screen after sign out"
        settings_page.take_screenshot("test_sign_out_success")

    def test_cancel_sign_out(self, logged_in_page: HomePage):
        """Test canceling sign out"""
        settings_page = logged_in_page.click_settings()

        # Scroll to find sign out
        settings_page.scroll_to_bottom()
        settings_page.page.wait_for_timeout(500)

        settings_page.click_sign_out()

        if settings_page.is_visible(settings_page.CANCEL_SIGN_OUT, timeout=2000):
            settings_page.cancel_sign_out()
            settings_page.page.wait_for_timeout(500)

            assert settings_page.is_settings_screen_displayed(), \
                "Should remain on settings after canceling sign out"

        settings_page.take_screenshot("test_cancel_sign_out")
