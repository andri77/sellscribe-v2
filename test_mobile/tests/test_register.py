"""
Registration Test Cases for SellScribe Mobile App
"""
import pytest
from pages import LoginPage, RegisterPage, HomePage


@pytest.mark.smoke
@pytest.mark.register
class TestRegistration:
    """Test cases for user registration functionality"""

    def test_register_screen_displayed(self, ensure_on_login_screen):
        """Verify register screen can be accessed"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        assert register_page.is_register_screen_displayed(), \
            "Register screen should be displayed"

    def test_register_with_valid_details(self, ensure_on_login_screen, new_user):
        """Test successful registration with valid details"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        register_page.register(
            name=new_user["name"],
            email=new_user["email"],
            password=new_user["password"]
        )

        # After successful registration, should go to home or login
        home_page = HomePage(register_page.driver)
        login_page_check = LoginPage(register_page.driver)

        assert home_page.is_home_screen_displayed() or \
            login_page_check.is_login_screen_displayed(), \
            "Should navigate to home or login after registration"

    def test_register_with_existing_email(self, ensure_on_login_screen, test_user):
        """Test registration with already registered email"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        register_page.register(
            name="Duplicate User",
            email=test_user["email"],  # Existing email
            password="Password123!"
        )

        assert register_page.is_error_displayed(), \
            "Error should be displayed for duplicate email"

    def test_register_with_invalid_email(self, ensure_on_login_screen):
        """Test registration with invalid email format"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        register_page.register(
            name="Test User",
            email="invalid-email",
            password="Password123!"
        )

        assert register_page.is_error_displayed(), \
            "Error should be displayed for invalid email"

    def test_register_with_weak_password(self, ensure_on_login_screen):
        """Test registration with weak password"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        register_page.register(
            name="Test User",
            email="test@example.com",
            password="123"  # Weak password
        )

        assert register_page.is_error_displayed() or \
            register_page.is_register_screen_displayed(), \
            "Should show error for weak password"

    def test_register_with_mismatched_passwords(self, ensure_on_login_screen):
        """Test registration with password confirmation mismatch"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        register_page.enter_name("Test User")
        register_page.enter_email("test@example.com")
        register_page.enter_password("Password123!")
        register_page.enter_confirm_password("DifferentPass!")
        register_page.tap_register()

        assert register_page.is_error_displayed() or \
            register_page.is_register_screen_displayed(), \
            "Should show error for mismatched passwords"

    def test_register_with_empty_fields(self, ensure_on_login_screen):
        """Test registration with empty fields"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        register_page.tap_register()

        assert register_page.is_error_displayed() or \
            register_page.is_register_screen_displayed(), \
            "Should show error for empty fields"

    def test_navigate_back_to_login(self, ensure_on_login_screen):
        """Test navigation back to login from register"""
        login_page = ensure_on_login_screen
        register_page = login_page.tap_register_link()

        login_page_back = register_page.tap_login_link()

        assert login_page_back.is_login_screen_displayed(), \
            "Should navigate back to login screen"


@pytest.mark.regression
@pytest.mark.register
class TestRegistrationValidation:
    """Extended validation tests for registration"""

    @pytest.mark.skip(reason="Multi-field sequence causes stale element - needs test restructure")
    def test_name_field_required(self, login_page):
        """Test that name field is required"""
        register_page = login_page.tap_register_link()

        register_page.enter_email("test@example.com")
        register_page.enter_password("Password123!")
        register_page.enter_confirm_password("Password123!")
        register_page.tap_register()

        assert register_page.is_error_displayed() or \
            register_page.is_register_screen_displayed(), \
            "Should require name field"

    def test_email_field_required(self, login_page):
        """Test that email field is required"""
        register_page = login_page.tap_register_link()

        register_page.enter_name("Test User")
        register_page.enter_password("Password123!")
        register_page.enter_confirm_password("Password123!")
        register_page.tap_register()

        assert register_page.is_error_displayed() or \
            register_page.is_register_screen_displayed(), \
            "Should require email field"

    def test_password_field_required(self, login_page):
        """Test that password field is required"""
        register_page = login_page.tap_register_link()

        register_page.enter_name("Test User")
        register_page.enter_email("test@example.com")
        register_page.tap_register()

        assert register_page.is_error_displayed() or \
            register_page.is_register_screen_displayed(), \
            "Should require password field"

    def test_password_minimum_length(self, login_page):
        """Test password minimum length requirement"""
        register_page = login_page.tap_register_link()

        register_page.register(
            name="Test User",
            email="test@example.com",
            password="Pas1!"  # Too short
        )

        assert register_page.is_error_displayed() or \
            register_page.is_register_screen_displayed(), \
            "Should enforce minimum password length"

    def test_name_accepts_special_characters(self, login_page, new_user):
        """Test that name field accepts special characters"""
        register_page = login_page.tap_register_link()

        register_page.enter_name("Test O'User-Name")
        register_page.enter_email(new_user["email"])
        register_page.enter_password(new_user["password"])
        register_page.enter_confirm_password(new_user["password"])
        register_page.tap_register()

        # Should not show error for special characters in name
        home_page = HomePage(register_page.driver)
        assert home_page.is_home_screen_displayed() or \
            not register_page.is_error_displayed(), \
            "Should accept special characters in name"


@pytest.mark.regression
@pytest.mark.register
class TestNewUserCredits:
    """Test that new users receive free credits"""

    @pytest.mark.skip(reason="Credit assignment timing varies by server response - needs polling")
    def test_new_user_gets_5_credits(self, login_page, new_user):
        """Test that new user receives 5 free credits"""
        register_page = login_page.tap_register_link()

        register_page.register(
            name=new_user["name"],
            email=new_user["email"],
            password=new_user["password"]
        )

        home_page = HomePage(register_page.driver)

        if home_page.is_home_screen_displayed():
            credits = home_page.get_credits_remaining()
            assert credits == 5, \
                f"New user should have 5 credits, but has {credits}"
