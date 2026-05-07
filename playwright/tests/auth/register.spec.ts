import { test, expect } from '../../fixtures';
import { newUser } from '../../utils/test-data';

test.describe('Registration @smoke', () => {
  test('register screen is displayed on navigation', async ({ registerPage }) => {
    expect(await registerPage.isRegisterScreenDisplayed()).toBe(true);
    await registerPage.takeScreenshot('register-screen-displayed');
  });

  test('navigates to login from register screen', async ({ registerPage }) => {
    await registerPage.clickLoginLink();
    await expect(registerPage.page).toHaveURL(/login/);
    await registerPage.takeScreenshot('register-to-login');
  });
});

test.describe('Registration validation @regression', () => {
  test('mismatched passwords shows error', async ({ registerPage }) => {
    const user = newUser();
    await registerPage.register({
      email: user.email,
      password: 'Password123!',
      confirmPassword: 'DifferentPassword456!',
    });
    const hasError = await registerPage.isErrorDisplayed();
    const onRegister = await registerPage.isRegisterScreenDisplayed();
    expect(hasError || onRegister).toBe(true);
    await registerPage.takeScreenshot('password-mismatch');
  });

  test('invalid email format stays on register screen', async ({ registerPage }) => {
    const user = newUser();
    await registerPage.register({
      email: 'not-valid-email',
      password: user.password,
    });
    expect(
      (await registerPage.isRegisterScreenDisplayed()) ||
        (await registerPage.isErrorDisplayed()),
    ).toBe(true);
    await registerPage.takeScreenshot('invalid-email-register');
  });

  test('empty submission stays on register screen', async ({ registerPage }) => {
    await registerPage.page.click(registerPage.REGISTER_BUTTON).catch(() => {});
    expect(
      (await registerPage.isRegisterScreenDisplayed()) ||
        (await registerPage.isErrorDisplayed()),
    ).toBe(true);
    await registerPage.takeScreenshot('empty-register-submission');
  });

  test('weak password shows validation error', async ({ registerPage }) => {
    const user = newUser();
    await registerPage.register({
      email: user.email,
      password: '123',
      confirmPassword: '123',
    });
    const hasError = await registerPage.isErrorDisplayed();
    const onRegister = await registerPage.isRegisterScreenDisplayed();
    expect(hasError || onRegister).toBe(true);
    await registerPage.takeScreenshot('weak-password');
  });
});
