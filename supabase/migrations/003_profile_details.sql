-- Profile detail columns read by UserProfile.fromJson and written by AuthService.updateProfile.
-- They were documented in database.md but missing from 001_initial_schema.sql, so a fresh
-- database rejected profile writes with PGRST204 (pact plan finding D1).
-- IF NOT EXISTS keeps this safe on databases where the columns were added by hand.
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS first_name TEXT,
ADD COLUMN IF NOT EXISTS last_name TEXT,
ADD COLUMN IF NOT EXISTS mobile TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS zip_code TEXT,
ADD COLUMN IF NOT EXISTS country TEXT;
