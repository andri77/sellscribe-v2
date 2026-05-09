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

  async waitForFlutter(): Promise<void> {
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
    // Flutter web needs time after click for its input handler to initialize before keystrokes land.
    // Without the wait, the first character is dropped. pressSequentially dispatches to the specific
    // element and reaches Flutter; page.fill() uses native browser fill which does not.
    const locator = this.page.locator(selector).first();
    await locator.click({ timeout: this.timeout });
    await this.page.waitForTimeout(150);
    await this.page.keyboard.press('Control+a');
    await this.page.keyboard.press('Delete');
    await locator.pressSequentially(value, { delay: 50 });
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
