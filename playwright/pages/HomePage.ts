import { Page } from '@playwright/test';
import { BasePage, semanticButton } from './BasePage';

export class HomePage extends BasePage {
  private readonly baseUrl: string;

  readonly CREATE_LISTING_BUTTON = semanticButton('create-listing-button');
  // Credits shows as text number + 'credits' label in AppBar
  readonly CREDITS_DISPLAY = "flt-semantics:has-text('credits'), [data-testid='credits-display'], [aria-label*='credit' i]";
  readonly HISTORY_LINK = semanticButton('view-history-button');
  // Settings and Sign out live in the PopupMenuButton (tooltip='profile-menu'); the menu items
  // are Material defaults and expose their titles as aria-labels.
  readonly SHOW_MENU_BUTTON = semanticButton('profile-menu');
  readonly SETTINGS_MENU_ITEM = "flt-semantics[role='menuitem'][aria-label='Settings']";
  readonly SIGN_OUT_MENU_ITEM = "flt-semantics[role='menuitem'][aria-label='Sign out']";
  // SellScribe appears in AppBar — most reliable home indicator
  readonly APP_TITLE = "flt-semantics:has-text('SellScribe'), text=SellScribe";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/#/home`);
  }

  // Waits on the quick-action IDs; 15 s covers the Supabase sign-in round trip after login.
  async isHomeScreenDisplayed(): Promise<boolean> {
    return this.isVisible(`${this.CREATE_LISTING_BUTTON}, ${this.HISTORY_LINK}`, 15_000);
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
    await this.waitForFlutter();
  }

  async clickHistory(): Promise<void> {
    await this.click(this.HISTORY_LINK);
    await this.waitForLoadState();
    await this.waitForFlutter();
  }

  async clickSettings(): Promise<void> {
    // Settings is inside the PopupMenuButton — open menu first, then click Settings item
    await this.click(this.SHOW_MENU_BUTTON);
    await this.page.waitForTimeout(500);
    await this.click(this.SETTINGS_MENU_ITEM);
    await this.page.waitForTimeout(1000);
    await this.waitForLoadState();
  }

  async signOut(): Promise<void> {
    // Sign out is inside the PopupMenuButton — open menu first, then click Sign out item
    await this.click(this.SHOW_MENU_BUTTON);
    await this.page.waitForTimeout(500);
    await this.click(this.SIGN_OUT_MENU_ITEM);
    await this.waitForLoadState();
  }

  async isCreditsVisible(): Promise<boolean> {
    return (
      (await this.isVisible(this.CREDITS_DISPLAY, 3000)) ||
      (await this.isTextPresent('credits', 3000))
    );
  }
}
