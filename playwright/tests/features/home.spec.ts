import { test, expect, authenticated } from '../../fixtures';
import { SettingsPage } from '../../pages/SettingsPage';

// Starts from the session saved by auth.setup.ts instead of logging in through the UI
test.use(authenticated);

test.describe('Home Dashboard @smoke', () => {
  test('home screen is displayed after login', async ({ loggedInPage }) => {
    expect(await loggedInPage.isHomeScreenDisplayed()).toBe(true);
    await loggedInPage.takeScreenshot('home-dashboard');
  });

  test('credits counter is visible', async ({ loggedInPage }) => {
    expect(await loggedInPage.isCreditsVisible()).toBe(true);
    await loggedInPage.takeScreenshot('credits-visible');
  });

  test('create listing button is visible', async ({ loggedInPage }) => {
    expect(await loggedInPage.isVisible(loggedInPage.CREATE_LISTING_BUTTON)).toBe(true);
  });
});

test.describe('Home navigation @regression', () => {
  test('navigates to history from home', async ({ loggedInPage, page }) => {
    await loggedInPage.clickHistory();
    await expect(page).toHaveURL(/history/);
    await loggedInPage.takeScreenshot('navigate-to-history');
  });

  test('navigates to settings from home', async ({ loggedInPage, page }) => {
    await loggedInPage.clickSettings();
    // Flutter's hash routing with context.push() does not always update the URL fragment;
    // verify navigation by checking settings screen content instead
    const settings = new SettingsPage(page);
    expect(await settings.isSettingsScreenDisplayed()).toBe(true);
    await settings.takeScreenshot('navigate-to-settings');
  });

  test('navigates to upload on create listing click', async ({ loggedInPage, page }) => {
    await loggedInPage.clickCreateListing();
    await expect(page).toHaveURL(/upload|generator|create/);
    await loggedInPage.takeScreenshot('navigate-to-upload');
  });
});
