# Input autofill & password-manager spec

> Closes audit item **KIT-35-05** (no autofill / password-manager affordance spec — no
> `autoComplete` / `textContentType` mapping per field type). Companion to
> `keyboard-focus-order.md`.

Every `MxTextField` must declare the correct **autofill hints** so the browser/OS keyboard bar,
Android Autofill Framework, and third-party password managers can offer the
right value. Missing/incorrect hints break password-manager save+fill and force manual
typing. Additive documentation only: this sets props on the existing `MxTextField` — no
token/class/name changes, no rendered-pixel change (autofill hints are non-visual props).

Owner: Design System team · Status: Current (v4, additive-only).

---

## 1. Rules

- **Every field carries a semantic hint.** Flutter `AutofillHints` is the production contract;
  on Web it maps to the HTML `autocomplete` attribute. A field with no meaningful hint
  (search box, one-off) sets autofill off
  explicitly — silence is a defect, not "off".
- **Match the keyboard + capitalization to the field** (`TextInputType`,
  `textCapitalization`, `autocorrect`) so autofill and manual entry agree.
- **`obscureText` for every credential** (current + new password); pair with the
  password hints so managers offer save/fill and the strong-password generator.
- **New vs. current password:** use `new-password` on create/confirm fields (invites the
  generator) and `password` on sign-in (invites fill). Never both `newPassword` and
  `password` on the same field.
- **One-time codes:** `AutofillHints.oneTimeCode` / `autocomplete="one-time-code"` lets the
  platform surface the code; use `TextInputType.number`.

## 2. Field-type → hint mapping

| Field type | Flutter `AutofillHints` | Web `autocomplete` | `TextInputType` | Other contract |
| --- | --- | --- | --- | --- |
| Email | `AutofillHints.email` | `email` | `emailAddress` | capitalization none; autocorrect false |
| Username | `AutofillHints.username` | `username` | `text` | capitalization none |
| Current password (sign-in) | `AutofillHints.password` | `current-password` | `visiblePassword` | `obscureText: true` |
| New password (create/confirm) | `AutofillHints.newPassword` | `new-password` | `visiblePassword` | `obscureText: true` |
| One-time code (OTP/2FA) | `AutofillHints.oneTimeCode` | `one-time-code` | `number` | — |
| Person name (full) | `AutofillHints.name` | `name` | `name` | capitalization words |
| Given / family name | `givenName` / `familyName` | `given-name` / `family-name` | `name` | capitalization words |
| Phone number | `AutofillHints.telephoneNumber` | `tel` | `phone` | — |
| Street address | `AutofillHints.fullStreetAddress` | `street-address` | `streetAddress` | capitalization words |
| Postal code | `AutofillHints.postalCode` | `postal-code` | `number` | — |
| One-time / search / free text | none | `off` | as suited | opt out explicitly |

> The kit's placeholder screens are content-only (no real auth), so no fixture currently
> renders a credential field; this spec is the contract the moment auth/profile fields
> land. Verify the mapping against the Flutter framework and target-browser support before
> wiring, because browser autofill behaviour can vary.

## 3. Interaction with focus order

- Autofill does not change tab/focus order (`keyboard-focus-order.md`). A password manager
  filling multiple fields must not move focus unexpectedly; after an autofill the focus
  stays on the field the user is on, and the submit CTA remains the last stop.
- The OS autofill accessory sits above the keyboard and over `--memox-safe-area-bottom`;
  it must not occlude the focused field — keep the standard keyboard-avoidance behaviour.
