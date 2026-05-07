import { Page } from '@playwright/test';
import { BasePage } from './BasePage';

export class HomePage extends BasePage {
  private readonly baseUrl: string;

  readonly CREATE_LISTING_BUTTON = "flt-semantics[role='button']:has-text('Create Listing'), flt-semantics[role='button']:has-text('New Listing'), [data-testid='create-listing'], button:has-text('Create Listing')";
  readonly CREDITS_DISPLAY = "[data-testid='credits-display'], .credits, [class*='credit']";
  readonly HISTORY_LINK = "flt-semantics[role='button']:has-text('History'), flt-semantics[role='link']:has-text('History'), [data-testid='history-link'], a:has-text('History')";
  readonly SETTINGS_LINK = "flt-semantics[role='button']:has-text('Settings'), [data-testid='settings-link'], a:has-text('Settings')";
  readonly SIGN_OUT_BUTTON = "flt-semantics[role='button']:has-text('Sign Out'), flt-semantics[role='button']:has-text('Logout'), [data-testid='sign-out'], button:has-text('Sign Out')";
  readonly PROFILE_MENU = "flt-semantics[role='button']:has-text('Profile'), [data-testid='profile-menu'], [aria-label='Profile']";
  readonly WELCOME_MESSAGE = "[data-testid='welcome-message'], .welcome, h1:has-text('Welcome'), h2:has-text('Welcome')";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/dashboard`);
  }

  async isHomeScreenDisplayed(): Promise<boolean> {
    return (
      (await this.isVisible(this.CREATE_LISTING_BUTTON, 5000)) ||
      (await this.isVisible(this.WELCOME_MESSAGE, 3000)) ||
      (await this.isTextPresent('Dashboard', 3000)) ||
      (await this.isTextPresent('Create Listing', 3000))
    );
  }

  async getCreditsRemaining(): Promise<number> {
    if (await this.isVisible(this.CREDITS_DISPLAY, 3000)) {
      const text = await this.getText(this.CREDITS_DISPLAY);
      const match = text.match(/\d+/);
      return match ? parseInt(match[0], 10) : 0;
    }
    return 0;
  }

  async clickCreateListing(): Promise<void> {
    await this.click(this.CREATE_LISTING_BUTTON);
    await this.waitForLoadState();
  }

  async clickHistory(): Promise<void> {
    await this.click(this.HISTORY_LINK);
    await this.waitForLoadState();
  }

  async clickSettings(): Promise<void> {
    await this.click(this.SETTINGS_LINK);
    await this.waitForLoadState();
  }

  async signOut(): Promise<void> {
    if (await this.isVisible(this.PROFILE_MENU, 3000)) {
      await this.click(this.PROFILE_MENU);
    }
    await this.click(this.SIGN_OUT_BUTTON);
    await this.waitForLoadState();
  }

  async isCreditsVisible(): Promise<boolean> {
    return this.isVisible(this.CREDITS_DISPLAY, 3000);
  }
}
