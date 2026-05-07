# Design Spec: TypeScript Playwright Demo Suite
**Date:** 2026-05-07  
**Target:** Origin Energy — Automation Tester, Squad 3 (Chat)  
**Status:** Approved

---

## 1. Goal

Transform the existing Python Playwright UI tests into a production-grade TypeScript Playwright suite that serves as a recruiter demo aligned to Origin Energy's engineering stack (TypeScript / Node / API-first / CI/CD / AI-led delivery).

Deliverables:
- Full TypeScript Playwright suite in a new `playwright/` directory
- API tests using Playwright's native `APIRequestContext`
- GitHub Actions CI/CD pipeline (`.github/workflows/playwright.yml`)
- Recruiter-facing documentation (`TESTING_PORTFOLIO.md`)

---

## 2. Context

**SellScribe** is a Flutter Web + Supabase + OpenAI app. It has:
- An existing Python/Playwright UI test suite (`test_web/`) with POM architecture — kept as-is
- An existing Appium mobile suite (`test_mobile/`) — kept as-is
- A Supabase Edge Function API: `POST /functions/v1/generate-listing`
- No GitHub Actions pipeline yet
- No TypeScript test layer yet

**Target role:** Automation Tester, Origin Energy Squad 3 (Chat — most urgent).  
Stack: TypeScript, Node.js, AWS, API-first design, CI/CD, LLM integrations, AI-led delivery.

---

## 3. Architecture

### 3.1 Directory Structure

```
playwright/                           # New top-level TypeScript Playwright suite
├── playwright.config.ts              # Multi-browser config, reporters, base URL
├── package.json                      # Dependencies: @playwright/test, typescript, dotenv
├── tsconfig.json                     # Strict TypeScript config
├── .env.example                      # Required env vars template
├── fixtures/
│   └── index.ts                      # Typed custom fixtures (replaces conftest.py)
├── pages/
│   ├── BasePage.ts                   # Common helpers: click, fill, waitFor, screenshot
│   ├── LoginPage.ts
│   ├── RegisterPage.ts
│   ├── HomePage.ts
│   ├── UploadPage.ts
│   ├── HistoryPage.ts
│   └── SettingsPage.ts
├── tests/
│   ├── auth/
│   │   ├── login.spec.ts             # Smoke + regression login tests
│   │   └── register.spec.ts         # Registration flow tests
│   ├── features/
│   │   ├── home.spec.ts             # Dashboard tests
│   │   ├── listing.spec.ts          # Listing generation flow
│   │   └── settings.spec.ts         # Settings/profile tests
│   └── api/
│       └── generate-listing.spec.ts  # API contract + error + mock tests
└── utils/
    └── test-data.ts                  # Test data factories

.github/
└── workflows/
    └── playwright.yml                # CI: Chromium + Firefox matrix, artifact upload

TESTING_PORTFOLIO.md                  # Recruiter showpiece at repo root
```

### 3.2 Python Suite Preserved

The existing `test_web/` (Python) and `test_mobile/` (Appium) directories are **untouched**. The TypeScript suite is additive — showing breadth across Python POM and TypeScript Playwright in the same repo.

---

## 4. Test Design

### 4.1 Fixtures Pattern

Custom fixtures extend Playwright's `test` base, typed with page objects:

```typescript
// fixtures/index.ts
import { test as base } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { HomePage } from '../pages/HomePage';

type Fixtures = {
  loginPage: LoginPage;
  homePage: HomePage;
  loggedInPage: HomePage;
};

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    const lp = new LoginPage(page);
    await lp.navigate();
    await use(lp);
  },
  loggedInPage: async ({ page }, use) => {
    const lp = new LoginPage(page);
    await lp.navigate();
    await lp.login(process.env.TEST_EMAIL!, process.env.TEST_PASSWORD!);
    const hp = new HomePage(page);
    await use(hp);
  },
});

export { expect } from '@playwright/test';
```

### 4.2 Page Object Pattern

```typescript
// pages/BasePage.ts
import { Page, Locator } from '@playwright/test';

export class BasePage {
  constructor(protected page: Page) {}

  async navigate(path = '') {
    await this.page.goto(path);
    await this.page.waitForLoadState('networkidle');
    await this.enableFlutterAccessibility();
  }

  protected async enableFlutterAccessibility() {
    await this.page.evaluate(() => {
      const el = document.querySelector('flt-semantics-placeholder');
      if (el) { (el as HTMLElement).click(); }
    });
    await this.page.waitForTimeout(1000);
  }

  async takeScreenshot(name: string) {
    await this.page.screenshot({ path: `test-results/screenshots/${name}.png`, fullPage: true });
  }
}
```

