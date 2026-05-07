import { Page, Locator } from '@playwright/test';

export class BasePage {
  readonly page: Page;
  protected readonly timeout = 10_000;

  constructor(page: Page) {
    this.page = page;
  }

  async navigate(path: string): Promise<void> {
    await this.page.goto(path);
    await this.page.waitForLoadState('networkidle');
    await this.enableFlutterAccessibility();
  }

  protected async enableFlutterAccessibility(): Promise<void> {
    try {
      await this.page.evaluate(() => {
        const el = document.querySelector('flt-semantics-placeholder');
        if (el) (el as HTMLElement).click();
      });
      await this.page.waitForTimeout(1000);
    } catch {
      // Accessibility already enabled or not a Flutter page
    }
  }

  async click(selector: string): Promise<void> {
    await this.page.click(selector, { timeout: this.timeout });
  }

  async fill(selector: string, value: string): Promise<void> {
    await this.page.fill(selector, '', { timeout: this.timeout });
    await this.page.fill(selector, value, { timeout: this.timeout });
  }

  async isVisible(selector: string, timeout = this.timeout): Promise<boolean> {
    try {
      await this.page.waitForSelector(selector, { state: 'visible', timeout });
      return true;
    } catch {
      return false;
    }
  }

  async getText(selector: string): Promise<string> {
    return (await this.page.textContent(selector)) ?? '';
  }

  async getAttribute(selector: string, attr: string): Promise<string | null> {
    return this.page.getAttribute(selector, attr);
  }

  async waitForLoadState(): Promise<void> {
    await this.page.waitForLoadState('networkidle');
  }

  async isTextPresent(text: string, timeout = 3000): Promise<boolean> {
    try {
      await this.page.waitForSelector(`text=${text}`, { timeout });
      return true;
    } catch {
      return false;
    }
  }

  async takeScreenshot(name: string): Promise<void> {
    await this.page.screenshot({
      path: `playwright-report/screenshots/${name}-${Date.now()}.png`,
      fullPage: true,
    });
  }

  async pressEnter(): Promise<void> {
    await this.page.keyboard.press('Enter');
  }

  async scrollToElement(selector: string): Promise<void> {
    await this.page.locator(selector).scrollIntoViewIfNeeded();
  }

  locator(selector: string): Locator {
    return this.page.locator(selector);
  }
}
