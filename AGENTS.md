# SellScribe — Agent Instructions

Agents working on this codebase must follow these rules in addition to any in `CLAUDE.md`.

---

## Semantic Element Identifiers

Every interactive widget **must** have a unique, meaningful semantic ID declared in the Flutter
source. Tests locate elements exclusively via these IDs — never by XPath hierarchy, DOM position,
display text, or hint strings.

### Setting IDs in Flutter

| Widget type | How to set the ID |
|---|---|
| `AppTextField` | `semanticsLabel: 'field-name-input'` (sets label **and** identifier) |
| `AppButton` | `semanticsLabel: 'action-verb-button'` (sets label **and** identifier) |
| `ListTile`, `GestureDetector`, other tappables | `Semantics(identifier: 'noun-role', child: ...)` |
| Text the tests read (e.g. a credits count) | `Semantics(identifier: 'noun', child: Text(...))` |
| `IconButton` (e.g., AppBar back) | `tooltip: 'Back'` |
| `PopupMenuButton` | `tooltip: 'menu-name'` |

**`identifier` is the test ID.** On Android it becomes the element's `resource-id` and on iOS
its accessibility identifier, which is what the Appium tests look up. It is invisible to users and
screen readers. Older IDs were set as `Semantics(label: 'id', identifier: 'id')`, and they keep the
label because the Playwright suite selects on `aria-label`. New IDs need only `identifier`.

Labels alone don't work on Android: a text field's label lands in its `hint`, and a tappable's
label is merged with its children's text (`create-listing-button\nCreate Listing\n…`), so neither
matches an exact accessibility-id lookup.

### ID naming rules

- **Format**: `kebab-case`
- **Suffix the role**: `-input`, `-button`, `-link`, `-tile`, `-menu`
- **Be specific**: `email-input` not `field1`; `sign-in-button` not `btn`
- **Screen-scope uniqueness**: an ID must be unique within the screen it lives on

### Using IDs in mobile page objects (Appium / Python)

Declare IDs as class constants and locate them with the `BasePage` helpers:
`by_id()` for semantic IDs (Flutter `identifier`), `by_tooltip()` for IconButton tooltips.

```python
# constants
EMAIL_INPUT_ID = "email-input"
SIGN_IN_BUTTON_ID = "sign-in-button"
PROFILE_MENU_TOOLTIP = "profile-menu"

# finding elements
self.tap(self.by_id(self.SIGN_IN_BUTTON_ID))          # tappables
self.type_into(self.EMAIL_INPUT_ID, value)            # fields: tap, then type into the active element
self.read_text("credits-count")                       # text of an element by ID
self.tap(self.by_tooltip(self.PROFILE_MENU_TOOLTIP))  # IconButton / PopupMenuButton tooltips
self.tap_back()                                       # AppBar back button (tooltip 'Back')
self.is_present(self.by_id(self.SIGN_IN_BUTTON_ID))   # screen checks use an ID unique to the screen
```

`by_id()` matches the Android resource-id exactly with `UiSelector().resourceId(...)`. Appium's
plain `AppiumBy.ID` doesn't work: it prefixes the app package (`com.sellscribe.app:id/...`),
which Flutter's resource-ids don't have.

**Never use** XPath, visible text (`tap_by_text()`, `contains(@text, ...)`), class names or
element positions. If a test needs an element that has no ID, add one in the Flutter source.

### Using IDs in web page objects (Playwright / TypeScript)

```typescript
// constants — Flutter exposes the label as aria-label on flt-semantics nodes
readonly EMAIL_FIELD = "flt-semantics[aria-label='email-input']";
readonly SIGN_IN_BUTTON = "flt-semantics[role='button'][aria-label='sign-in-button']";

// usage
await this.click(this.SIGN_IN_BUTTON);
await this.isVisible(this.EMAIL_FIELD);
```

---

## Checklist — adding a new screen or interactive widget