### 4.3 API Tests

Three categories in `tests/api/generate-listing.spec.ts`:

**Contract tests** — validate happy-path response schema:
```typescript
test('returns valid listing schema for complete payload', async ({ request }) => {
  const res = await request.post('/functions/v1/generate-listing', {
    data: { productName: 'Bamboo Charger', category: 'Electronics', tone: 'professional' }
  });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body).toHaveProperty('title');
  expect(body).toHaveProperty('description');
  expect(Array.isArray(body.bullets)).toBe(true);
  expect(Array.isArray(body.tags)).toBe(true);
});
```

**Error tests** — validate 400 cases (missing required fields, invalid tone):
```typescript
test('returns 400 when productName is missing', async ({ request }) => {
  const res = await request.post('/functions/v1/generate-listing', {
    data: { category: 'Electronics', tone: 'professional' }
  });
  expect(res.status()).toBe(400);
});
```

**Mock/integration tests** — use `page.route()` to intercept in UI flows:
```typescript
test('renders generated listing content in UI', async ({ page }) => {
  await page.route('**/generate-listing', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        title: 'Premium Bamboo Wireless Charger',
        description: '<p>Eco-friendly charging solution.</p>',
        bullets: ['Fast 15W charging', 'Eco-friendly bamboo'],
        tags: ['wireless-charger', 'eco-friendly']
      })
    })
  );
  // Navigate through UI flow, assert content renders
});
```

**Mode switching:** `USE_REAL_API=true` env var enables real Supabase calls. CI runs mock mode. Local demo runs real.

### 4.4 Test Tags

```typescript
test.describe('Login @smoke', () => { ... });    // Quick sanity
test.describe('Login @regression', () => { ... }); // Full coverage
// CLI: npx playwright test --grep @smoke
```

---

## 5. CI/CD Pipeline

### `.github/workflows/playwright.yml`

```yaml
name: Playwright Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        browser: [chromium, firefox]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - name: Install dependencies
        run: cd playwright && npm ci
      - name: Install Playwright browsers
        run: cd playwright && npx playwright install --with-deps ${{ matrix.browser }}
      - name: Run tests
        run: cd playwright && npx playwright test --project=${{ matrix.browser }}
        env:
          BASE_URL: ${{ secrets.BASE_URL }}
          TEST_EMAIL: ${{ secrets.TEST_EMAIL }}
          TEST_PASSWORD: ${{ secrets.TEST_PASSWORD }}
      - name: Upload report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report-${{ matrix.browser }}
          path: playwright/playwright-report/
```

---

## 6. Documentation — TESTING_PORTFOLIO.md

Sections:

1. **About SellScribe** — real-world app context, not a toy project
2. **Test Strategy** — pyramid thinking: unit (Flutter), UI E2E (Playwright TS + Python), API contract, mobile (Appium)
3. **Playwright Architecture** — POM, fixtures, typed tests, API testing in one framework
4. **MCP & AI-Augmented Testing** — how Anthropic's Model Context Protocol (via Claude Code) was used throughout: generating page objects, reviewing test coverage, writing GitHub Actions, iterating on specs. Directly mirrors Origin's AI-led delivery approach.
5. **CI/CD Pipeline** — GitHub Actions walkthrough, artifact uploads, matrix strategy
6. **Running Locally** — one-command setup with npm

The MCP section explicitly bridges to Origin's Squad 3 differentiator: *"Developers structure requirements for AI generation, outputs are reviewed and refined."*

---

## 7. Out of Scope

- Migrating `test_mobile/` to TypeScript (Appium stays Python)
- Visual regression testing (Applitools)
- Performance testing
- Accessibility automated checks
- Allure reporting (HTML reporter sufficient for demo)

---

## 8. Success Criteria

- [ ] TypeScript Playwright suite runs headless with `npx playwright test`
- [ ] API tests cover: happy path, 400 error, mock intercept
- [ ] GitHub Actions pipeline passes on push
- [ ] `TESTING_PORTFOLIO.md` clearly articulates Playwright + MCP + AI-augmented testing
- [ ] Recruiter can clone repo, run `npm ci && npx playwright test` and see results
