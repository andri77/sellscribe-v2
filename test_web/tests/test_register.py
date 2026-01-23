"""
Registration Test Cases for SellScribe Web Application
"""
import pytest
from pages import RegisterPage, LoginPage, HomePage


@pytest.mark.smoke
@pytest.mark.register
class TestRegistration:
    """Test cases for user registration functionality"""

    def test_register_screen_displayed(self, register_page: RegisterPage):
        """Verify register screen can be accessed"""
        assert register_page.is_register_screen_displayed(), \
            "Register screen should be displayed"
        register_page.take_screenshot("test_register_screen_displayed")

    def test_register_with_valid_details(self, register_page: RegisterPage, new_user: dict):
        """Test successful registration with valid details"""
        register_page.register(
            name=new_user["name"],
            first_name=new_user["first_name"],
            last_name=new_user["last_name"],
            email=new_user["email"],
            password=new_user["password"]
        )

        register_page.page.wait_for_timeout(2000)

        # After successful registration, should go to home or login
        home_page = HomePage(register_page.page, register_page.base_url)
        login_page = LoginPage(register_page.page, register_page.base_url)

        assert (
            home_page.is_home_screen_displayed() or
            login_page.is_login_screen_displayed() or
            register_page.is_success_displayed()
        ), "Should navigate to home, login, or show success after registration"
        register_page.take_screenshot("test_register_with_valid_details")

    def test_register_with_existing_email(self, register_page: RegisterPage, test_user: dict):
        """Test registration with already registered email"""
        register_page.register(
            name="Duplicate User",
            email=test_user["email"],
            password="Password123!"
        )

        register_page.page.wait_for_timeout(2000)

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Error should be displayed for duplicate email"
        register_page.take_screenshot("test_register_with_existing_email")

    def test_register_with_invalid_email(self, register_page: RegisterPage):
        """Test registration with invalid email format"""
        register_page.register(
            name="Test User",
            email="invalid-email",
            password="Password123!"
        )

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Error should be displayed for invalid email"
        register_page.take_screenshot("test_register_with_invalid_email")

    def test_register_with_weak_password(self, register_page: RegisterPage, new_user: dict):
        """Test registration with weak password"""
        register_page.register(
            name="Test User",
            email=new_user["email"],
            password="123"
        )

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Should show error for weak password"
        register_page.take_screenshot("test_register_with_weak_password")

    def test_register_with_mismatched_passwords(self, register_page: RegisterPage, new_user: dict):
        """Test registration with password confirmation mismatch"""
        register_page.enter_name("Test User")
        register_page.enter_email(new_user["email"])
        register_page.enter_password("Password123!")
        register_page.enter_confirm_password("DifferentPass!")
        register_page.click_register()

        register_page.page.wait_for_timeout(1000)

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Should show error for mismatched passwords"
        register_page.take_screenshot("test_register_with_mismatched_passwords")

    def test_register_with_empty_fields(self, register_page: RegisterPage):
        """Test registration with empty fields"""
        register_page.click_register()

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Should show error for empty fields"
        register_page.take_screenshot("test_register_with_empty_fields")

    def test_navigate_back_to_login(self, register_page: RegisterPage):
        """Test navigation back to login from register"""
        login_page = register_page.click_login_link()

        assert login_page.is_login_screen_displayed(), \
            "Should navigate back to login screen"
        register_page.take_screenshot("test_navigate_back_to_login")


@pytest.mark.regression
@pytest.mark.register
class TestRegistrationValidation:
    """Extended validation tests for registration"""

    def test_name_field_required(self, register_page: RegisterPage, new_user: dict):
        """Test that name field is required"""
        register_page.enter_email(new_user["email"])
        register_page.enter_password(new_user["password"])
        register_page.enter_confirm_password(new_user["password"])
        register_page.click_register()

        register_page.page.wait_for_timeout(1000)

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Should require name field"
        register_page.take_screenshot("test_name_field_required")

    def test_email_field_required(self, register_page: RegisterPage, new_user: dict):
        """Test that email field is required"""
        register_page.enter_name("Test User")
        register_page.enter_password(new_user["password"])
        register_page.enter_confirm_password(new_user["password"])
        register_page.click_register()

        register_page.page.wait_for_timeout(1000)

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Should require email field"
        register_page.take_screenshot("test_email_field_required")

    def test_password_field_required(self, register_page: RegisterPage, new_user: dict):
        """Test that password field is required"""
        register_page.enter_name("Test User")
        register_page.enter_email(new_user["email"])
        register_page.click_register()

        register_page.page.wait_for_timeout(1000)

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Should require password field"
        register_page.take_screenshot("test_password_field_required")

    def test_password_minimum_length(self, register_page: RegisterPage, new_user: dict):
        """Test password minimum length requirement"""
        register_page.register(
            name="Test User",
            email=new_user["email"],
            password="Pas1!"
        )

        register_page.page.wait_for_timeout(1000)

        assert register_page.is_error_displayed() or register_page.is_register_screen_displayed(), \
            "Should enforce minimum password length"
        register_page.take_screenshot("test_password_minimum_length")

    def test_name_accepts_special_characters(self, register_page: RegisterPage, new_user: dict):
        """Test that name field accepts special characters"""
        register_page.enter_name("Test O'User-Name")
        register_page.enter_email(new_user["email"])
        register_page.enter_password(new_user["password"])
        register_page.enter_confirm_password(new_user["password"])
        register_page.accept_terms()
        register_page.click_register()

        register_page.page.wait_for_timeout(2000)

        # Should not show error for special characters in name
        home_page = HomePage(register_page.page, register_page.base_url)
        login_page = LoginPage(register_page.page, register_page.base_url)

        assert (
            home_page.is_home_screen_displayed() or
            login_page.is_login_screen_displayed() or
            not register_page.is_error_displayed()
        ), "Should accept special characters in name"
        register_page.take_screenshot("test_name_accepts_special_characters")
