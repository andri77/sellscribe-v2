import { defineConfig, devices } from '@playwright/test';
import * as dotenv from 'dotenv';

dotenv.config();

export default defineConfig({
  testDir: './tests',
  // globalSetup waits for flt-semantics-placeholder so tests don't race the Dart compile.
  globalSetup: './global-setup.ts',
  timeout: 60_000,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,

  // Start the Flutter web server automatically if not already running.
  // reuseExistingServer=true means a manually-started server on :8080 is reused during dev.
  // CI sets WEB_SERVER_CMD to serve a prebuilt release bundle, which skips the on-demand debug compile.
  webServer: {
    command: process.env.WEB_SERVER_CMD ?? 'flutter run -d web-server --web-port=8080',
    // The Flutter app lives at the repo root, not in playwright/
    cwd: '..',
    url: process.env.BASE_URL ?? 'http://localhost:8080',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    stdout: 'ignore',
    stderr: 'pipe',
  },

  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['list'],
    ['junit', { outputFile: 'playwright-report/results.xml' }],
  ],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:8080',
    // Off in CI: saving a trace of the Flutter canvas hangs until the test times out, so a
    // traced retry always failed. Published reports drop traces anyway (sanitize-report.py).
    trace: process.env.CI ? 'off' : 'on-first-retry',
    screenshot: 'only-on-failure',
    video: "off",
    ignoreHTTPSErrors: true,
    viewport: { width: 1920, height: 1080 },
  },
  projects: [
    // Signs the test user in once and saves .auth/user.json for test.use(authenticated)
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['setup'],
    },
    // Firefox: API contract tests only — Flutter web does not render in Firefox.
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      testMatch: '**/api/**',
    },
  ],
});
