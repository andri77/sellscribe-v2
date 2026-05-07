import { Page } from '@playwright/test';
import { BasePage } from './BasePage';

export class HistoryPage extends BasePage {
  private readonly baseUrl: string;

  readonly LISTING_ITEM = "[data-testid='listing-item'], .listing-item, .listing-card, [class*='listing']";
  readonly LISTING_TITLE = "[data-testid='listing-title'], .listing-title, h3, h4";
  readonly COPY_BUTTON = "[data-testid='copy-listing'], button:has-text('Copy'), button[aria-label='Copy']";
  readonly DELETE_BUTTON = "[data-testid='delete-listing'], button:has-text('Delete'), button[aria-label='Delete']";
  readonly SEARCH_INPUT = "[data-testid='search-input'], input[type='search'], input[placeholder*='search' i]";
  readonly EMPTY_STATE = "[data-testid='empty-state'], .empty-state, .no-listings, p:has-text('No listings')";
  readonly CONFIRM_DELETE = "[data-testid='confirm-delete'], button:has-text('Confirm'), button:has-text('Yes')";
  readonly BACK_BUTTON = "[data-testid='back-button'], button:has-text('Back'), a:has-text('Back'), [aria-label='Back']";

  constructor(page: Page, baseUrl = '') {
    super(page);
    this.baseUrl = baseUrl;
  }

  async navigate(): Promise<void> {
    await super.navigate(`${this.baseUrl}/history`);
  }

  async isHistoryScreenDisplayed(): Promise<boolean> {
    return (
      (await this.isTextPresent('History', 5000)) ||
      (await this.isVisible(this.LISTING_ITEM, 3000)) ||
      (await this.isVisible(this.EMPTY_STATE, 3000))
    );
  }

  async hasListings(): Promise<boolean> {
    return this.isVisible(this.LISTING_ITEM, 3000);
  }

  async getListingCount(): Promise<number> {
    return this.page.locator(this.LISTING_ITEM).count();
  }

  async isEmptyStateDisplayed(): Promise<boolean> {
    return this.isVisible(this.EMPTY_STATE, 3000);
  }

  async searchListings(query: string): Promise<void> {
    if (await this.isVisible(this.SEARCH_INPUT, 3000)) {
      await this.fill(this.SEARCH_INPUT, query);
      await this.pressEnter();
      await this.waitForLoadState();
    }
  }

  async goBack(): Promise<void> {
    if (await this.isVisible(this.BACK_BUTTON, 2000)) {
      await this.click(this.BACK_BUTTON);
    } else {
      await this.page.goBack();
    }
    await this.waitForLoadState();
  }
}
