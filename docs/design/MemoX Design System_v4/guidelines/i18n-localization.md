# Internationalization & localization guide

> Guideline / spec layer. This documents the i18n contract for the kit and the production
> React Native app; the runtime wiring (string tables, format layer, RTL flip) is engineering's
> job — this file defines the rules they build to. Additive only: no token/class/name changes.
>
> Owner: Design System team · Status: Current (v4, additive-only).
> Closes audit items: KIT-09-04 (per-script font fallback), KIT-37-01 (expansion corpus
> guidance), KIT-37-02 (CJK/Vietnamese font stack), KIT-37-04 (locale number/date/plural
> formatting), KIT-37-06 (string externalization), KIT-20-04 (date/relative-time formatting),
> KIT-20-06 (count+noun pluralization), KIT-26-06 (RTL scope statement).

---

## 1. Locale scope

| Tier | Locales | Status |
| --- | --- | --- |
| Shipping | English (en), Vietnamese (vi) | Supported |
| Planned | CJK (Chinese/Japanese/Korean study content) | Content-ready (fonts + fallback declared); UI strings pending |
| Not yet supported | RTL UI (Arabic/Hebrew) | Rules defined here; not enabled in product (product is LTR today) |

The app is **local-first** and study content is user-authored in any script, so the type stack and
layout must render arbitrary scripts even before the UI itself is translated.

---

## 2. Per-script font fallback (KIT-09-04, KIT-37-02)

The frozen primary family is **Plus Jakarta Sans** (`--memox-font-sans`), which covers Latin +
Latin-Extended (Vietnamese diacritics fully). It does **not** cover CJK or Arabic glyphs, so those
resolve through the OS fallback already present in `--memox-font-sans`
(`-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, …`). Declare the intended fallback so it
is a decision, not an accident:

| Script | Primary | Fallback (per-platform, via OS stack) |
| --- | --- | --- |
| Latin / Vietnamese | Plus Jakarta Sans | system sans — diacritics render in-family; no fallback needed |
| Chinese (SC/TC) | — | iOS `PingFang SC/TC`, Android `Noto Sans CJK SC/TC`, Windows `Microsoft YaHei` |
| Japanese | — | iOS `Hiragino Sans`, Android `Noto Sans CJK JP` |
| Korean | — | iOS `Apple SD Gothic Neo`, Android `Noto Sans CJK KR` |
| Arabic/Hebrew (future) | — | iOS `Geeza Pro`/system, Android `Noto Sans Arabic/Hebrew` |

**RN production note.** Do not hard-code CJK family names in component styles; keep a single
theme-level font constant that maps to `--memox-font-sans` and let the platform fall back per
script. If a bundled CJK face is required for brand consistency, add it as a **new** theme font
constant (additive) — never rename `--memox-font-sans`. Vietnamese diacritics (combining marks,
stacked tone + vowel marks) must be verified at the largest type roles; the variable font carries
them, so no reflow is expected — capture per-script sample shots when adding a locale.

---

## 3. String externalization (KIT-37-06)

- **No user-visible string literals in JSX.** Every label, placeholder, helper, error, empty-state
  copy, `ariaLabel`, and toast message comes from a keyed string table (`t('deck.editor.save')`),
  not an inline literal. The kit's `_features/**` fixtures use literals only because they are static
  prototypes; production screens must route through the table.
- Keys are namespaced by screen/pattern (`library.filter.due`, `editor.save`).
- Pass interpolation values as arguments, never by string concatenation (see §5).
- `MxIconButton.ariaLabel`, `MxSwitch.ariaLabel`, `MxFab.ariaLabel` are user-visible to AT — they
  are externalized too.

---

## 4. Locale-aware date / number / relative-time formatting (KIT-37-04, KIT-20-04)

Never hard-code English date/number strings (e.g. "Saturday · 27 Jun", "142", "2 days ago").
Route every one through a **format layer** (`Intl` / RN i18n):

| Value kind | Rule | Example en → vi |
| --- | --- | --- |
| Date / time | locale calendar + month/day names + order | "Saturday · 27 Jun" → "Thứ Bảy · 27 thg 6" |
| Relative time | locale `RelativeTimeFormat` | "2 days ago" → "2 ngày trước" |
| Number / count | locale digit grouping + separators | "1,240" → "1.240" |
| Currency / units | locale currency & unit format | — |
| Percentage | locale percent format | "72%" |

The app-bar `context` label, dashboard "cards due" figures, sync "last synced" timestamps, and
statistics values are all format-layer outputs — the fixtures show one rendered locale only.

---

## 5. Pluralization & count+noun composition (KIT-20-06)

Do **not** build phrases by concatenating a number with a noun fragment ("`" + n + " selected`",
"142 cards due"). Different locales have different plural categories (Vietnamese has one; English
has one/other; some locales have up to six).

- Use ICU plural messages: `t('selection.count', {count: n})` → `{count, plural, one {# selected}
  other {# selected}}`.
- Keep the **whole** phrase (number + noun + any preposition) inside the message so translators can
  reorder and inflect it.
- Applies to: "N selected" (`MxContextualAppBar` selection), "142 cards due", "6 active",
  "N results", bulk-action confirmations ("Delete N cards?").

---

## 6. Text expansion (KIT-37-01)

Design for **+30–50%** text length versus English (German/Vietnamese/Finnish run long).

- Buttons/tabs/dialog titles/segment labels must not be width-locked to the English string — allow
  `block`, wrap, or truncation-with-tooltip per the constraints matrix.
- App-bar titles truncate (never wrap/grow the bar); bottom-nav and segmented labels stay one word;
  chip rows scroll.
- When authoring an edge-data fixture set, include a "long-text" state whose strings are ~1.4× the
  English length (an expansion pseudo-locale is ideal), plus a large-font (200%) pass.

---

## 7. RTL & logical properties (KIT-26-06, and see KIT-37-03/05 code side)

RTL UI is **not enabled in product today** (LTR-only), but all new layout guidance uses logical
direction so enabling it later is additive:

- Author spacing/position with logical properties (`padding-inline-start`, `margin-inline-end`,
  `inset-inline-*`) rather than physical `left`/`right`. (Retrofitting existing physical values in
  `components.css` is the code agent's task — KIT-37-03/05.)
- **Mirror under `dir=rtl`:** leading/trailing icons (button, chip, link, search dock), back
  buttons, `chevron_*` and `arrow_back`, FAB resting corner, bottom-nav order, section-header
  action, app-bar leading/actions.
- **Do not mirror:** media, avatars, symmetric icons, brand wordmark, and numerals within LTR runs.
- Study **content** direction is independent of UI direction — a card's term/definition may be RTL
  text inside an LTR UI; set the text node's `dir` from the content, not the app.

---

## 8. Adding a locale — checklist

1. Provide the string table for all namespaces; run a missing-key scan.
2. Declare the script's font fallback (§2) and capture per-script sample shots.
3. Confirm the format layer covers the locale's date/number/plural rules (§4–5).
4. Run the long-text (+40%) and 200%-font passes (§6); fix any clip/overflow.
5. If the locale is RTL, enable the logical-property flip (§7) and re-shoot mirrored states.
