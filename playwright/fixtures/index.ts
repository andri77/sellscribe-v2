import { test as base, expect, Page } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { RegisterPage } from '../pages/RegisterPage';
import { HomePage } from '../pages/HomePage';
import { UploadPage } from '../pages/UploadPage';
import { HistoryPage } from '../pages/HistoryPage';
import { SettingsPage } from '../pages/SettingsPage';
import { authenticated, createSession } from '../utils/auth';

type Fixtures = {
  loginPage: LoginPage;
  registerPage: RegisterPage;
  homePage: HomePage;
  uploadPage: UploadPage;
  historyPage: HistoryPage;
  settingsPage: SettingsPage;
  loggedInPage: HomePage;
  isolatedLoggedInPage: HomePage;
};

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    const lp = new LoginPage(page);
    await lp.navigate();
    await use(lp);
  },

  registerPage: async ({ page }, use) => {
    const rp = new RegisterPage(page);
    await rp.navigate();
    await use(rp);
  },

  homePage: async ({ page }, use) => {
    await use(new HomePage(page));
  },

  uploadPage: async ({ page }, use) => {
    await use(new UploadPage(page));
  },

  historyPage: async ({ page }, use) => {
    await use(new HistoryPage(page));
  },

  settingsPage: async ({ page }, use) => {
    await use(new SettingsPage(page));
  },

  // Home screen from the shared session saved by auth.setup.ts; the spec must call
  // test.use(authenticated) so the page starts with that storage state.
  loggedInPage: async ({ page }, use) => {
    await use(await openHome(page));
  },

  // Home screen with a session of its own. Use this for tests that sign out: sign-out
  // revokes the session server-side, which would break the shared one for other tests.
  isolatedLoggedInPage: async ({ page }, use) => {
    const { name, value } = await createSession();
    // Seed once per tab, so a reload after sign-out does not log back in
    await page.addInitScript(([k, v]) => {
      if (!sessionStorage.getItem('pw-session-seeded')) {
        localStorage.setItem(k, v);
        sessionStorage.setItem('pw-session-seeded', '1');
      }
    }, [name, value]);
    await use(await openHome(page));
  },
});

async function openHome(page: Page): Promise<HomePage> {
  const home = new HomePage(page);
  await home.navigate();
  if (!(await home.isHomeScreenDisplayed())) {
    throw new Error('Home screen not shown: is the spec missing test.use(authenticated)?');
  }
  return home;
}

export { expect, authenticated };
