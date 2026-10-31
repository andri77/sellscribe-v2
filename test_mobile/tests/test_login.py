"""
Login Test Cases for SellScribe Mobile App
"""
import pytest
from pages import HomePage


def assert_stays_on_login(login_page):
    """A rejected sign-in keeps the login screen and never reaches home"""
    assert not HomePage(login_page.driver).is_home_screen_displayed(timeout=5), \
        "Should not reach the home screen"
    assert login_page.is_login_screen_displayed(), "Should remain on the login screen"


@pytest.mark.smoke
@pytest.mark.login
class TestLogin:
    """Test cases for login functionality"""

    def test_login_screen_displayed(self, ensure_on_login_screen):
        """Verify login screen is displayed on app launch"""
        login_page = ensure_on_login_screen
        assert login_page.is_login_screen_displayed(), \
            "Login screen should be displayed"

    def test_login_with_valid_credentials(self, ensure_on_login_screen, test_user):
        """Test successful login with valid credentials"""
        login_page = ensure_on_login_screen
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(login_page.driver)
        assert home_page.is_home_screen_displayed(), \
            "Home screen should be displayed after successful login"

    def test_login_with_invalid_email(self, ensure_on_login_screen):
        """Test login with invalid email format"""
        login_page = ensure_on_login_screen
        login_page.login("invalid-email", "Password123!")
        assert_stays_on_login(login_page)

    def test_login_with_wrong_password(self, ensure_on_login_screen, test_user):
        """Test login with incorrect password"""
        login_page = ensure_on_login_screen
        login_page.login(test_user["email"], "WrongPassword123!")
        assert_stays_on_login(login_page)

    def test_login_with_empty_email(self, ensure_on_login_screen):
        """Test login with empty email field"""
        login_page = ensure_on_login_screen
        login_page.enter_password("Password123!")
        login_page.tap_login()
        assert_stays_on_login(login_page)

    def test_login_with_empty_password(self, ensure_on_login_screen, test_user):
        """Test login with empty password field"""
        login_page = ensure_on_login_screen
        login_page.enter_email(test_user["email"])
        login_page.tap_login()
        assert_stays_on_login(login_page)

    def test_login_with_empty_fields(self, ensure_on_login_screen):
        """Test login with all fields empty"""
        login_page = ensure_on_login_screen
        login_page.tap_login()
        assert_stays_on_login(login_page)

    def test_navigate_to_register(self, ensure_on_login_screen):
        """Test navigation from login to register screen"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        assert register_page.is_register_screen_displayed(), \
            "Register screen should be displayed"

    def test_forgot_password_link(self, login_page):
        """Forgot password is not implemented yet (TODO in login_screen.dart): tapping
        it must leave the user on the login screen"""
        login_page.tap_forgot_password()
        assert login_page.is_login_screen_displayed(), \
            "App should stay on the login screen after tapping forgot password"


@pytest.mark.regression
@pytest.mark.login
class TestLoginValidation:
    """Extended validation tests for login"""

    def test_email_field_accepts_valid_formats(self, login_page):
        """Test that the email field accepts various valid formats"""
        valid_emails = [
            "user@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "user@subdomain.example.com"
        ]

        for email in valid_emails:
            login_page.enter_email(email)  # clears the previous value first

        assert login_page.is_login_screen_displayed(), \
            "Login screen should stay usable after editing the email"

    def test_password_field_masks_input(self, login_page):
        """Test that password field masks characters"""
        login_page.enter_password("TestPassword123!")

        assert login_page.is_password_masked(), \
            "Password field should hide its input"

    @pytest.mark.skip(reason="Sign In is never disabled; submitting empty fields is "
                             "covered by test_login_with_empty_fields")
    def test_login_button_disabled_initially(self, login_page):
        """Test that login button state before input"""

    @pytest.mark.skip(reason="The test emulator uses a hardware keyboard, so there is no soft "
                             "keyboard to dismiss; Appium's hide (a Back press) can leave the app")
    def test_keyboard_dismissal(self, login_page, test_user):
        """Test that keyboard can be dismissed"""
        login_page.enter_email(test_user["email"])
        login_page.hide_keyboard()

        assert not login_page.driver.is_keyboard_shown(), \
            "Keyboard should be hidden"


@pytest.mark.regression
@pytest.mark.login
class TestLoginPersistence:
    """Test login session persistence"""

    def test_stay_logged_in_after_app_restart(self, driver, login_page, test_user):
        """Test that user stays logged in after the app is backgrounded"""
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(driver)
        assert home_page.is_home_screen_displayed()

        driver.background_app(2)

        assert home_page.is_home_screen_displayed(), \
            "User should remain logged in after app restart"

    def test_logout_and_login_again(self, driver, login_page, test_user):
        """Test logout and login again flow"""
        login_page.login(test_user["email"], test_user["password"])

        home_page = HomePage(driver)
        assert home_page.is_home_screen_displayed()

        login_page = home_page.tap_sign_out()

        assert login_page.is_login_screen_displayed(), \
            "Should return to login screen after logout"

        login_page.login(test_user["email"], test_user["password"])

        assert home_page.is_home_screen_displayed(), \
            "Should be able to login again after logout"
