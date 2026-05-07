import { test as base, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';
import { RegisterPage } from '../pages/RegisterPage';
import { HomePage } from '../pages/HomePage';
import { UploadPage } from '../pages/UploadPage';
import { HistoryPage } from '../pages/HistoryPage';
import { SettingsPage } from '../pages/SettingsPage';
import { testUser } from '../utils/test-data';

type Fixtures = {
  loginPage: LoginPage;
  registerPage: RegisterPage;
  homePage: HomePage;
  uploadPage: UploadPage;
  historyPage: HistoryPage;
  settingsPage: SettingsPage;
  loggedInPage: HomePage;
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

  loggedInPage: async ({ page }, use) => {
    const lp = new LoginPage(page);
    await lp.navigate();
    const user = testUser();
    await lp.login(user.email, user.password);
    await use(new HomePage(page));
  },
});

export { expect };
