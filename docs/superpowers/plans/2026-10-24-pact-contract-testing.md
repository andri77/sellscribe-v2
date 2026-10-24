# Pact Contract Testing — Development Plan

| | |
|---|---|
| **Status** | Draft for review |
| **Date** | 2026-10-24 |
| **Owner** | QA automation |
| **Estimate** | ~6 engineer-days across 6 milestones |
| **Depends on** | Playwright suite green on Chromium (done 2026-10-24) |

---

## 1. Goal

Add consumer-driven contract tests (Pact) to SellScribe so that a change on either side of an HTTP
boundary that breaks the other side fails in CI **before** deploy, without needing the full
Flutter + Supabase + OpenAI stack running.

Two boundaries are in scope:

| Consumer | Provider | Why it matters |
|---|---|---|
| Flutter app (`sellscribe-app`) | `generate-listing` Edge Function (`sellscribe-generate-listing`) | Request/response shape for AI generation; error codes the UI branches on. |
| Flutter app (`sellscribe-app`) | Supabase PostgREST (`sellscribe-postgrest`) | The DB schema *is* this API. Migrations can silently break the Dart models. |

### Success criteria
1. `npm run test:consumer` generates pact files for both providers offline in under 30 s.
2. Provider verification passes against a freshly migrated local Supabase.
3. A deliberately breaking migration or Dart model change turns CI red, with a readable diff.
4. `can-i-deploy` gates the deploy step in GitHub Actions.

