import { Page } from '@playwright/test';
import { BasePage } from './BasePage';

export class SettingsPage extends BasePage {
  private readonly baseUrl: string;

  readonly PROFILE_SECTION = "[data-testid='profile-section'], .profile-section, section:has-text('Profile')";
  readonly EDIT_PROFILE_BUTTON = "[data-testid='edit-profile'], button:has-text('Edit Profile'), a:has-text('Edit Profile')";
  readonly THEME_LIGHT = "[data-testid='theme-light'], input[value='light'], button:has-text('Light')";
  readonly THEME_DARK = "[data-testid='theme-dark'], input[value='dark'], button:has-text('Dark')";
  readonly SIGN_OUT_BUTTON = "[data-testid='sign-out'], button:has-text('Sign Out'), button:has-text('Logout')";
  readonly FIRST_NAME_INPUT = "[data-testid='first-name'], input[name='firstName'], input[placeholder*='first name' i]";
  readonly LAST_NAME_INPUT = "[data-testid='last-name'], input[name='lastName'], input[placeholder*='last name' i]";
  readonly SAVE_BUTTON = "[data-testid='save-button'], button:has-text('Save'), button[type='submit']";
  readonly CONFIRM_SIGN_OUT = "[data-testid='confirm-signout'], button:has-text('Confirm'), button:has-text('Yes')";
  readonly SUCCESS_MESSAGE = "[data-testid='success-message'], .success, .alert-success, [role='alert']:has-text('success')";
  readonly ERROR_MESSAGE = "[data-testid='error-message'], .error, .alert-error, [role='alert']:has-text('error')";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/settings`);
  }

  async isSettingsScreenDisplayed(): Promise<boolean> {
    return (
      (await this.isTextPresent('Settings', 5000)) ||
      (await this.isVisible(this.PROFILE_SECTION, 3000))
    );
  }

  async clickEditProfile(): Promise<void> {
    await this.click(this.EDIT_PROFILE_BUTTON);
    await this.waitForLoadState();
  }

  async updateName(firstName: string, lastName: string): Promise<void> {
    await this.fill(this.FIRST_NAME_INPUT, firstName);
    await this.fill(this.LAST_NAME_INPUT, lastName);
    await this.click(this.SAVE_BUTTON);
    await this.waitForLoadState();
  }

  async setLightTheme(): Promise<void> {
    if (await this.isVisible(this.THEME_LIGHT, 3000)) {
      await this.click(this.THEME_LIGHT);
    }
  }

  async setDarkTheme(): Promise<void> {
    if (await this.isVisible(this.THEME_DARK, 3000)) {
      await this.click(this.THEME_DARK);
    }
  }

  async signOut(): Promise<void> {
    await this.scrollToElement(this.SIGN_OUT_BUTTON);
    await this.click(this.SIGN_OUT_BUTTON);
    if (await this.isVisible(this.CONFIRM_SIGN_OUT, 3000)) {
      await this.click(this.CONFIRM_SIGN_OUT);
    }
    await this.waitForLoadState();
  }

  async isSuccessDisplayed(): Promise<boolean> {
    return this.isVisible(this.SUCCESS_MESSAGE, 3000);
  }

  async isErrorDisplayed(): Promise<boolean> {
    return this.isVisible(this.ERROR_MESSAGE, 3000);
  }
}
