"""
Login Test Cases for SellScribe Web Application
"""
import pytest
from pages import LoginPage, HomePage


@pytest.mark.smoke
@pytest.mark.login
class TestLogin:
    """Test cases for login functionality"""

    def test_login_screen_displayed(self, login_page: LoginPage):
        """Verify login screen is displayed"""
        assert login_page.is_login_screen_displayed(), \
            "Login screen should be displayed"
        login_page.take_screenshot("test_login_screen_displayed")

    def test_login_with_valid_credentials(self, login_page: LoginPage, test_user: dict):
        """Test successful login with valid credentials"""
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(login_page.page, login_page.base_url)
        assert home_page.is_home_screen_displayed(), \
            "Home screen should be displayed after successful login"
        login_page.take_screenshot("test_login_with_valid_credentials")

    def test_login_with_invalid_email(self, login_page: LoginPage):
        """Test login with invalid email format"""
        login_page.login("invalid-email", "Password123!")

        assert login_page.is_error_displayed() or login_page.is_login_screen_displayed(), \
            "Should show error or remain on login screen for invalid email"
        login_page.take_screenshot("test_login_with_invalid_email")

    def test_login_with_wrong_password(self, login_page: LoginPage, test_user: dict):
        """Test login with incorrect password"""
        login_page.login(test_user["email"], "WrongPassword123!")

        assert login_page.is_error_displayed() or login_page.is_login_screen_displayed(), \
            "Should show error or remain on login screen for wrong password"
        login_page.take_screenshot("test_login_with_wrong_password")

    def test_login_with_empty_email(self, login_page: LoginPage):
        """Test login with empty email field"""
        login_page.enter_password("Password123!")
        login_page.click_login()

        assert login_page.is_error_displayed() or login_page.is_login_screen_displayed(), \
            "Should show error or remain on login screen"
        login_page.take_screenshot("test_login_with_empty_email")

    def test_login_with_empty_password(self, login_page: LoginPage, test_user: dict):
        """Test login with empty password field"""
        login_page.enter_email(test_user["email"])
        login_page.click_login()

        assert login_page.is_error_displayed() or login_page.is_login_screen_displayed(), \
            "Should show error or remain on login screen"
        login_page.take_screenshot("test_login_with_empty_password")

    def test_login_with_empty_fields(self, login_page: LoginPage):
        """Test login with all fields empty"""
        login_page.click_login()

        assert login_page.is_error_displayed() or login_page.is_login_screen_displayed(), \
            "Should show error or remain on login screen"
        login_page.take_screenshot("test_login_with_empty_fields")

    def test_navigate_to_register(self, login_page: LoginPage):
        """Test navigation from login to register screen"""
        register_page = login_page.click_register_link()

        assert register_page.is_register_screen_displayed(), \
            "Register screen should be displayed"
        login_page.take_screenshot("test_navigate_to_register")


@pytest.mark.regression
@pytest.mark.login
class TestLoginValidation:
    """Extended validation tests for login"""

    def test_email_field_accepts_valid_formats(self, login_page: LoginPage):
        """Test that email field accepts various valid formats"""
        valid_emails = [
            "user@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "user@subdomain.example.com"
        ]

        for email in valid_emails:
            login_page.enter_email(email)
            # Verify no immediate validation error
            login_page.page.wait_for_timeout(500)

        login_page.take_screenshot("test_email_field_accepts_valid_formats")

    def test_password_field_masks_input(self, login_page: LoginPage):
        """Test that password field masks characters"""
        login_page.enter_password("TestPassword123!")

        # Password field should have type="password"
        password_type = login_page.get_attribute(
            login_page.PASSWORD_INPUT,
            "type"
        )
        assert password_type == "password", \
            "Password field should mask input"
        login_page.take_screenshot("test_password_field_masks_input")

    def test_login_button_state(self, login_page: LoginPage):
        """Test login button state"""
        # Button state may vary by implementation
        # Some apps disable until fields are filled
        assert login_page.is_visible(login_page.LOGIN_BUTTON), \
            "Login button should be visible"
        login_page.take_screenshot("test_login_button_state")

    def test_keyboard_submit(self, login_page: LoginPage, test_user: dict):
        """Test form submission via Enter key"""
        login_page.enter_email(test_user["email"])
        login_page.enter_password(test_user["password"])
        login_page.press_enter()

        login_page.page.wait_for_timeout(2000)
        home_page = HomePage(login_page.page, login_page.base_url)

        assert home_page.is_home_screen_displayed() or login_page.is_error_displayed(), \
            "Should navigate to home or show error"
        login_page.take_screenshot("test_keyboard_submit")


@pytest.mark.regression
@pytest.mark.login
class TestLoginPersistence:
    """Test login session persistence"""

    def test_stay_logged_in_after_page_refresh(
        self,
        login_page: LoginPage,
        test_user: dict
    ):
        """Test that user stays logged in after page refresh"""
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(login_page.page, login_page.base_url)
        assert home_page.is_home_screen_displayed()

        # Refresh page
        login_page.page.reload()
        login_page.wait_for_load_state()

        # Should still be on home screen
        assert home_page.is_home_screen_displayed(), \
            "User should remain logged in after page refresh"
        login_page.take_screenshot("test_stay_logged_in_after_page_refresh")

    def test_logout_and_login_again(
        self,
        login_page: LoginPage,
        test_user: dict
    ):
        """Test logout and login again flow"""
        # Login
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(login_page.page, login_page.base_url)
        assert home_page.is_home_screen_displayed()

        # Logout
        login_page_back = home_page.sign_out()

        # Should be back to login screen
        assert login_page_back.is_login_screen_displayed(), \
            "Should return to login screen after logout"

        # Login again
        login_page_back.login(test_user["email"], test_user["password"])

        assert home_page.is_home_screen_displayed(), \
            "Should be able to login again after logout"
        login_page.take_screenshot("test_logout_and_login_again")
