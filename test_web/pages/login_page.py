"""
Login Page Object for SellScribe Web Application
"""
from playwright.sync_api import Page
from .base_page import BasePage


class LoginPage(BasePage):
    """Page object for Login screen"""

    # Selectors - Flutter web uses ARIA labels after accessibility is enabled
    # Primary selectors use aria-label (Flutter), fallback to standard HTML for non-Flutter
    EMAIL_INPUT = "input[aria-label*='email' i], input[aria-label*='Email' i], [data-testid='email-input'], input[type='email']"
    PASSWORD_INPUT = "input[aria-label*='password' i], input[aria-label*='Password' i], [data-testid='password-input'], input[type='password']"
    LOGIN_BUTTON = "flt-semantics[role='button']:has-text('Sign In'), [data-testid='login-button'], button:has-text('Sign In')"
    REGISTER_LINK = "flt-semantics[role='button']:has-text('Sign up'), [data-testid='register-link'], a:has-text('Sign Up')"
    FORGOT_PASSWORD_LINK = "flt-semantics[role='button']:has-text('Forgot'), [data-testid='forgot-password'], a:has-text('Forgot')"
    ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']"
    REMEMBER_ME = "[data-testid='remember-me'], input[type='checkbox'][name*='remember']"

    def __init__(self, page: Page, base_url: str = ""):
        super().__init__(page)
        self.base_url = base_url
        self.login_url = f"{base_url}/login" if base_url else "/login"

    def navigate_to_login(self) -> "LoginPage":
        """Navigate to login page"""
        self.navigate(self.login_url)
        self.wait_for_load_state()
        self._enable_flutter_accessibility()
        return self

    def _enable_flutter_accessibility(self) -> None:
        """Enable Flutter web accessibility mode if needed"""
        try:
            placeholder = self.page.query_selector("flt-semantics-placeholder")
            if placeholder:
                self.page.evaluate('''() => {
                    const elem = document.querySelector("flt-semantics-placeholder");
                    if (elem) {
                        elem.focus();
                        elem.click();
                    }
                }''')
                self.page.wait_for_timeout(1000)
        except Exception:
            pass  # Accessibility may already be enabled

    def is_login_screen_displayed(self) -> bool:
        """Check if login screen is displayed"""
        return (
            self.is_visible(self.EMAIL_INPUT, timeout=5000) and
            self.is_visible(self.PASSWORD_INPUT, timeout=2000)
        )

    def enter_email(self, email: str) -> "LoginPage":
        """Enter email address"""
        self.clear_and_fill(self.EMAIL_INPUT, email)
        return self

    def enter_password(self, password: str) -> "LoginPage":
        """Enter password"""
        self.clear_and_fill(self.PASSWORD_INPUT, password)
        return self

    def click_login(self) -> None:
        """Click login button"""
        self.click(self.LOGIN_BUTTON)

    def login(self, email: str, password: str) -> None:
        """Perform complete login flow"""
        self.enter_email(email)
        self.enter_password(password)
        self.click_login()
        self.wait_for_load_state()

    def click_register_link(self) -> "RegisterPage":
        """Click register link to navigate to registration"""
        self.click(self.REGISTER_LINK)
        self.wait_for_load_state()
        from .register_page import RegisterPage
        return RegisterPage(self.page, self.base_url)

    def click_forgot_password(self) -> None:
        """Click forgot password link"""
        self.click(self.FORGOT_PASSWORD_LINK)
        self.wait_for_load_state()

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return self.is_visible(self.ERROR_MESSAGE, timeout=3000)

    def get_error_message(self) -> str:
        """Get error message text"""
        if self.is_error_displayed():
            return self.get_text(self.ERROR_MESSAGE)
        return ""

    def check_remember_me(self) -> "LoginPage":
        """Check remember me checkbox"""
        if self.is_visible(self.REMEMBER_ME, timeout=2000):
            self.check(self.REMEMBER_ME)
        return self

    def is_login_button_enabled(self) -> bool:
        """Check if login button is enabled"""
        return self.is_enabled(self.LOGIN_BUTTON)

    def get_email_validation_message(self) -> str:
        """Get email field validation message"""
        return self.get_attribute(self.EMAIL_INPUT, "validationMessage") or ""

    def get_password_validation_message(self) -> str:
        """Get password field validation message"""
        return self.get_attribute(self.PASSWORD_INPUT, "validationMessage") or ""
