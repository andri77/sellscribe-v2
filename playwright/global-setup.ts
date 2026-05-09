import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  const baseURL =
    (config.projects[0]?.use as { baseURL?: string })?.baseURL ??
    'http://localhost:8080';

  const browser = await chromium.launch();
  const page = await browser.newPage();
  try {
    // Navigate once to trigger Dart compilation. With 'flutter run -d web-server' the
    // HTTP server responds immediately but the Dart VM may need up to 90 s to finish
    // compiling on a cold start. We poll until flt-semantics-placeholder appears (first
    // rendered frame), then enable the accessibility tree so every test worker starts warm.
    await page.goto(baseURL, { timeout: 30_000 });
    await page.waitForSelector('flt-semantics-placeholder, flt-semantics', {
      timeout: 120_000,
    });
    // Activate the semantic overlay so the first test in each worker hits a pre-warmed app.
    await page.evaluate(() => {
      const el = document.querySelector('flt-semantics-placeholder');
      if (el) (el as HTMLElement).click();
    });
    await page.waitForTimeout(1000);
  } catch {
    // Timed out — tests will wait individually for Flutter to render.
  } finally {
    await browser.close();
  }
}

export default globalSetup;
