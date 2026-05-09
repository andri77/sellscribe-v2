import { Page } from '@playwright/test';
import { BasePage } from './BasePage';

export class HomePage extends BasePage {
  private readonly baseUrl: string;

  // Selectors verified against live Flutter DOM inspection
  readonly CREATE_LISTING_BUTTON = "flt-semantics[role='button']:has-text('Create Listing'), [data-testid='create-listing'], button:has-text('Create Listing')";
  // Credits shows as text number + 'credits' label in AppBar
  readonly CREDITS_DISPLAY = "flt-semantics:has-text('credits'), [data-testid='credits-display'], [aria-label*='credit' i]";
  // Home has a 'View History' card (title in home_screen.dart cards)
  readonly HISTORY_LINK = "flt-semantics[role='button']:has-text('View History'), flt-semantics[role='button']:has-text('History'), [data-testid='history-link'], a:has-text('History')";
  // Settings and Sign out are in PopupMenuButton — tooltip='profile-menu'.
  // Flutter web exposes tooltip as text content on the flt-semantics button node.
  // Fallback covers the Material default "Show menu" label if tooltip is ever removed.
  readonly SHOW_MENU_BUTTON = "flt-semantics[role='button']:has-text('profile-menu'), flt-semantics[role='button'][aria-label='profile-menu'], flt-semantics[role='button']:has-text('Show menu')";
  readonly SETTINGS_MENU_ITEM = "flt-semantics[role='menuitem'][aria-label='Settings']";
  readonly SIGN_OUT_MENU_ITEM = "flt-semantics[role='menuitem'][aria-label='Sign out']";
  // SellScribe appears in AppBar — most reliable home indicator
  readonly APP_TITLE = "flt-semantics:has-text('SellScribe'), text=SellScribe";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/home`);
  }

  async isHomeScreenDisplayed(): Promise<boolean> {
    return (
      (await this.isTextPresent('SellScribe', 5000)) &&
      ((await this.isTextPresent('Create Listing', 3000)) ||
        (await this.isTextPresent('View History', 3000)))
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
