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
  webServer: {
    command: 'flutter run -d web-server --web-port=8080',
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
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: "off",
    ignoreHTTPSErrors: true,
    viewport: { width: 1920, height: 1080 },
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // Firefox: API contract tests only — Flutter web does not render in Firefox.
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      testMatch: '**/api/**',
    },
  ],
});
