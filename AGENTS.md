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
| `AppTextField` | `semanticsLabel: 'field-name-input'` |
| `AppButton` | `semanticsLabel: 'action-verb-button'` |
| `ListTile`, `GestureDetector`, other tappables | `Semantics(label: 'noun-role', button: true, child: ...)` |
| `IconButton` (e.g., AppBar back) | `tooltip: 'Back'` |
| `PopupMenuButton` | `tooltip: 'menu-name'` |

### ID naming rules

- **Format**: `kebab-case`
- **Suffix the role**: `-input`, `-button`, `-link`, `-tile`, `-menu`
- **Be specific**: `email-input` not `field1`; `sign-in-button` not `btn`
- **Screen-scope uniqueness**: an ID must be unique within the screen it lives on

### Using IDs in mobile page objects (Appium / Python)

Declare as a class constant and locate via `ACCESSIBILITY_ID` — which maps directly to the
Flutter `Semantics(label:)` / `tooltip:` value on Android.

```python
# constants
EMAIL_FIELD_ID = "email-input"
SIGN_IN_BUTTON_ID = "sign-in-button"

# finding elements
self.find_by_accessibility_id(self.EMAIL_FIELD_ID)          # tappable elements
self.find_by_accessibility_id(self.EMAIL_FIELD_ID).click()  # then type via active element
active = self.driver.switch_to.active_element
active.clear()
active.send_keys(value)
```

**Never use** `//android.widget.EditText[@hint='...']`, `tap_by_text()`, or index-based XPath
for elements that have a semantic ID.

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

1. Set the semantic label in the Flutter widget (`semanticsLabel`, `Semantics(label:)`, or `tooltip`).
2. Add a `_ID` constant to the relevant Appium page object and use `find_by_accessibility_id()`.
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
