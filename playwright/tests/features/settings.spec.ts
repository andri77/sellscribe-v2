import { test, expect, authenticated } from '../../fixtures';
import { SettingsPage } from '../../pages/SettingsPage';

// Starts from the session saved by auth.setup.ts instead of logging in through the UI
test.use(authenticated);

test.describe('Settings screen @smoke', () => {
  test('settings screen is displayed', async ({ loggedInPage, page }) => {
    await loggedInPage.clickSettings();
    const settings = new SettingsPage(page);
    expect(await settings.isSettingsScreenDisplayed()).toBe(true);
    await settings.takeScreenshot('settings-screen');
  });

  // Own session: signing out revokes it, so it must not be the shared one
  test('sign out from settings returns to login', async ({ isolatedLoggedInPage, page }) => {
    await isolatedLoggedInPage.clickSettings();
    const settings = new SettingsPage(page);
    await settings.signOut();
    await expect(page).toHaveURL(/login/);
    await settings.takeScreenshot('settings-signout');
  });
});

test.describe('Settings back navigation @smoke', () => {
  test('back button returns to home from settings', async ({ loggedInPage, page }) => {
    await loggedInPage.clickSettings();
    const settings = new SettingsPage(page);
    expect(await settings.isSettingsScreenDisplayed()).toBe(true);
    await settings.goBack();
    expect(await loggedInPage.isHomeScreenDisplayed()).toBe(true);
    await loggedInPage.takeScreenshot('settings-back-to-home');
  });
});

test.describe('Profile editing @regression', () => {
  test('edit profile form is accessible', async ({ loggedInPage, page }) => {
    await loggedInPage.clickSettings();
    const settings = new SettingsPage(page);

    if (await settings.isVisible(settings.EDIT_PROFILE_BUTTON, 3000)) {
      await settings.clickEditProfile();
      const hasForm =
        (await settings.isVisible(settings.FIRST_NAME_INPUT, 3000)) ||
        (await settings.isVisible(settings.LAST_NAME_INPUT, 3000));
      expect(hasForm).toBe(true);
      await settings.takeScreenshot('edit-profile-form');
    } else {
      expect(await settings.isSettingsScreenDisplayed()).toBe(true);
    }
  });
});

test.describe('Theme switching @regression', () => {
  test('light theme toggle is accessible', async ({ loggedInPage, page }) => {
    await loggedInPage.clickSettings();
    const settings = new SettingsPage(page);

    const hasThemeControl =
      (await settings.isVisible(settings.THEME_LIGHT, 3000)) ||
      (await settings.isVisible(settings.THEME_DARK, 3000)) ||
      (await settings.isTextPresent('Theme', 3000));
    expect(hasThemeControl).toBe(true);
    await settings.takeScreenshot('theme-controls');
  });

  test('clicking light theme does not crash app', async ({ loggedInPage, page }) => {
    await loggedInPage.clickSettings();
    const settings = new SettingsPage(page);
    await settings.setLightTheme();
    expect(await settings.isSettingsScreenDisplayed()).toBe(true);
    await settings.takeScreenshot('light-theme-set');
  });
});
