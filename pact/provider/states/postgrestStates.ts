import type { StateHandlers } from '../types';
import {
  LISTING_ID,
  OTHER_LISTING_ID,
  OTHER_USER_ID,
  USER_EMAIL,
  USER_ID,
  exampleListingRow,
  exampleProfile,
  newListingRow,
} from '../../src/data/fixtures';
import {
  createUser,
  deleteRows,
  deleteUser,
  insertRows,
  patchRows,
  signIn,
} from './supabaseAdmin';

const OTHER_USER_EMAIL = 'pact-user2@example.com';
const SECOND_LISTING_ID = '55555555-5555-4555-8555-555555555555';

/** JWT for U1 — every C2 interaction is made as U1 (PR-12 included, to prove RLS). */
export let currentUserToken = '';

async function freshUser1() {
  await deleteUser(USER_ID);
  await deleteUser(OTHER_USER_ID);
  await createUser(USER_ID, USER_EMAIL);
  currentUserToken = await signIn(USER_EMAIL);
}

// Fills every column UserProfile.fromJson reads. Fails with PGRST204 while D1 is unfixed.
async function completeProfile() {
  const { id: _id, created_at: _c, updated_at: _u, ...details } = exampleProfile;
  await patchRows('profiles', `id=eq.${USER_ID}`, details);
}

export const postgrestStates: StateHandlers = {
  'user U1 has a profile with 5 credits': async () => {
    await freshUser1();
    await completeProfile();
  },

  'user U1 has no profile': async () => {
    await freshUser1();
    await deleteRows('profiles', `id=eq.${USER_ID}`);
  },

  'user U1 has 2 listings': async () => {
    await freshUser1();
    await completeProfile();
    await insertRows('listings', [
      { ...newListingRow, id: LISTING_ID },
      { ...newListingRow, id: SECOND_LISTING_ID, product_name: 'Bamboo Desk Organiser' },
    ]);
  },

  'listing L1 exists for user U1': async () => {
    await freshUser1();
    await completeProfile();
    const { created_at: _c, ...row } = exampleListingRow;
    await insertRows('listings', [row]);
  },

  'listing L2 exists for user U2': async () => {
    await freshUser1();
    await createUser(OTHER_USER_ID, OTHER_USER_EMAIL);
    await insertRows('listings', [{ ...newListingRow, id: OTHER_LISTING_ID, user_id: OTHER_USER_ID }]);
  },
};
