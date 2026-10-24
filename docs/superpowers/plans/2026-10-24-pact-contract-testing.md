# Pact Contract Testing — Implementation Plan

**Goal:** Add consumer-driven contract tests (Pact) to the SellScribe POC, covering the HTTP
contracts between the Flutter client (consumer) and its two backends (providers): the
`generate-listing` Edge Function and Supabase PostgREST (`profiles`, `listings`,
`credit_transactions`). This fills the gap between today's fully-mocked `page.route()` tests and
slow, flaky full-stack E2E.

**Architecture:** New top-level `pact/` workspace (TypeScript, Jest, `@pact-foundation/pact` PactV4
API). Consumer tests model the requests the Dart code actually sends; provider verification runs
against a local Supabase stack (`supabase start`) with OpenAI stubbed. Pact files are stored locally
first, then published to a broker with `can-i-deploy` gating in CI.

**Tech stack:** `@pact-foundation/pact` (latest, PactV4), Jest + ts-jest, TypeScript 5, Supabase CLI
(Docker), GitHub Actions. Optional later: PactFlow / self-hosted Pact Broker.

---

## 1. What exists today (findings from the code scan)

| Area | State |
|---|---|
| App | Flutter (web + Android), Provider state, GoRouter. Talks to Supabase via `supabase_flutter ^2.3.0`. |
| AI generation | `ListingProvider.generateListing` → `AiService.generateListing` calls **OpenAI directly** from the client; the Edge Function path (`generateListingViaEdgeFunction`) exists but is not the default. Both fall back to a mock on any error. |
| Edge Function | `supabase/functions/generate-listing` (Deno). 400 if `productName`/`category` missing, 500 on OpenAI failure, CORS preflight. Ignores `imageUrls`. OpenAI URL is hard-coded. |
| DB | `profiles`, `listings`, `credit_transactions` with RLS (`auth.uid()` ownership). Profile auto-created by trigger with 5 credits. |
| `playwright/` | TS Playwright: POM + fixtures, UI tests for auth/home/settings/listing, and `tests/api/generate-listing.spec.ts`. The "API contract" tests only run with `USE_REAL_API=true` (they hit a live function → real OpenAI cost), and the `@smoke` "contract" tests assert against a local mock object — they can't detect drift between client and server. |
| `test_web/` (pytest), `test_mobile/` (Appium) | UI-level only; no API contract coverage. |
| CI | `.github/workflows/playwright.yml` (chromium/firefox matrix). No contract stage. |

### Contract bugs Pact would surface immediately

These are real mismatches found during the scan — good demo material for the POC:

1. **Schema drift — profile columns missing from migrations.** `UserProfile.fromJson` and
   `AuthService.updateProfile` read/write `first_name, last_name, mobile, address, city, state,
   zip_code, country`. `001_initial_schema.sql` doesn't create them (only `database.md` does). A
   fresh `supabase db reset` → `PATCH/upsert /profiles` fails with PGRST204 "column not found".
2. **Nullability mismatch.** `profiles.email` is nullable in the migration, but Dart casts
   `json['email'] as String` → runtime crash on a null email.
3. **Default drift.** `listings.platform` defaults to `'shopify'` in the migration, `'general'` in
   `database.md`, and the Dart model sends its own value — the contract pins which one is true.
4. **Unused request field.** The client sends `imageUrls` to the Edge Function; the provider
   ignores it (the vision path only exists in the direct-OpenAI client code).
5. **Non-atomic credit deduction.** `deductCredits` does `PATCH profiles` + `POST
   credit_transactions` as two calls; contract tests document both, and flag the case for an RPC.

---

## 2. Scope

