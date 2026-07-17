# Input autofill & password-manager spec

> Closes audit item **KIT-35-05** (no autofill / password-manager affordance spec — no
> `autoComplete` / `textContentType` mapping per field type). Companion to
> `keyboard-focus-order.md`.

Every `MxTextField` must declare the correct **autofill hints** so the OS keyboard bar,
iOS AutoFill, Android Autofill Framework, and third-party password managers can offer the
right value. Missing/incorrect hints break password-manager save+fill and force manual
typing. Additive documentation only: this sets props on the existing `MxTextField` — no
token/class/name changes, no rendered-pixel change (autofill hints are non-visual props).

Owner: Design System team · Status: Current (v4, additive-only).

---

## 1. Rules

- **Every field carries both hints.** Set React Native `autoComplete` (cross-platform hint)
  **and** iOS `textContentType`; on web/RN-web the hint maps to the HTML `autocomplete`
  attribute. A field with no meaningful hint (search box, one-off) sets `autoComplete="off"`
  explicitly — silence is a defect, not "off".
- **Match the keyboard + capitalization to the field** (`keyboardType`,
  `autoCapitalize`, `autoCorrect`) so autofill and manual entry agree — e.g. email fields
  are `keyboardType="email-address"`, `autoCapitalize="none"`, `autoCorrect={false}`.
- **`secureTextEntry` for every credential** (current + new password); pair with the
  password hints so managers offer save/fill and the strong-password generator.
- **New vs. current password:** use `new-password` on create/confirm fields (invites the
  generator) and `password` on sign-in (invites fill). Never both `newPassword` and
  `password` on the same field.
- **One-time codes:** `autoComplete="sms-otp"` / `textContentType="oneTimeCode"` so the OS
  surfaces the code from Messages; `keyboardType="number-pad"`.

## 2. Field-type → hint mapping

| Field type | RN `autoComplete` | iOS `textContentType` | `keyboardType` | Other props |
| --- | --- | --- | --- | --- |
| Email | `email` | `emailAddress` | `email-address` | `autoCapitalize="none"`, `autoCorrect={false}` |
| Username | `username` | `username` | `default` | `autoCapitalize="none"` |
| Current password (sign-in) | `password` | `password` | `default` | `secureTextEntry` |
| New password (create/confirm) | `new-password` | `newPassword` | `default` | `secureTextEntry` |
| One-time code (OTP/2FA) | `sms-otp` | `oneTimeCode` | `number-pad` | — |
| Person name (full) | `name` | `name` | `default` | `autoCapitalize="words"` |
| Given / family name | `given-name` / `family-name` | `givenName` / `familyName` | `default` | `autoCapitalize="words"` |
| Phone number | `tel` | `telephoneNumber` | `phone-pad` | — |
| Street address | `street-address` | `fullStreetAddress` | `default` | `autoCapitalize="words"` |
| Postal code | `postal-code` | `postalCode` | `number-pad` | — |
| One-time / search / free text (no autofill) | `off` | `none` | as suited | explicit `off`, not omitted |

> The kit's placeholder screens are content-only (no real auth), so no fixture currently
> renders a credential field; this spec is the contract the moment auth/profile fields
> land. Names above are the RN/Expo hint tokens — verify against the Expo v57
> `TextInput` docs before wiring, as accepted `autoComplete` values evolve.

## 3. Interaction with focus order

- Autofill does not change tab/focus order (`keyboard-focus-order.md`). A password manager
  filling multiple fields must not move focus unexpectedly; after an autofill the focus
  stays on the field the user is on, and the submit CTA remains the last stop.
- The OS autofill accessory sits above the keyboard and over `--memox-safe-area-bottom`;
  it must not occlude the focused field — keep the standard keyboard-avoidance behaviour.
