import { Page, Locator } from '@playwright/test';

// Flutter web (3.47+) puts the semantic ID from `semanticsLabel` on a disabled twin <input>;
// the editable input is its sibling inside the same flt-semantics node. Locate by ID, then step
// to the enabled input. See AGENTS.md "Semantic Element Identifiers".
export function semanticInput(id: string): string {
  return `flt-semantics:has(> input[aria-label='${id}']) input:not([disabled])`;
}

// Flutter renders a semantic ID on a tappable in one of three shapes, depending on the widget:
//   1. AppButton / Semantics(label:) over a button → role=group[aria-label=id] > role=button
//   2. Semantics(label:) over a ListTile           → role=button[aria-label=id]
//   3. Semantics(label:, button: true) / tooltip   → role=button whose text starts with the id
export function semanticButton(id: string): string {
  return (
    `flt-semantics[aria-label='${id}'] > flt-semantics[role='button'], ` +
    `flt-semantics[role='button'][aria-label='${id}'], ` +
    `flt-semantics[role='button']:has-text('${id}')`
  );
}

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
      // The placeholder only appears once Flutter renders its first frame (can lag networkidle on
      // a cold debug server). Once semantics are on, the placeholder is gone and flt-semantics
      // nodes exist instead — so wait for either, and only click when the placeholder is there.
      await this.page.waitForSelector('flt-semantics-placeholder, flt-semantics', {
        state: 'attached',
        timeout: 30_000,
      });
      const placeholder = this.page.locator('flt-semantics-placeholder');
      if ((await placeholder.count()) === 0) return;
      await placeholder.evaluate((el) => (el as HTMLElement).click());
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
