# Testing Portfolio — SellScribe

> A production-grade, multi-layer test automation suite built with Playwright (TypeScript), Appium (Python), and GitHub Actions CI/CD.

## About SellScribe

SellScribe is an AI-powered Shopify product listing generator. Users upload product images, provide details, and receive GPT-4o-generated titles, descriptions, bullet points, and SEO tags in seconds.

**Tech stack:** Flutter Web · Supabase (Auth, PostgreSQL, Storage, Edge Functions) · OpenAI GPT-4o · Vercel

**Why it's a realistic test target:** Real authentication flows, AI API calls, file uploads, credit transactions, and a Flutter/canvas DOM that requires accessibility unlocking before Playwright can interact with it — a non-trivial testing challenge that mirrors enterprise complexity.

---

## Test Strategy

Testing follows a layered pyramid approach:

```
                    ┌─────────────────┐
                    │   E2E (Smoke)   │  ← Playwright TS: critical user journeys
                    └────────┬────────┘
               ┌─────────────┴────────────┐
               │  Integration & API Tests  │  ← Playwright APIRequestContext + route mocking
               └────────────┬─────────────┘
         ┌───────────────────┴─────────────────────┐
         │     Regression UI Tests (Playwright)     │  ← Full POM suite, multi-browser
         └───────────────────┬─────────────────────┘
   ┌──────────────────────────┴──────────────────────────┐
   │         Mobile Tests (Appium / Python)               │  ← iOS & Android flows
   └─────────────────────────────────────────────────────┘
```

| Layer | Tool | Coverage |
|-------|------|----------|
| E2E smoke | Playwright (TypeScript) | Login, home, listing generation |
| Regression UI | Playwright (TypeScript) | Auth validation, navigation, settings |
| API contract | Playwright `APIRequestContext` | Edge function schema, error codes, CORS |
| Mobile E2E | Appium + Python | iOS/Android login, register, listing flows |
| Unit | Flutter test | Widget rendering |

---

## Playwright Architecture

### Why TypeScript Playwright?

Playwright's native language is TypeScript. Choosing TypeScript for this suite aligns with Origin Energy's stack (TypeScript / Node.js / AWS) and unlocks full type safety, IDE autocompletion, and zero-friction integration with Node-based CI pipelines.

### Page Object Model (POM)

Every screen has a dedicated page class. Tests never contain selectors — they call named methods.

```
playwright/
├── pages/
│   ├── BasePage.ts          ← shared helpers (click, fill, Flutter accessibility)
│   ├── LoginPage.ts         ← login selectors + typed action methods
│   ├── RegisterPage.ts
│   ├── HomePage.ts
│   ├── UploadPage.ts
│   ├── HistoryPage.ts
│   └── SettingsPage.ts
├── fixtures/
│   └── index.ts             ← typed fixtures (replaces pytest conftest.py)
├── tests/
│   ├── auth/                ← login.spec.ts, register.spec.ts
│   ├── features/            ← home, listing, settings specs
│   └── api/                 ← generate-listing.spec.ts
└── utils/
    └── test-data.ts         ← factories and mock payloads
```

### Flutter Web Challenge

Flutter renders to an HTML canvas, not standard DOM elements. Playwright cannot interact with it directly. Solution: trigger the `flt-semantics-placeholder` click to enable Flutter's accessibility/semantic tree, which exposes ARIA-labelled elements that Playwright can target.

```typescript
// BasePage.ts — every page navigation calls this automatically
protected async enableFlutterAccessibility(): Promise<void> {
  await this.page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    if (el) (el as HTMLElement).click();
  });
  await this.page.waitForTimeout(1000);
}
```

### Typed Fixtures

Playwright's fixture system provides dependency injection. Custom fixtures replace pytest's `conftest.py`:

```typescript
export const test = base.extend<{
  loginPage: LoginPage;
  loggedInPage: HomePage;  // pre-authenticated session
}>({
  loggedInPage: async ({ page }, use) => {
    const lp = new LoginPage(page);
    await lp.navigate();
    await lp.login(process.env.TEST_EMAIL!, process.env.TEST_PASSWORD!);
    await use(new HomePage(page));
  },
});
```

### API Testing in One Framework

No separate tool needed. Playwright's `APIRequestContext` tests HTTP endpoints directly:

