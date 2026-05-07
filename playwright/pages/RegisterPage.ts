import { Page } from '@playwright/test';
import { BasePage } from './BasePage';

export class RegisterPage extends BasePage {
  private readonly baseUrl: string;

  readonly NAME_INPUT = "input[aria-label*='name' i], [data-testid='name-input'], input[name='name']";
  readonly FIRST_NAME_INPUT = "input[aria-label*='first name' i], [data-testid='first-name'], input[name='firstName']";
  readonly LAST_NAME_INPUT = "input[aria-label*='last name' i], [data-testid='last-name'], input[name='lastName']";
  readonly EMAIL_INPUT = "input[aria-label*='email' i], [data-testid='email-input'], input[type='email']";
  readonly PASSWORD_INPUT = "input[aria-label='Create a password'], input[aria-label*='password' i]:not([aria-label*='confirm' i]), [data-testid='password-input']";
  readonly CONFIRM_PASSWORD_INPUT = "input[aria-label*='Confirm' i], [data-testid='confirm-password'], input[name='confirmPassword']";
  readonly REGISTER_BUTTON = "flt-semantics[role='button']:has-text('Create Account'), flt-semantics[role='button']:has-text('Sign Up'), [data-testid='register-button'], button:has-text('Create Account')";
  readonly LOGIN_LINK = "flt-semantics[role='button']:has-text('Sign in'), [data-testid='login-link'], a:has-text('Sign In')";
  readonly ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']";
  readonly TERMS_CHECKBOX = "[data-testid='terms-checkbox'], input[name='terms'], input[name='acceptTerms']";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/register`);
  }

  async isRegisterScreenDisplayed(): Promise<boolean> {
    return (
      (await this.isVisible(this.EMAIL_INPUT, 5000)) &&
      ((await this.isVisible(this.NAME_INPUT, 2000)) ||
        (await this.isVisible(this.FIRST_NAME_INPUT, 2000)))
    );
  }

  async register(opts: {
    name?: string;
    firstName?: string;
    lastName?: string;
    email: string;
    password: string;
    confirmPassword?: string;
  }): Promise<void> {
    if (opts.name && (await this.isVisible(this.NAME_INPUT, 2000))) {
      await this.fill(this.NAME_INPUT, opts.name);
    }
    if (opts.firstName && (await this.isVisible(this.FIRST_NAME_INPUT, 2000))) {
      await this.fill(this.FIRST_NAME_INPUT, opts.firstName);
    }
    if (opts.lastName && (await this.isVisible(this.LAST_NAME_INPUT, 2000))) {
      await this.fill(this.LAST_NAME_INPUT, opts.lastName);
    }
    await this.fill(this.EMAIL_INPUT, opts.email);
    await this.fill(this.PASSWORD_INPUT, opts.password);
    const confirmPw = opts.confirmPassword ?? opts.password;
    if (await this.isVisible(this.CONFIRM_PASSWORD_INPUT, 2000)) {
      await this.fill(this.CONFIRM_PASSWORD_INPUT, confirmPw);
    }
    if (await this.isVisible(this.TERMS_CHECKBOX, 2000)) {
      await this.page.check(this.TERMS_CHECKBOX);
    }
    await this.click(this.REGISTER_BUTTON);
    await this.waitForLoadState();
  }

  async isErrorDisplayed(): Promise<boolean> {
    return this.isVisible(this.ERROR_MESSAGE, 3000);
  }

  async getErrorMessage(): Promise<string> {
    if (await this.isErrorDisplayed()) return this.getText(this.ERROR_MESSAGE);
    return '';
  }

  async clickLoginLink(): Promise<void> {
    await this.click(this.LOGIN_LINK);
    await this.waitForLoadState();
  }
}