| # | Consumer → Provider | Interactions | Priority |
|---|---|---|---|
| C1 | `sellscribe-app` → `sellscribe-generate-listing` (Edge Fn) | POST valid → 200 listing; POST minimal → 200; missing `productName` → 400; missing `category` → 400; upstream AI failure → 500 | **P0** |
| C2 | `sellscribe-app` → `sellscribe-postgrest` | `GET /profiles?id=eq.{id}` (single + maybeSingle/empty); `POST /profiles` upsert (`on_conflict=id`); `PATCH /profiles` credits; `POST /listings` (return=representation, single); `GET /listings?user_id=eq.{id}&order=created_at.desc`; `GET /listings?id=eq.{id}`; `PATCH /listings`; `DELETE /listings`; `POST /credit_transactions` | **P0** |
| C3 | `sellscribe-app` → `supabase-gotrue` | `POST /auth/v1/token?grant_type=password`, `POST /auth/v1/signup` | P2 (vendor-owned, optional) |
| — | Edge Fn → OpenAI | **Out of scope for Pact** (third party, can't run provider verification). Use a stub during verification; optionally bi-directional contract testing against OpenAI's OpenAPI spec later. |
| — | Storage uploads | Out of scope (binary, vendor-owned); covered by E2E. |

**Why consumer tests in TypeScript, not Dart:** the Dart Pact binding (`pact_dart`) is immature and
would need FFI setup on every CI runner. The POC writes consumer tests in TS that mirror the Dart
client's requests one-to-one, and closes the fidelity gap with two guards (section 5).

---

## 3. File map

```
pact/
├── package.json              # jest, ts-jest, @pact-foundation/pact, dotenv
├── tsconfig.json
├── jest.config.ts            # testTimeout 30s, runInBand for provider tests
├── .env.example              # SUPABASE_LOCAL_URL, SERVICE_ROLE_KEY, PACT_BROKER_*
├── src/
│   ├── clients/              # thin TS clients mirroring the Dart call shapes
│   │   ├── edgeFunctionClient.ts     # ↔ AiService.generateListingViaEdgeFunction
│   │   └── postgrestClient.ts        # ↔ AuthService / ListingProvider / AuthProvider
│   ├── matchers/
│   │   ├── listing.ts        # like()/eachLike()/regex() for listing rows + AI response
│   │   └── profile.ts
│   └── data/                 # fixed UUIDs + seed rows shared by consumer & provider states
│       └── fixtures.ts
├── consumer/
│   ├── generate-listing.pact.test.ts
│   ├── profiles.pact.test.ts
│   ├── listings.pact.test.ts
│   └── credit-transactions.pact.test.ts
├── provider/
│   ├── generate-listing.verify.test.ts   # against `supabase functions serve`
│   ├── postgrest.verify.test.ts          # against local PostgREST :54321/rest/v1
│   ├── states/
│   │   ├── postgrestStates.ts            # seed/cleanup via service-role key
│   │   └── edgeFnStates.ts               # toggles OpenAI stub behaviour
│   └── stubs/openai-stub.ts              # tiny HTTP server: /v1/chat/completions + /__control
├── pacts/                    # generated pact JSON (git-ignored once the broker is in)
└── scripts/
    ├── run-consumer.sh
    ├── run-provider.sh       # supabase start → db reset → serve fn → verify
    └── publish.sh            # pact-broker publish + can-i-deploy
test/contract/
└── pact_models_test.dart     # Dart guard: feeds pact response bodies into fromJson()
```

Small production changes required:
- `supabase/functions/generate-listing/index.ts`: read `OPENAI_BASE_URL` from env (default
  `https://api.openai.com`) so verification can point at the stub. One line, no behaviour change.
- `supabase/migrations/003_profile_details.sql`: add the missing profile columns (fixes finding 1
  *after* the pact has demonstrated the failure — keep the red→green commit pair as evidence).

---

## 4. Phases

### Phase 1 — Scaffold (½ day)
- [ ] Create `pact/` with package.json, tsconfig, jest config, `.env.example`, `.gitignore`.
- [ ] Shared fixtures: fixed `USER_ID`, `LISTING_ID`, seed rows; mirrors `playwright/utils/test-data.ts`
      (`validListingPayload`, `mockListingResponse`) — import, don't duplicate.
- [ ] `npm run test:consumer`, `test:provider`, `pact:publish` scripts.

### Phase 2 — Consumer contracts: Edge Function (C1) (½ day)
- [ ] `edgeFunctionClient.ts` sends exactly what `supabase_flutter`'s `functions.invoke` sends:
      `POST /functions/v1/generate-listing`, headers `Authorization: Bearer …`, `apikey`,
      `Content-Type: application/json`, body including `imageUrls`.
- [ ] Interactions with provider states:
      `"OpenAI returns a valid listing"` → 200, body
      `{title: string(≤70 via regex), description: string, bullets: eachLike(string, min 1), tags: eachLike(string, min 1)}`;
      `"no precondition"` → 400 `{error: string}` ×2;
      `"OpenAI is unavailable"` → 500 `{error: string}`.
- [ ] Use type matchers, not exact AI text — the contract is the shape, not the copy.

### Phase 3 — Consumer contracts: PostgREST (C2) (1–1½ days)
- [ ] `postgrestClient.ts` reproduces supabase-dart's wire format per call:
      - `.select().eq('id', x).single()` → `GET /rest/v1/profiles?select=*&id=eq.{x}`,
        `Accept: application/vnd.pgrst.object+json`
      - `.maybeSingle()` → same with empty result → 200 `[]`/406 handling as the SDK expects
      - `.insert(...).select().single()` → `POST` with `Prefer: return=representation`
      - `.upsert(..., onConflict: 'id')` → `POST ?on_conflict=id`,
        `Prefer: resolution=merge-duplicates,return=…`
      - `.order('created_at', ascending: false)` → `order=created_at.desc`
- [ ] Interactions keyed by provider states:
      `"user {id} exists with 5 credits"`, `"user {id} has no profile row"`,
      `"user {id} has 2 listings"`, `"listing {id} exists for user {id}"`.
- [ ] Response matchers cover every key read by `UserProfile.fromJson`,
      `ProductListing.fromJson`, `CreditTransaction.fromJson` — including the 8 profile detail
      columns (this is what makes finding 1 fail at verification).
- [ ] `transaction_type` matched with `regex('^(used|purchased|bonus|refund)$')` to mirror the
      CHECK constraint.

### Phase 4 — Provider verification (1–1½ days)
- [ ] `run-provider.sh`: `supabase start` → `supabase db reset` (applies migrations) →
      start `openai-stub` → `supabase functions serve generate-listing --env-file …` with
      `OPENAI_BASE_URL=http://host.docker.internal:<stubPort>`.
- [ ] **PostgREST verifier**: `providerBaseUrl = http://localhost:54321/rest/v1`.
      State handlers use the **service-role** key to seed/clean rows and create the auth user
      (`auth.admin.createUser` with the fixed `USER_ID`). `requestFilter` swaps the pact's
      placeholder `Authorization` for a real JWT minted for that user, so **RLS is exercised**,
      not bypassed.
- [ ] **Edge Fn verifier**: state handlers call the stub's `/__control` to switch between
      "valid JSON completion", "HTTP 500" and "non-JSON content".
- [ ] Expect the first run to go red on findings 1–2; land `003_profile_details.sql`
      (+ `email NOT NULL` or a nullable Dart field) to turn it green.

### Phase 5 — Fidelity guards (½ day)
These keep the TS consumer tests honest about what the Dart client really does:
- [ ] **Dart model guard** — `test/contract/pact_models_test.dart`: loads `pact/pacts/*.json`,
      reifies each response example, runs it through `UserProfile.fromJson` /
      `ProductListing.fromJson` / `CreditTransaction.fromJson`. Fails if the contract promises a
      shape the real Dart parser can't consume. Runs with plain `flutter test`.
- [ ] **Wire-capture check** — reuse the existing Playwright E2E: a fixture listens to
      `page.on('request')` for `*/rest/v1/*` and `*/functions/v1/*` during a logged-in run,
      dumps method/path/query/headers to `playwright/test-results/wire.json`; a small script
      asserts each captured request matches an interaction in the pact (path + query keys +
      Prefer/Accept headers). Catches SDK upgrades that change wire format.

### Phase 6 — Broker + CI (1 day)
- [ ] Broker: PactFlow free tier or `pactfoundation/pact-broker` via docker-compose (POC: either).
- [ ] Publish with `--consumer-app-version=$GITHUB_SHA --branch=$GITHUB_REF_NAME`.
- [ ] New workflow `.github/workflows/contract.yml`:
      job `consumer` (fast, no Docker) → publish;
      job `provider` (needs Docker for `supabase start`) → verify from broker, publish results;
      job `can-i-deploy` before any deploy step.
- [ ] Trigger provider verification when `supabase/migrations/**` or `supabase/functions/**`
      change; trigger consumer job when `lib/services/**`, `lib/providers/**`, `lib/models/**` change.
- [ ] Add `--pact` to `scripts/run-all-tests.sh`; add a "Contract" row to `TESTING_PORTFOLIO.md`
      and the pyramid diagram.

### Phase 7 — Clean up overlap in `playwright/tests/api/`
- [ ] Keep the CORS preflight test (Pact doesn't model OPTIONS well) and one real-API smoke.
- [ ] Remove/retire the self-asserting "mocked response has correct schema shape" tests — the
      contract now owns schema; point `page.route()` mocks at pact-generated examples so UI mocks
      can't drift from the contract either.

---

## 5. Decisions & trade-offs

| Decision | Choice | Why |
|---|---|---|
| Consumer language | TypeScript (mirroring Dart) | Mature Pact-JS, same stack as `playwright/`; guarded by Dart model test + wire capture. |
| Test runner | Jest | Most Pact-JS docs/examples; Playwright runner isn't built for Pact's mock-server lifecycle. |
| Separate `pact/` workspace | Yes | Pact ships native binaries; keeps `playwright/` install lean and CI jobs independent. |
| PostgREST as a "provider" | Yes, verified against real local Supabase | The DB schema *is* the API; this is where the actual drift bugs live. |
| GoTrue / Storage | Deferred | Vendor-owned; low drift risk vs. effort. |
| OpenAI | Stubbed, not contracted | Can't verify a third party; Edge Fn owns the translation. |

## 6. Open questions for you
1. Broker: PactFlow (hosted, free tier) or self-hosted Docker broker?
2. Should the app switch its default AI path to the Edge Function? Today the client calls OpenAI
   directly (API key in the client bundle) — the C1 contract protects a path users don't hit yet.
3. Fix findings 1–2 in this work, or only demonstrate them failing?

## 7. Done criteria
- `cd pact && npm run test:consumer` generates pacts for both providers (no network, < 30 s).
- `./pact/scripts/run-provider.sh` verifies both pacts green against a fresh `supabase db reset`.
- `flutter test test/contract` passes against the generated pacts.
- CI runs consumer → publish → provider verify → `can-i-deploy`, with the report linked in the job summary.

**Estimated effort:** ~5–6 days for one engineer.
