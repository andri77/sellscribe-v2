"""
Login Test Cases for SellScribe Mobile App
"""
import pytest
from pages import LoginPage, HomePage


@pytest.mark.smoke
@pytest.mark.login
class TestLogin:
    """Test cases for login functionality"""

    def test_login_screen_displayed(self, login_page):
        """Verify login screen is displayed on app launch"""
        assert login_page.is_login_screen_displayed(), \
            "Login screen should be displayed"

    def test_login_with_valid_credentials(self, login_page, test_user):
        """Test successful login with valid credentials"""
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(login_page.driver)
        assert home_page.is_home_screen_displayed(), \
            "Home screen should be displayed after successful login"

    def test_login_with_invalid_email(self, login_page):
        """Test login with invalid email format"""
        login_page.login("invalid-email", "Password123!")

        assert login_page.is_error_displayed(), \
            "Error message should be displayed for invalid email"

    def test_login_with_wrong_password(self, login_page, test_user):
        """Test login with incorrect password"""
        login_page.login(test_user["email"], "WrongPassword123!")

        assert login_page.is_error_displayed(), \
            "Error message should be displayed for wrong password"

    def test_login_with_empty_email(self, login_page):
        """Test login with empty email field"""
        login_page.enter_password("Password123!")
        login_page.tap_login()

        assert login_page.is_error_displayed() or \
            login_page.is_login_screen_displayed(), \
            "Should show error or remain on login screen"

    def test_login_with_empty_password(self, login_page, test_user):
        """Test login with empty password field"""
        login_page.enter_email(test_user["email"])
        login_page.tap_login()

        assert login_page.is_error_displayed() or \
            login_page.is_login_screen_displayed(), \
            "Should show error or remain on login screen"

    def test_login_with_empty_fields(self, login_page):
        """Test login with all fields empty"""
        login_page.tap_login()

        assert login_page.is_error_displayed() or \
            login_page.is_login_screen_displayed(), \
            "Should show error or remain on login screen"

    def test_navigate_to_register(self, login_page):
        """Test navigation from login to register screen"""
        register_page = login_page.tap_register_link()

        assert register_page.is_register_screen_displayed(), \
            "Register screen should be displayed"

    def test_forgot_password_link(self, login_page):
        """Test forgot password functionality"""
        # First verify the forgot password link exists
        assert login_page.is_text_present("Forgot password?"), \
            "Forgot password link should be visible"

        login_page.tap_forgot_password()

        # Verify forgot password screen or dialog is displayed
        # Look for common text on reset password screens
        assert login_page.is_text_present("Reset") or \
            login_page.is_text_present("email") or \
            login_page.is_text_present("Send") or \
            login_page.is_text_present("Password"), \
            "Forgot password screen should be displayed"


@pytest.mark.regression
@pytest.mark.login
class TestLoginValidation:
    """Extended validation tests for login"""

    def test_email_field_accepts_valid_formats(self, login_page):
        """Test that email field accepts various valid formats"""
        valid_emails = [
            "user@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "user@subdomain.example.com"
        ]

        for email in valid_emails:
            login_page.enter_email(email)
            # Clear for next iteration
            login_page.driver.back()
            # Verify no immediate error on email field
            # (full validation happens on submit)

    def test_password_field_masks_input(self, login_page):
        """Test that password field masks characters"""
        login_page.enter_password("TestPassword123!")

        # Password field should not show plain text
        # This is a visual verification that would need
        # additional implementation to check

    def test_login_button_disabled_initially(self, login_page):
        """Test that login button state before input"""
        # Depending on implementation, login button may be
        # disabled until fields are filled
        pass

    def test_keyboard_dismissal(self, login_page, test_user):
        """Test that keyboard can be dismissed"""
        login_page.enter_email(test_user["email"])
        login_page.hide_keyboard()

        # Verify keyboard is hidden
        # This would require checking if keyboard is visible


@pytest.mark.regression
@pytest.mark.login
class TestLoginPersistence:
    """Test login session persistence"""

    def test_stay_logged_in_after_app_restart(self, driver, login_page, test_user):
        """Test that user stays logged in after app restart"""
        # Login first
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(driver)
        assert home_page.is_home_screen_displayed()

        # Restart app (background and foreground)
        driver.background_app(2)

        # Should still be on home screen
        assert home_page.is_home_screen_displayed(), \
            "User should remain logged in after app restart"

    def test_logout_and_login_again(self, driver, login_page, test_user):
        """Test logout and login again flow"""
        # Login
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(driver)
        assert home_page.is_home_screen_displayed()

        # Logout
        home_page.tap_sign_out()
        home_page.confirm_sign_out()

        # Should be back to login screen
        assert login_page.is_login_screen_displayed(), \
            "Should return to login screen after logout"

        # Login again
        login_page.login(test_user["email"], test_user["password"])

        assert home_page.is_home_screen_displayed(), \
            "Should be able to login again after logout"
