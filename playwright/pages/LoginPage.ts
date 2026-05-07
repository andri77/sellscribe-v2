import { Page } from '@playwright/test';
import { BasePage } from './BasePage';

export class LoginPage extends BasePage {
  private readonly baseUrl: string;

  readonly EMAIL_INPUT = "input[aria-label*='email' i], input[aria-label*='Email' i], [data-testid='email-input'], input[type='email']";
  readonly PASSWORD_INPUT = "input[aria-label*='password' i], input[aria-label*='Password' i], [data-testid='password-input'], input[type='password']";
  readonly LOGIN_BUTTON = "flt-semantics[role='button']:has-text('Sign In'), [data-testid='login-button'], button:has-text('Sign In')";
  readonly REGISTER_LINK = "flt-semantics[role='button']:has-text('Sign up'), [data-testid='register-link'], a:has-text('Sign Up')";
  readonly ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/login`);
  }

  async isLoginScreenDisplayed(): Promise<boolean> {
    return (
      (await this.isVisible(this.EMAIL_INPUT, 5000)) &&
      (await this.isVisible(this.PASSWORD_INPUT, 2000))
    );
  }

  async enterEmail(email: string): Promise<void> {
    await this.fill(this.EMAIL_INPUT, email);
  }

  async enterPassword(password: string): Promise<void> {
    await this.fill(this.PASSWORD_INPUT, password);
  }

  async clickLogin(): Promise<void> {
    await this.click(this.LOGIN_BUTTON);
    await this.waitForLoadState();
  }

  async login(email: string, password: string): Promise<void> {
    await this.enterEmail(email);
    await this.enterPassword(password);
    await this.clickLogin();
  }

  async isErrorDisplayed(): Promise<boolean> {
    return this.isVisible(this.ERROR_MESSAGE, 3000);
  }

  async getErrorMessage(): Promise<string> {
    if (await this.isErrorDisplayed()) return this.getText(this.ERROR_MESSAGE);
    return '';
  }

  async clickRegisterLink(): Promise<void> {
    await this.click(this.REGISTER_LINK);
    await this.waitForLoadState();
  }
}
