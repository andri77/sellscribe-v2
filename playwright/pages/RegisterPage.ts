import { Page } from '@playwright/test';
import { BasePage, semanticButton, semanticInput } from './BasePage';

export class RegisterPage extends BasePage {
  private readonly baseUrl: string;

  // The register screen has a single Name field; first/last name are aliases for older callers.
  readonly NAME_INPUT = semanticInput('name-input');
  readonly FIRST_NAME_INPUT = this.NAME_INPUT;
  readonly LAST_NAME_INPUT = this.NAME_INPUT;
  readonly EMAIL_INPUT = semanticInput('email-input');
  readonly PASSWORD_INPUT = semanticInput('password-create-input');
  readonly CONFIRM_PASSWORD_INPUT = semanticInput('password-confirm-input');
  readonly REGISTER_BUTTON = semanticButton('create-account-button');
  readonly LOGIN_LINK = semanticButton('sign-in-link');
  readonly ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']";
  readonly TERMS_CHECKBOX = "[data-testid='terms-checkbox'], input[name='terms'], input[name='acceptTerms']";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    // The app uses hash routing — /#/register deep-links straight to the screen.
    await super.navigate(`${this.baseUrl}/#/register`);
  }

  async isRegisterScreenDisplayed(): Promise<boolean> {
    return (
      (await this.isVisible(this.EMAIL_INPUT, 5000)) &&
      (await this.isVisible(this.NAME_INPUT, 2000))
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