```typescript
// Contract test — validates the Supabase Edge Function schema
const res = await request.post('/functions/v1/generate-listing', {
  data: { productName: 'Bamboo Charger', category: 'Electronics', tone: 'professional' },
});
expect(res.status()).toBe(200);
expect(Array.isArray((await res.json()).bullets)).toBe(true);
```

### Network Mocking for CI

`page.route()` intercepts API calls at the browser level — no mock server required:

```typescript
await page.route('**/generate-listing**', (route) =>
  route.fulfill({ status: 200, contentType: 'application/json',
    body: JSON.stringify(mockListingResponse) })
);
```

This means CI runs fast and reliably without live API keys, while the same test suite validates real responses locally with `USE_REAL_API=true`.

---

## MCP & AI-Augmented Testing

**MCP (Model Context Protocol)** is Anthropic's open standard that lets AI models like Claude interact directly with development tools — reading files, running commands, making edits — through a structured tool-use protocol.

This suite was built using **Claude Code**, an AI coding assistant powered by Claude, operating via MCP. In practice, this means:

| Traditional approach | AI-augmented approach (this project) |
|---|---|
| Write selectors manually | Claude reads existing Python POM and generates TypeScript equivalents |
| Author GitHub Actions by hand | Claude generates the matrix pipeline from the framework structure |
| Manually write API contract tests | Claude reads the Edge Function source and derives test cases |
| Iterate on spec separately | Claude authors, reviews, and self-corrects implementation plans |

**Why this matters for Origin Energy Squad 3:** The brief describes an intentionally AI-led delivery approach — *"Developers and BAs structure requirements for AI generation. Outputs are reviewed, refined and optimised."*

That's exactly how this suite was built:
1. Requirements structured as a design spec
2. Claude generated page objects, fixtures, tests, CI config
3. Each output reviewed and refined
4. The result is production-quality code, not throwaway AI output

This is the workflow that will scale AI-led test automation at enterprise level.

---

## CI/CD Pipeline

### GitHub Actions

Every push to `main` and every pull request triggers a parallel multi-browser pipeline:

```
push/PR → ubuntu-latest
          ├── chromium job
          │   └── install → test → upload HTML report + screenshots
          └── firefox job
              └── install → test → upload HTML report + screenshots
```

**Key design decisions:**
- `fail-fast: false` — both browsers run even if one fails, giving complete cross-browser signal
- `retries: 2` in CI — flakiness from Flutter render timing is handled, not masked
- Artifacts retained 30 days — historical pass/fail evidence available
- Secrets via GitHub repo secrets — never hardcoded

### Running Locally

```bash
# First time setup
cd playwright
npm install
npx playwright install chromium firefox

# Copy and configure environment
cp .env.example .env
# Edit .env: add BASE_URL, TEST_EMAIL, TEST_PASSWORD

# Run all tests (headless)
npm test

# Run only smoke tests (fast feedback)
npm run test:smoke

# Run API tests only
npm run test:api

# Run with browser visible
npm run test:headed

# Run against real Supabase API
USE_REAL_API=true SUPABASE_URL=https://xxx.supabase.co SUPABASE_ANON_KEY=eyJ... npm test

# View HTML report
npm run report
```

### Test Tags

| Tag | Purpose | Command |
|-----|---------|---------|
| `@smoke` | Critical path, fast feedback | `npm run test:smoke` |
| `@regression` | Full coverage | `npm test` |
| `@api` | API contract tests only | `npm run test:api` |

---

## Test Coverage Summary

| Area | Tests | Type |
|------|-------|------|
| Login — happy path | 3 | Smoke |
| Login — validation | 4 | Regression |
| Session persistence | 2 | Regression |
| Registration — happy path | 2 | Smoke |
| Registration — validation | 4 | Regression |
| Home dashboard | 5 | Smoke + Regression |
| Listing generation | 2 | Smoke (mocked) |
| Settings / profile | 5 | Smoke + Regression |
| API — contract (real) | 5 | Regression (gated) |
| API — mock/integration | 4 | Smoke |
| **Total** | **36** | **Multi-layer** |

---

*Built with Playwright 1.48 · TypeScript 5 · GitHub Actions · Claude Code (MCP)*
