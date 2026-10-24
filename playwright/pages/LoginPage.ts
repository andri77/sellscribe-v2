import { Page } from '@playwright/test';
import { BasePage, semanticButton, semanticInput } from './BasePage';

export class LoginPage extends BasePage {
  private readonly baseUrl: string;

  readonly EMAIL_INPUT = semanticInput('email-input');
  readonly PASSWORD_INPUT = semanticInput('password-input');
  readonly LOGIN_BUTTON = semanticButton('sign-in-button');
  readonly REGISTER_LINK = semanticButton('sign-up-link');
  readonly ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    // The app uses hash routing — a plain /login path is ignored and the splash decides.
    await super.navigate(`${this.baseUrl}/#/login`);
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
    await this.waitForFlutter();
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
