"""
Registration Test Cases for SellScribe Mobile App
"""
import pytest
from pages import LoginPage, HomePage


def assert_stays_on_register(register_page):
    """A rejected registration keeps the register screen and never reaches home"""
    assert not HomePage(register_page.driver).is_home_screen_displayed(timeout=5), \
        "Should not reach the home screen"
    assert register_page.is_register_screen_displayed(), \
        "Should remain on the register screen"


def assert_registered(driver):
    """After sign-up the app shows home, or login when email confirmation is required"""
    assert HomePage(driver).is_home_screen_displayed() or \
        LoginPage(driver).is_login_screen_displayed(), \
        "Should navigate to home or login after registration"


@pytest.mark.smoke
@pytest.mark.register
class TestRegistration:
    """Test cases for user registration functionality"""

    def test_register_screen_displayed(self, ensure_on_login_screen):
        """Verify register screen can be accessed"""
        register_page = ensure_on_login_screen.tap_register_link()

        assert register_page.is_register_screen_displayed(), \
            "Register screen should be displayed"

    def test_register_with_valid_details(self, ensure_on_login_screen, new_user):
        """Test successful registration with valid details"""
        register_page = ensure_on_login_screen.tap_register_link()

        register_page.register(
            name=new_user["name"],
            email=new_user["email"],
            password=new_user["password"]
        )

        assert_registered(register_page.driver)

    @pytest.mark.skip(reason="Supabase's answer to a duplicate sign-up depends on project settings "
                             "(with email confirmation on it returns no error), so there is no "
                             "stable outcome to assert")
    def test_register_with_existing_email(self, ensure_on_login_screen, test_user):
        """Test registration with already registered email"""

    def test_register_with_invalid_email(self, ensure_on_login_screen):
        """Test registration with invalid email format"""
        register_page = ensure_on_login_screen.tap_register_link()

        register_page.register(
            name="Test User",
            email="invalid-email",
            password="Password123!"
        )

        assert_stays_on_register(register_page)

    def test_register_with_weak_password(self, ensure_on_login_screen):
        """Test registration with weak password"""
        register_page = ensure_on_login_screen.tap_register_link()

        register_page.register(
            name="Test User",
            email="test@example.com",
            password="123"  # Weak password
        )

        assert_stays_on_register(register_page)

    def test_register_with_mismatched_passwords(self, ensure_on_login_screen):
        """Test registration with password confirmation mismatch"""
        register_page = ensure_on_login_screen.tap_register_link()

        register_page.enter_name("Test User")
        register_page.enter_email("test@example.com")
        register_page.enter_password("Password123!")
        register_page.enter_confirm_password("DifferentPass!")
        register_page.tap_register()

        assert_stays_on_register(register_page)

    def test_register_with_empty_fields(self, ensure_on_login_screen):
        """Test registration with empty fields"""
        register_page = ensure_on_login_screen.tap_register_link()

        register_page.tap_register()

        assert_stays_on_register(register_page)

    def test_navigate_back_to_login(self, ensure_on_login_screen):
        """Test navigation back to login from register"""
        register_page = ensure_on_login_screen.tap_register_link()

        login_page = register_page.tap_login_link()

        assert login_page.is_login_screen_displayed(), \
            "Should navigate back to login screen"


@pytest.mark.regression
@pytest.mark.register
class TestRegistrationValidation:
    """Extended validation tests for registration"""

    def test_name_field_required(self, login_page):
        """Test that name field is required"""
        register_page = login_page.tap_register_link()

        register_page.enter_email("test@example.com")
        register_page.enter_password("Password123!")
        register_page.enter_confirm_password("Password123!")
        register_page.tap_register()

        assert_stays_on_register(register_page)

    def test_email_field_required(self, login_page):
        """Test that email field is required"""
        register_page = login_page.tap_register_link()

        register_page.enter_name("Test User")
        register_page.enter_password("Password123!")
        register_page.enter_confirm_password("Password123!")
        register_page.tap_register()

        assert_stays_on_register(register_page)

    def test_password_field_required(self, login_page):
        """Test that password field is required"""
        register_page = login_page.tap_register_link()

        register_page.enter_name("Test User")
        register_page.enter_email("test@example.com")
        register_page.tap_register()

        assert_stays_on_register(register_page)

    def test_password_minimum_length(self, login_page):
        """Test password minimum length requirement"""
        register_page = login_page.tap_register_link()

        register_page.register(
            name="Test User",
            email="test@example.com",
            password="Pas1!"  # Too short
        )

        assert_stays_on_register(register_page)

    def test_name_accepts_special_characters(self, login_page, new_user):
        """Test that name field accepts special characters"""
        register_page = login_page.tap_register_link()

        register_page.enter_name("Test O'User-Name")
        register_page.enter_email(new_user["email"].replace("newuser_", "special_"))
        register_page.enter_password(new_user["password"])
        register_page.enter_confirm_password(new_user["password"])
        register_page.tap_register()

        assert_registered(register_page.driver)


@pytest.mark.regression
@pytest.mark.register
class TestNewUserCredits:
    """Test that new users receive free credits"""

    def test_new_user_gets_5_credits(self, login_page, new_user):
        """Test that new user receives 5 free credits"""
        register_page = login_page.tap_register_link()

        register_page.register(
            name=new_user["name"],
            email=new_user["email"].replace("newuser_", "credits_"),
            password=new_user["password"]
        )

        home_page = HomePage(register_page.driver)
        if not home_page.is_home_screen_displayed():
            pytest.skip("Sign-up needs email confirmation, so the new user can't reach home")

        credits = home_page.get_credits_remaining()
        assert credits == 5, f"New user should have 5 credits, but has {credits}"
