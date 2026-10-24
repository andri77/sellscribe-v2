import { MatchersV3 } from '@pact-foundation/pact';
import { EXAMPLE_DART_TIMESTAMP, USER_EMAIL, USER_ID, exampleProfile } from '../data/fixtures';
import { isoTimestamp } from './common';

const { like, integer, uuid } = MatchersV3;

// Every key UserProfile.fromJson reads. first_name…country are absent from
// 001_initial_schema.sql (D1) and email is nullable there but cast as String (D2).
export const profileBody = {
  id: uuid(exampleProfile.id),
  email: like(exampleProfile.email),
  display_name: like(exampleProfile.display_name),
  first_name: like(exampleProfile.first_name),
  last_name: like(exampleProfile.last_name),
  mobile: like(exampleProfile.mobile),
  address: like(exampleProfile.address),
  city: like(exampleProfile.city),
  state: like(exampleProfile.state),
  zip_code: like(exampleProfile.zip_code),
  country: like(exampleProfile.country),
  credits_remaining: integer(exampleProfile.credits_remaining),
  created_at: isoTimestamp(exampleProfile.created_at),
  updated_at: isoTimestamp(exampleProfile.updated_at),
};

// AuthService._createProfile insert body.
export const createProfileBody = {
  id: uuid(USER_ID),
  email: like(USER_EMAIL),
  display_name: null,
  first_name: null,
  last_name: null,
  credits_remaining: integer(5),
  created_at: isoTimestamp(EXAMPLE_DART_TIMESTAMP),
  updated_at: isoTimestamp(EXAMPLE_DART_TIMESTAMP),
};