### Non-goals
- Contracting OpenAI (third party, can't run verification). It's stubbed instead.
- Supabase Auth (GoTrue) and Storage. These are vendor-owned and low-drift, so they're deferred (see §9).
- Replacing the Playwright E2E suite. Pact covers the contract layer only.

---

## 2. Current state (from the code scan)

| Area | Finding |
|---|---|
| AI path | `ListingProvider.generateListing` → `AiService.generateListing` calls **OpenAI directly from the client**. `generateListingViaEdgeFunction` exists but is not the default. Both swallow errors and return mock data. |
| Edge Function | `supabase/functions/generate-listing/index.ts`. 400 when `productName`/`category` is missing, 500 when OpenAI fails, CORS preflight. Ignores `imageUrls`. OpenAI URL hard-coded. |
| DB access | `AuthService` (profiles select/insert/upsert), `AuthProvider.deductCredits` (profiles PATCH + credit_transactions POST), `ListingProvider` (listings insert/select/update/delete). All via `supabase_flutter ^2.3.0`. |
| Existing "contract" tests | `playwright/tests/api/generate-listing.spec.ts`: live tests are skipped unless `USE_REAL_API=true`, and the `@smoke` tests assert a local mock object against itself. They can't detect drift. |
| Toolchain on dev machine | Node 26, Flutter 3.47. **Supabase CLI, Docker and Deno are not installed**, and provider verification needs all three. CI uses Node 20. |

### Contract defects Pact will expose on day one
These are real and make good evidence for the POC. Fix each one in a commit separate from the
failing pact, so the history shows red → green.

| # | Defect | Where | Expected pact failure |
|---|---|---|---|
| D1 | `profiles` lacks `first_name, last_name, mobile, address, city, state, zip_code, country`. They're only in `database.md`, not in the migrations. | `001_initial_schema.sql` vs `UserProfile.fromJson`, `AuthService.updateProfile` | PostgREST verification: PGRST204 "column not found" on upsert; missing keys on select. |
| D2 | `profiles.email` is nullable in the DB, but Dart reads it as `as String`. | migration vs `user.dart:44` | The Dart model guard fails on a null example. |
| D3 | `listings.platform` defaults to `'shopify'` in the migration and `'general'` in the docs. | migration vs `database.md` | The contract pins the real value; the doc gets fixed. |
| D4 | The client sends `imageUrls`; the Edge Function ignores it. | `ai_service.dart` vs `index.ts` | Documented in the contract; feature gap logged. |
| D5 | Credit deduction is two non-atomic calls. | `auth_provider.dart:195-206` | Both interactions are contracted; an RPC is recommended as a follow-up. |

---

## 3. Architecture

```
┌──────────────────────── pact/ (TypeScript, Jest) ────────────────────────┐
│                                                                          │
│  consumer/*.pact.test.ts                                                 │
│     └─ src/clients/*  ← TS mirror of the Dart call shapes                │
│            │  (Pact mock server)                                         │
│            ▼                                                             │
│     pacts/sellscribe-app-<provider>.json ──publish──► Pact Broker        │
│                                                          │               │
│  provider/*.verify.test.ts  ◄──────────fetch─────────────┘               │
│     ├─ PostgREST  → http://localhost:54321/rest/v1  (supabase start)     │
│     │     state handlers seed via service-role key; RLS exercised        │
│     │     with a real user JWT injected by requestFilter                 │
│     └─ Edge Fn    → supabase functions serve generate-listing            │
│           OPENAI_BASE_URL → provider/stubs/openai-stub.ts                │
└──────────────────────────────────────────────────────────────────────────┘
        ▲                                                ▲
        │ guard 1: Dart fromJson over pact examples      │ guard 2: Playwright wire capture
        │ (test/contract/pact_models_test.dart)          │ compares real Flutter requests to pact
```

### Key decisions

| Decision | Choice | Rationale |
|---|---|---|
| Consumer language | **TypeScript**, mirroring the Dart calls | `pact_dart` is immature and FFI-heavy. Pact-JS (v17.x, PactV4) is the reference implementation, and the team already maintains TS in `playwright/`. Fidelity risk is covered by guards 1 and 2. |
| Runner | **Jest + ts-jest** | Best-documented with Pact-JS. The Playwright runner isn't built around the mock-server lifecycle. |
| Location | New **`pact/`** workspace at repo root | Pact ships native binaries. Keeps `playwright/` lean and lets CI jobs install independently. |
| Node version | **Pin Node 20 LTS** (`.nvmrc`, CI) | Matches the existing CI; avoids unverified native-binding support on Node 26. |
| Provider target | **Local Supabase via CLI (Docker)** | Verifies the actual migrations; no shared remote test account (the Playwright work showed how fragile that is). |
| Broker | **PactFlow free tier** (default); self-hosted `pactfoundation/pact-broker` if hosted is not allowed | Free tier is enough for 2–3 pacticipants and gives `can-i-deploy` out of the box. |
| Versioning | `--app-version=$GITHUB_SHA --branch=$GITHUB_REF_NAME` | Standard for branch-based `can-i-deploy`. |

---

## 4. Repository layout

```
pact/
├── package.json            # @pact-foundation/pact ^17, jest, ts-jest, typescript, dotenv
├── tsconfig.json
├── jest.config.ts          # consumer: parallel; provider: runInBand, testTimeout 60s
├── .nvmrc                  # 20
├── .env.example            # SUPABASE_LOCAL_URL, SUPABASE_SERVICE_ROLE_KEY, PACT_BROKER_BASE_URL, PACT_BROKER_TOKEN
├── src/
│   ├── clients/
│   │   ├── edgeFunctionClient.ts   # ↔ AiService.generateListingViaEdgeFunction
│   │   └── postgrestClient.ts      # ↔ AuthService / AuthProvider / ListingProvider
│   ├── matchers/
│   │   ├── listing.ts              # listing row + AI response matchers
│   │   ├── profile.ts
│   │   └── creditTransaction.ts
│   └── data/fixtures.ts            # fixed UUIDs + seed rows shared by consumer & provider states
├── consumer/
│   ├── generate-listing.pact.test.ts
│   ├── profiles.pact.test.ts
│   ├── listings.pact.test.ts
│   └── credit-transactions.pact.test.ts
├── provider/
│   ├── postgrest.verify.test.ts
│   ├── generate-listing.verify.test.ts
│   ├── states/postgrestStates.ts
│   ├── states/edgeFnStates.ts
│   └── stubs/openai-stub.ts        # /v1/chat/completions + /__control (mode switch)
├── scripts/
│   ├── provider-up.sh              # supabase start → db reset → stub → functions serve
│   ├── provider-down.sh
│   └── wire-check.ts               # guard 2
└── pacts/                          # generated; git-ignored once the broker is live
test/contract/pact_models_test.dart # guard 1 (Flutter)
.github/workflows/contract.yml
```

**Production code changes required (small):**
- `supabase/functions/generate-listing/index.ts`: read `OPENAI_BASE_URL` from env, defaulting to
  `https://api.openai.com`. One line, no behaviour change.
- `supabase/config.toml`: create it via `supabase init` (it doesn't exist yet) so `supabase start` works.
- `supabase/migrations/003_profile_details.sql`: fixes D1 (after the pact proves it).
- `supabase/migrations/004_profile_email_not_null.sql` **or** make `UserProfile.email` nullable: fixes D2.

---

## 5. Contract catalogue

### 5.1 `sellscribe-app` → `sellscribe-generate-listing`

| ID | Provider state | Request | Response |
|---|---|---|---|
| GL-1 | `OpenAI returns a valid listing` | `POST /functions/v1/generate-listing` full payload incl. `imageUrls` | 200 `{title: regex(.{1,70}), description: string, bullets: eachLike(string,1), tags: eachLike(string,1)}` |
| GL-2 | `OpenAI returns a valid listing` | minimal `{productName, category, tone}` | 200, same shape |
| GL-3 | none | missing `productName` | 400 `{error: string}` |
| GL-4 | none | missing `category` | 400 `{error: string}` |
| GL-5 | `OpenAI is unavailable` | full payload | 500 `{error: string}` |

Headers pinned: `Content-Type: application/json`. `Authorization`/`apikey` are matched by regex only.
CORS preflight stays in Playwright, because Pact models OPTIONS poorly.

### 5.2 `sellscribe-app` → `sellscribe-postgrest`

The requests must match what `supabase_flutter` actually puts on the wire. Guard 2 checks this.

| ID | Dart origin | Provider state | Request (essentials) | Response |
|---|---|---|---|---|
| PR-1 | `getCurrentProfile` (found) | `user U1 has a profile with 5 credits` | `GET /rest/v1/profiles?select=*&id=eq.U1`, `Accept: application/vnd.pgrst.object+json` | 200 profile object (all `UserProfile.fromJson` keys) |
| PR-2 | `getCurrentProfile` (maybeSingle, none) | `user U1 has no profile` | same, maybeSingle form | empty result as the SDK expects |
| PR-3 | `_createProfile` | `user U1 has no profile` | `POST /rest/v1/profiles` | 201 |
| PR-4 | `updateProfile` (upsert) | `user U1 has a profile with 5 credits` | `POST /rest/v1/profiles?on_conflict=id`, `Prefer: resolution=merge-duplicates` | 201/200 |
| PR-5 | `deductCredits` step 1 | `user U1 has a profile with 5 credits` | `PATCH /rest/v1/profiles?id=eq.U1` `{credits_remaining:int, updated_at}` | 204 |
| PR-6 | `deductCredits` step 2 | `user U1 has a profile with 5 credits` | `POST /rest/v1/credit_transactions` `{amount:-1, transaction_type:'used'}` | 201 |
| PR-7 | `_saveListing` | `user U1 has a profile with 5 credits` | `POST /rest/v1/listings?select=*`, `Prefer: return=representation`, object Accept | 201 listing row |
| PR-8 | `loadHistory` | `user U1 has 2 listings` | `GET /rest/v1/listings?select=*&user_id=eq.U1&order=created_at.desc` | 200 `eachLike(listing, 2)` |
| PR-9 | `getListingById` | `listing L1 exists for user U1` | `GET /rest/v1/listings?select=*&id=eq.L1` (single) | 200 listing row |
| PR-10 | `updateListing` | `listing L1 exists for user U1` | `PATCH /rest/v1/listings?id=eq.L1&select=*` | 200 listing row |
| PR-11 | `deleteListing` | `listing L1 exists for user U1` | `DELETE /rest/v1/listings?id=eq.L1` | 204 |
| PR-12 | RLS negative | `listing L2 exists for user U2` | `GET …listings?id=eq.L2` as U1 | 406/empty (documents isolation) |

Matching rules:
- UUIDs and timestamps: `uuid()` / `timestamp()` matchers.
- `transaction_type`: `regex('^(used|purchased|bonus|refund)$')`, mirroring the CHECK constraint.
- Every key read by `fromJson` is present in the response matchers. This is what makes D1/D2 fail.

---

## 6. Milestones

Each milestone ends with a mergeable PR and passing CI.

### M0 — Prerequisites (0.5 d)
- [ ] Install Docker Desktop, Supabase CLI (`brew install supabase/tap/supabase`) and Deno.
- [ ] `supabase init` (creates `supabase/config.toml`) → `supabase start` → `supabase db reset` applies 001/002 cleanly.
- [ ] Add `.nvmrc` = 20 at the repo root.
- [ ] Decide on the broker (§10, Q1).
- **Done when:** `supabase status` shows API, DB and Studio running locally, and the migrations apply.

### M1 — Scaffold `pact/` (0.5 d)
- [ ] package.json, tsconfig, jest config, `.env.example`, `.gitignore`.
- [ ] `src/data/fixtures.ts`: fixed `U1`, `U2`, `L1`, `L2` UUIDs; reuse `validListingPayload` and `mockListingResponse` from `playwright/utils/test-data.ts`. Import them, don't copy.
- [ ] npm scripts: `test:consumer`, `test:provider`, `pact:publish`, `pact:can-i-deploy`.
- **Done when:** an empty Jest run passes in CI on Node 20.

### M2 — Edge Function consumer contracts (0.5 d)
- [ ] `edgeFunctionClient.ts` replicating `functions.invoke` (method, path, headers, body incl. `imageUrls`).
- [ ] GL-1 … GL-5.
- **Done when:** `pacts/sellscribe-app-sellscribe-generate-listing.json` is generated and reviewed.

### M3 — PostgREST consumer contracts (1.5 d)
- [ ] Capture real request shapes first: run the existing Playwright login/home flow with
      `page.on('request')` filtered to `/rest/v1/`, and save them as reference fixtures.
- [ ] `postgrestClient.ts` reproduces those shapes exactly (query string, `Prefer`, `Accept`).
- [ ] Matchers for profile, listing and credit transaction.
- [ ] PR-1 … PR-12.
- **Done when:** the PostgREST pact is generated and every interaction maps to a named Dart method (table in §5.2).

### M4 — Provider verification (1.5 d)
- [ ] `openai-stub.ts` with modes `ok | http500 | nonJson`, switched via `POST /__control`.
- [ ] Edge Function: add `OPENAI_BASE_URL`; `provider-up.sh` serves the function with the stub URL.
- [ ] PostgREST state handlers (service-role key):
      create auth user `U1`/`U2` with fixed IDs (`auth.admin.createUser`), seed or clean rows.
- [ ] `requestFilter`: replace the pact's placeholder bearer with a JWT signed for the state's user,
      so **RLS is exercised, not bypassed**.
- [ ] First run: **expect red on D1/D2.** Commit that failing run's report as evidence.
- [ ] Land the `003`/`004` migrations (or the Dart nullable fix) → green.
- **Done when:** both verifications pass from a clean `supabase db reset`.

### M5 — Fidelity guards (0.5 d)
- [ ] **Guard 1:** `test/contract/pact_models_test.dart` loads the pact JSON, reifies each response
      example, and runs it through `UserProfile.fromJson`, `ProductListing.fromJson` and
      `CreditTransaction.fromJson`. Runs under `flutter test`.
- [ ] **Guard 2:** a Playwright fixture records `/rest/v1/*` and `/functions/v1/*` requests during
      the logged-in smoke run into `test-results/wire.json`. `pact/scripts/wire-check.ts` asserts
      each one matches a pact interaction (method, path, query keys, `Prefer`, `Accept`).
- **Done when:** changing a Dart model key or upgrading `supabase_flutter` in a way that changes the wire
  format fails one of the guards.

### M6 — Broker + CI (1 d)
- [ ] `.github/workflows/contract.yml`:
  ```
  consumer   (ubuntu, node 20)         → test:consumer → pact:publish
  guard-dart (flutter)                 → flutter test test/contract
  provider   (ubuntu, docker, supabase)→ provider-up → test:provider (publish results) → provider-down
  can-i-deploy                         → needs: [consumer, provider]; gates deploy
  ```
- [ ] Path filters: run the consumer on `lib/services/**`, `lib/providers/**` and `lib/models/**`
      changes; run the provider on `supabase/migrations/**` and `supabase/functions/**` changes.
- [ ] Broker webhook: a new pact version triggers provider verification.
- [ ] Add `--pact` to `scripts/run-all-tests.sh`.
- [ ] Docs: a "Contract" layer in `TESTING_PORTFOLIO.md` (pyramid + table), a "Contract tests"
      section in `README.md`.
- **Done when:** a PR that adds a breaking migration is blocked by `can-i-deploy`.

### M7 — Retire overlap (0.25 d)
- [ ] In `playwright/tests/api/generate-listing.spec.ts`, remove the self-asserting schema tests
      ("mocked response has correct schema shape", "each bullet…", "all tone values…").
- [ ] Keep the CORS preflight test and one opt-in live smoke.
- [ ] Point `page.route()` mocks at pact-generated examples, so UI mocks can't drift from the contract.

---

## 7. Schedule

| Day | Milestones |
|---|---|
| 1 | M0, M1, M2 |
| 2 | M3 (capture + client) |
| 3 | M3 (interactions), start M4 |
| 4 | M4 (states, JWT filter, red → green) |
| 5 | M5, M6 |
| 6 | M6 (webhook, docs), M7, buffer |

---

## 8. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| The TS mirror drifts from the real Dart requests | False confidence | Guard 2 (wire capture) runs on every E2E smoke; review the mirror whenever `supabase_flutter` is bumped. |
| PostgREST/SDK header details (`Prefer`, `Accept`) differ by SDK version | Flaky or over-strict pacts | Capture real requests first (M3), match only the headers that change semantics. |
| Docker/Supabase CLI unavailable in some CI runners | Provider job can't run | Use `ubuntu-latest` (Docker preinstalled) + `supabase/setup-cli` action; cache images. |
| Node 26 locally vs Node 20 in CI | Native binding mismatches | `.nvmrc` + `engines` field; run locally via `nvm use`. |
| RLS hides rows and causes confusing verification failures | Slow debugging | Provider states log the seeded IDs; PR-12 makes the RLS behaviour explicit. |
| Production app still calls OpenAI directly | The GL contract protects a path users don't hit | Track as Q2; contract stays valuable once the app switches to the Edge Function. |
| Broker is a new external dependency | Secrets/ops overhead | Start with local pact files (M1–M5); add the broker only in M6. |

---

## 9. Backlog (after the POC)
- GoTrue contracts (`/auth/v1/token`, `/auth/v1/signup`) verified against local Supabase.
- Bi-directional contract testing for OpenAI using its published OpenAPI spec (PactFlow BDCT).
- Replace the two-call credit deduction with an RPC (`deduct_credit()`) and contract it.
- Contracts for the Appium/mobile build if it ever diverges from the web client.

---

## 10. Open decisions

| # | Question | Default if no answer |
|---|---|---|
| Q1 | PactFlow hosted or self-hosted broker? | PactFlow free tier |
| Q2 | Switch the app's default AI path to the Edge Function (removes the OpenAI key from the client bundle)? | Yes, as a separate PR after M4 |
| Q3 | Fix D1/D2 in this work or only demonstrate them? | Fix, in separate commits after the red run |
| Q4 | D2 fix direction: `email NOT NULL` in the DB, or nullable in Dart? | `NOT NULL` (the auth trigger always sets it) |

---

## 11. Definition of done
- [ ] Both pacts generated offline; both verified against a clean local Supabase.
- [ ] D1/D2 shown failing, then fixed, with the commits linked from the PR.
- [ ] Both guards in place and proven to catch an injected break.
- [ ] `contract.yml` green on `main`; `can-i-deploy` blocks a known-bad change.
- [ ] README, `TESTING_PORTFOLIO.md` and `scripts/run-all-tests.sh` updated.
