import { test as setup } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { AUTH_FILE, createSession } from '../utils/auth';

// Signs in once per run; tests that need a logged-in user start from this storage state
// instead of going through the login screen. The UI login flow itself is covered by
// login.spec.ts "valid credentials navigate to home".
setup('create authenticated storage state', async ({ baseURL }) => {
  const entry = await createSession();
  const state = {
    cookies: [],
    origins: [{ origin: new URL(baseURL!).origin, localStorage: [entry] }],
  };
  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true });
  fs.writeFileSync(AUTH_FILE, JSON.stringify(state, null, 2));
});
