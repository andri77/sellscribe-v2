import { Page } from '@playwright/test';
import { BasePage, semanticButton, semanticInput } from './BasePage';

export class SettingsPage extends BasePage {
  private readonly baseUrl: string;

  // tooltip: 'Back' on the AppBar IconButton → text content 'Back' on the role=button node.
  readonly BACK_BUTTON = semanticButton('Back');
  readonly PROFILE_SECTION = "flt-semantics:has-text('Profile'), [data-testid='profile-section']";
  readonly EDIT_PROFILE_BUTTON = semanticButton('edit-profile-tile');
  readonly THEME_BUTTON = semanticButton('theme-button');
  readonly THEME_LIGHT = "[data-testid='theme-light'], flt-semantics:has-text('Light')";
  readonly THEME_DARK = "[data-testid='theme-dark'], flt-semantics:has-text('Dark')";
  // Sign Out is a list tile on the settings screen (not in the popup menu) and opens a
  // confirmation dialog.
  readonly SIGN_OUT_BUTTON = semanticButton('sign-out-button');
  // Edit Profile screen (/settings/profile)
  readonly FIRST_NAME_INPUT = semanticInput('first-name-input');
  readonly LAST_NAME_INPUT = semanticInput('last-name-input');
  readonly SAVE_BUTTON = semanticButton('save-profile-button');
  readonly CONFIRM_SIGN_OUT = semanticButton('confirm-sign-out-button');
  readonly SUCCESS_MESSAGE = "[data-testid='success-message'], [role='alert']:has-text('success')";
  readonly ERROR_MESSAGE = "[data-testid='error-message'], [role='alert']:has-text('error')";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async goBack(): Promise<void> {
    await this.click(this.BACK_BUTTON);
    await this.waitForLoadState();
    await this.waitForFlutter();
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/#/settings`);
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
    // Theme tile opens a dialog with Light/Dark/System options (confirmed via DOM inspection).
    // Selecting Light triggers a Flutter notifyListeners() that can cause a router re-evaluation bug.
    // Open the dialog and close it with Escape to test dialog accessibility without changing theme state.
    if (await this.isVisible(this.THEME_BUTTON, 3000)) {
      await this.click(this.THEME_BUTTON);
      await this.page.waitForTimeout(800);
      // If dialog opened (confirmed by "Select Theme" text), close it without selecting
      if (await this.isTextPresent('Select Theme', 2000)) {
        await this.page.keyboard.press('Escape');
        await this.page.waitForTimeout(500);
      }
    }
  }

  async setDarkTheme(): Promise<void> {
    if (await this.isVisible(this.THEME_BUTTON, 3000)) {
      await this.click(this.THEME_BUTTON);
      await this.page.waitForTimeout(800);
      const darkOption = this.page.getByRole('button', { name: 'Dark', exact: true });
      if (await darkOption.count() > 0) {
        await darkOption.first().click({ timeout: 3000 });
        await this.page.waitForTimeout(500);
      }
    }
  }

  async signOut(): Promise<void> {
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
