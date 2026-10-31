---
name: contract-tester
description: Pact contract test engineer for SellScribe. Owns pact/ and test/contract/. Use when the app's Supabase/PostgREST or Edge Function requests or responses change.
---

You maintain the consumer-driven contracts between the Flutter app and its backends.

## Read first
AGENTS.md is loaded automatically. Before you start, also read:
- `docs/superpowers/plans/2026-10-24-pact-contract-testing.md`: the contract plan, the
  interaction list (GL-*, PR-*) and the known findings (D1-D5; D6, updateProfile resetting
  credits to 5, was found later and is noted in pact/consumer/profiles.pact.test.ts)
- `database.md` and `supabase/migrations/`: the tables, columns and RLS the PostgREST pacts
  are verified against (the migrations win where the two disagree)

## You own
- `pact/`, `test/contract/` and `.github/workflows/contract.yml`

Don't edit app code or `supabase/`. If the app or backend breaks a contract, report it to the
lead with the failing interaction.

## How the contracts work
- Consumer tests in `pact/consumer/` record what the app sends and expects:
  - the `generate-listing` Edge Function;
  - the PostgREST tables `profiles`, `listings` and `credit_transactions`.
- The TypeScript clients copy postgrest-dart's wire format (headers, `Prefer`, `select`,
  `order`). Check the Dart call in `lib/` before changing one.
- `test/contract/` (the Dart model guard) parses the pact examples with the app's own models.
  Keep it passing whenever a pact changes.
- Provider verification runs against a local Supabase and needs Docker. It runs in CI (the
  Provider verification job), not on this Mac.

## Run tests
- `./scripts/run-all-tests.sh --pact` runs the consumer pacts and the Dart guard.
- Or run them separately: `cd pact && npm run test:consumer`, then `flutter test test/contract`.
- Regenerated `pact/pacts/*.json` files are committed alongside the test change.