1. Set the ID in the Flutter widget (`semanticsLabel`, `Semantics(identifier:)`, or `tooltip`).
2. Add a `_ID` constant to the relevant Appium page object and locate it with `by_id()` (or `by_tooltip()`).
3. Add a matching `readonly` selector to the Playwright page object.
4. Run the smoke suite against both platforms to confirm the IDs resolve correctly.
5. Never leave an interactive element without a semantic ID if it has a corresponding test.

---

## Existing semantic IDs (source of truth)

| Screen | Widget | Semantic ID |
|---|---|---|
| Login | Email field | `email-input` |
| Login | Password field | `password-input` |
| Login | Sign In button | `sign-in-button` |
| Login | Sign Up link | `sign-up-link` |
| Register | Name field | `name-input` |
| Register | Email field | `email-input` |
| Register | Password field | `password-create-input` |
| Register | Confirm password field | `password-confirm-input` |
| Register | Create Account button | `create-account-button` |
| Register | Sign In link | `sign-in-link` |
| Home | Create Listing card | `create-listing-button` |
| Home | View History card | `view-history-button` |
| Home | Create First Listing (empty state) | `create-first-listing-button` |
| Home | Profile menu (PopupMenuButton) | `profile-menu` |
| Settings | AppBar back button | `Back` (via `tooltip: 'Back'`) |
| Settings | Edit Profile tile | `edit-profile-tile` |
| Settings | Theme tile | `theme-button` |
| Settings | Payment Methods tile | `payment-methods-tile` |
| Settings | Purchase Credits tile | `purchase-credits-tile` |
| Settings | Sign Out tile | `sign-out-button` |
| Login | Forgot password button | `forgot-password-button` |
| Home | Credits count (text) | `credits-count` |
| Home | Profile menu → Settings item | `settings-menu-item` |
| Home | Profile menu → Sign out item | `sign-out-menu-item` |
| Settings | Theme sheet options | `theme-light-option`, `theme-dark-option`, `theme-system-option` |
| Settings | Sign-out dialog buttons | `confirm-sign-out-button`, `cancel-sign-out-button` |
| Profile Edit | Fields | `first-name-input`, `last-name-input`, `mobile-input`, `address-input`, `city-input`, `state-input`, `zip-code-input`, `country-input` |
| Profile Edit | Save button | `save-profile-button` |
| Payment Methods | Add Card button | `add-card-button` |
| Payment Methods | Add card sheet | `card-number-input`, `card-expiry-input`, `card-cvv-input`, `cardholder-name-input`, `save-card-button` |
| Purchase Credits | Current balance (text) | `current-credits` |
| Purchase Credits | Package cards | `credit-package-10`, `credit-package-25`, `credit-package-50`, `credit-package-100` |
| Purchase Credits | Purchase button | `purchase-button` |
| Upload | Upload area / Continue / Skip | `upload-images-button`, `continue-button`, `skip-upload-button` |
| Details | Fields | `product-name-input`, `key-features-input`, `target-audience-input` |
| Details | Buttons | `generate-listing-button`, `details-back-button` |
| History | New Listing button | `new-listing-button` |
| History | Listing card / its actions | `listing-card`, `listing-view-button`, `listing-edit-button`, `listing-delete-button` |
| History | Delete dialog buttons | `confirm-delete-listing-button`, `cancel-delete-listing-button` |
| History | Create First Listing (empty state) | `create-first-listing-button` |
| All sub-screens | AppBar back button | `Back` (via `tooltip: 'Back'`) |

---

## Test execution

```bash
# All suites (web + API + mobile) — runs in background, logs to scripts/logs/
./scripts/run-all-tests.sh

# Web + API only (TypeScript Playwright)
cd playwright && npx playwright test

# Mobile only (Appium)
cd test_mobile && ./appium_scripts/launch_and_test.sh

# Smoke suite only
cd playwright && npx playwright test --grep @smoke
```
