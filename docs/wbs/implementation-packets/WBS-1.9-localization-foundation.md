# WBS 1.9 — Localization foundation implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Platform / Localization |
| Depends on | `1.1`, `0.6` — Done |
| Decision gates | DG-05 (ADR-002: en/vi, RTL-ready, CJK content tested) |
| Acceptance | `AC-WBS-1.9-01` |
| Test | `TEST-WBS-1.9-01` |

## Canonical inputs

- `docs/architecture/adr/ADR-002-platform-and-adaptive-scope.md` (DG-05:
  v1 UI locales en/vi; implementation RTL-ready; CJK card content tested).
- Guard i18n rules: no hardcoded user-facing strings anywhere in UI code.
- Existing `l10n.yaml` + `lib/l10n/app_en.arb` / `app_vi.arb` generation
  pipeline (working since baseline).
- `intl ^0.20.2` from the dependency baseline.

## Scope

Create:

- `lib/core/utils/locale_formats.dart` — locale-aware formatting helpers
  used by presentation: `formatInteger`, `formatDecimal`, `formatPercent`,
  `formatMediumDate` (all take the active `Locale`; no hardcoded locale
  tags).
- `test/support/localized_app.dart` — `localizedApp(child, {locale})` widget
  wrapper with the app's delegates/locales, used by every localized widget
  test from now on.
- `test/support/l10n_fixtures.dart` — shared fixture strings: expansion
  (~1.3× German-style), CJK (Japanese/Chinese), Vietnamese diacritics.
- `test/l10n/localization_test.dart` — delegate load en/vi, plural
  resolution, RTL-direction smoke, CJK/diacritics render smoke through the
  wrapper.
- `test/core/utils/locale_formats_test.dart` — en vs vi number/percent/date
  formatting differences.

Modify:

- `lib/l10n/app_en.arb` / `app_vi.arb` — add the plural-bearing
  `cardCountLabel` (first consumer: Deck lists in 5.2/6.x) proving the
  plural pipeline end-to-end.

Generated (never edit): `lib/l10n/generated/**`.

Out of scope: adding a third locale, RTL locale shipping (v1 is en/vi;
RTL-ready only), pseudo-locale tooling, per-feature copy (owned by each
feature slice), date/number persistence formats (data layer stores
ISO-8601/UTC — 4.x).

## Exact symbols

| Symbol | File | Contract |
| --- | --- | --- |
| `String formatInteger(int value, Locale locale)` | `locale_formats.dart` | Grouped decimal pattern for the locale. |
| `String formatDecimal(num value, Locale locale)` | `locale_formats.dart` | Locale decimal separator preserved. |
| `String formatPercent(double fraction, Locale locale)` | `locale_formats.dart` | `0.42` → localized `42%`. |
| `String formatMediumDate(DateTime local, Locale locale)` | `locale_formats.dart` | Medium date (`yMMMd`) in locale words; caller passes an already-localized instant. |
| `Widget localizedApp(Widget child, {Locale? locale})` | `localized_app.dart` | MaterialApp wrapper with app delegates; single source for localized widget tests. |
| `expansionFixtureText` / `cjkFixtureText` / `vietnameseFixtureText` | `l10n_fixtures.dart` | Canonical stress strings reused by later golden/layout tests. |

Dependency direction: `core/utils` imports `intl` + Flutter foundation only;
test support imports app l10n; no feature imports.

## State matrix

| Case | Expected |
| --- | --- |
| `formatInteger(1234567, en)` vs `(…, vi)` | `1,234,567` vs `1.234.567` |
| `formatPercent(0.42)` | Localized percent with correct symbol placement |
| `formatMediumDate` en vs vi | Locale month words, no crash without app context |
| `cardCountLabel(0/1/5)` en | `No cards` / `1 card` / `5 cards` |
| `cardCountLabel(n)` vi | `n thẻ` (no plural forms in vi) |
| App under RTL text direction | Renders without crash/overflow (RTL-ready) |
| CJK + Vietnamese fixture text in a localized widget | Renders without crash |

## Acceptance and test procedure

`AC-WBS-1.9-01` is true only when:

1. Plural, number, percent and date formatting all resolve through
   locale-aware APIs with zero hardcoded locale tags in production code.
2. The localized test wrapper exists and the l10n/widget tests use it.
3. Expansion/CJK/diacritics fixtures exist as shared test constants.
4. The app tree renders under RTL direction (contract smoke) and with CJK
   content.
5. Full canonical gate passes.

`TEST-WBS-1.9-01`:

- `localization_test.dart`: `AppLocalizations.delegate.load` for en and vi;
  plural cases 0/1/5 in both locales; RTL smoke; fixture render smoke.
- `locale_formats_test.dart`: en/vi divergence for integer, decimal,
  percent and medium date (with `initializeDateFormatting`).
- Run once through `node tool/verify/run.mjs`. No loose commands.

## Failure and completion

- Success: record register evidence, mark `1.9` Done, then assess `1.7` and
  `1.10` for the next packets.
