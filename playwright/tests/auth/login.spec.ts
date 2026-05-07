import { test, expect } from '../../fixtures';
import { HomePage } from '../../pages/HomePage';
import { testUser } from '../../utils/test-data';

test.describe('Login @smoke', () => {
  test('login screen is displayed on navigation', async ({ loginPage }) => {
    expect(await loginPage.isLoginScreenDisplayed()).toBe(true);
    await loginPage.takeScreenshot('login-screen-displayed');
  });

  test('valid credentials navigate to home', async ({ loginPage, page }) => {
    const user = testUser();
    await loginPage.login(user.email, user.password);

    const home = new HomePage(page);
    expect(await home.isHomeScreenDisplayed()).toBe(true);
    await loginPage.takeScreenshot('login-success');
  });

  test('navigates to register via sign up link', async ({ loginPage }) => {
    await loginPage.clickRegisterLink();
    await expect(loginPage.page).toHaveURL(/register/);
    await loginPage.takeScreenshot('navigate-to-register');
  });
});

test.describe('Login validation @regression', () => {
  test('invalid email shows error or stays on login screen', async ({ loginPage }) => {
    await loginPage.login('not-an-email', 'Password123!');
    const onLogin = await loginPage.isLoginScreenDisplayed();
    const hasError = await loginPage.isErrorDisplayed();
    expect(onLogin || hasError).toBe(true);
    await loginPage.takeScreenshot('invalid-email');
  });

  test('wrong password shows error or stays on login screen', async ({ loginPage }) => {
    const user = testUser();
    await loginPage.login(user.email, 'WrongPassword999!');
    const onLogin = await loginPage.isLoginScreenDisplayed();
    const hasError = await loginPage.isErrorDisplayed();
    expect(onLogin || hasError).toBe(true);
    await loginPage.takeScreenshot('wrong-password');
  });

  test('empty fields — submit stays on login screen', async ({ loginPage }) => {
    await loginPage.clickLogin();
    expect(
      (await loginPage.isLoginScreenDisplayed()) || (await loginPage.isErrorDisplayed()),
    ).toBe(true);
    await loginPage.takeScreenshot('empty-fields');
  });

  test('password field masks input', async ({ loginPage }) => {
    await loginPage.enterPassword('TestPassword123!');
    const type = await loginPage.getAttribute(loginPage.PASSWORD_INPUT, 'type');
    expect(type).toBe('password');
    await loginPage.takeScreenshot('password-masked');
  });
});

test.describe('Session persistence @regression', () => {
  test('user stays logged in after page refresh', async ({ loggedInPage, page }) => {
    expect(await loggedInPage.isHomeScreenDisplayed()).toBe(true);
    await page.reload();
    await page.waitForLoadState('networkidle');
    // Flutter accessibility tree resets on reload — re-enable before checking home content
    await loggedInPage.waitForFlutter();
    expect(await loggedInPage.isHomeScreenDisplayed()).toBe(true);
    await loggedInPage.takeScreenshot('session-persists-after-refresh');
  });

  test('logout returns to login screen', async ({ loggedInPage, page }) => {
    await loggedInPage.signOut();
    await expect(page).toHaveURL(/login/);
    await loggedInPage.takeScreenshot('logout-success');
  });
});
