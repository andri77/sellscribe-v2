"""
Register Page Object for SellScribe Web Application
"""
from playwright.sync_api import Page
from .base_page import BasePage


class RegisterPage(BasePage):
    """Page object for Registration screen"""

    # Selectors - Flutter web uses ARIA labels after accessibility is enabled
    NAME_INPUT = "input[aria-label*='name' i], [data-testid='name-input'], input[name='name']"
    FIRST_NAME_INPUT = "input[aria-label*='first name' i], [data-testid='first-name'], input[name='firstName']"
    LAST_NAME_INPUT = "input[aria-label*='last name' i], [data-testid='last-name'], input[name='lastName']"
    EMAIL_INPUT = "input[aria-label*='email' i], [data-testid='email-input'], input[type='email']"
    PASSWORD_INPUT = "input[aria-label='Create a password'], input[aria-label*='password' i]:not([aria-label*='confirm' i]), [data-testid='password-input']"
    CONFIRM_PASSWORD_INPUT = "input[aria-label*='Confirm' i], [data-testid='confirm-password'], input[name='confirmPassword']"
    REGISTER_BUTTON = "flt-semantics[role='button']:has-text('Create Account'), flt-semantics[role='button']:has-text('Sign Up'), [data-testid='register-button'], button:has-text('Create Account')"
    LOGIN_LINK = "flt-semantics[role='button']:has-text('Sign in'), [data-testid='login-link'], a:has-text('Sign In')"
    ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']"
    SUCCESS_MESSAGE = "[data-testid='success-message'], .success, .alert-success"
    TERMS_CHECKBOX = "[data-testid='terms-checkbox'], input[name='terms'], input[name='acceptTerms']"

    def __init__(self, page: Page, base_url: str = ""):
        super().__init__(page)
        self.base_url = base_url
        self.register_url = f"{base_url}/register" if base_url else "/register"

    def navigate_to_register(self) -> "RegisterPage":
        """Navigate to register page"""
        self.navigate(self.register_url)
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

    def is_register_screen_displayed(self) -> bool:
        """Check if register screen is displayed"""
        return (
            self.is_visible(self.EMAIL_INPUT, timeout=5000) and
            (self.is_visible(self.NAME_INPUT, timeout=2000) or
             self.is_visible(self.FIRST_NAME_INPUT, timeout=2000))
        )

    def enter_name(self, name: str) -> "RegisterPage":
        """Enter full name"""
        if self.is_visible(self.NAME_INPUT, timeout=2000):
            self.clear_and_fill(self.NAME_INPUT, name)
        return self

    def enter_first_name(self, first_name: str) -> "RegisterPage":
        """Enter first name"""
        if self.is_visible(self.FIRST_NAME_INPUT, timeout=2000):
            self.clear_and_fill(self.FIRST_NAME_INPUT, first_name)
        return self

    def enter_last_name(self, last_name: str) -> "RegisterPage":
        """Enter last name"""
        if self.is_visible(self.LAST_NAME_INPUT, timeout=2000):
            self.clear_and_fill(self.LAST_NAME_INPUT, last_name)
        return self

    def enter_email(self, email: str) -> "RegisterPage":
        """Enter email address"""
        self.clear_and_fill(self.EMAIL_INPUT, email)
        return self

    def enter_password(self, password: str) -> "RegisterPage":
        """Enter password"""
        self.clear_and_fill(self.PASSWORD_INPUT, password)
        return self

    def enter_confirm_password(self, password: str) -> "RegisterPage":
        """Enter confirm password"""
        if self.is_visible(self.CONFIRM_PASSWORD_INPUT, timeout=2000):
            self.clear_and_fill(self.CONFIRM_PASSWORD_INPUT, password)
        return self

    def accept_terms(self) -> "RegisterPage":
        """Accept terms and conditions"""
        if self.is_visible(self.TERMS_CHECKBOX, timeout=2000):
            self.check(self.TERMS_CHECKBOX)
        return self

    def click_register(self) -> None:
        """Click register button"""
        self.click(self.REGISTER_BUTTON)

    def register(
        self,
        name: str = "",
        first_name: str = "",
        last_name: str = "",
        email: str = "",
        password: str = "",
        confirm_password: str = ""
    ) -> None:
        """Perform complete registration flow"""
        if name:
            self.enter_name(name)
        if first_name:
            self.enter_first_name(first_name)
        if last_name:
            self.enter_last_name(last_name)
        self.enter_email(email)
        self.enter_password(password)
        if confirm_password:
            self.enter_confirm_password(confirm_password)
        else:
            self.enter_confirm_password(password)
        self.accept_terms()
        self.click_register()
        self.wait_for_load_state()

    def click_login_link(self) -> "LoginPage":
        """Click login link to navigate to login"""
        self.click(self.LOGIN_LINK)
        self.wait_for_load_state()
        from .login_page import LoginPage
        return LoginPage(self.page, self.base_url)

    def is_error_displayed(self) -> bool:
        """Check if error message is displayed"""
        return self.is_visible(self.ERROR_MESSAGE, timeout=3000)

    def get_error_message(self) -> str:
        """Get error message text"""
        if self.is_error_displayed():
            return self.get_text(self.ERROR_MESSAGE)
        return ""

    def is_success_displayed(self) -> bool:
        """Check if success message is displayed"""
        return self.is_visible(self.SUCCESS_MESSAGE, timeout=3000)

    def is_register_button_enabled(self) -> bool:
        """Check if register button is enabled"""
        return self.is_enabled(self.REGISTER_BUTTON)
