# Component constraint & combination matrix

> Guideline layer for the frozen `Mx*` family. Additive documentation only — it names
> existing behaviour and rules; it does not add or rename tokens, classes, props or ids.
> Closes audit items KIT-16-04 (kit-wide text/action constraints), KIT-17-05
> (supported vs excluded prop combinations) and KIT-16-06 (nested-interactive /
> invalid-combination rule).
>
> Owner: Design System team · Status: Current (v4, additive-only).

Each `Mx*` component's own `*.prompt.md` carries its **When not to use**, **States**,
**Content limits / i18n** and **Do / Don't** sections. This file is the single cross-component
view: hard limits, legal prop combinations, and the rules that hold across the whole kit.

---

## 1. Text-wrap, min/max and action-count constraints

| Component | Text wrap | Min / max content | Action count |
| --- | --- | --- | --- |
| MxButton | label single-line, `nowrap` | ≤ ~24 chars / 1–2 words; `block` for width growth | 1 label + optional lead/trail icon |
| MxLink | inline, may wrap in flow | 1–2 words | 1 (+ trailing chevron) |
| MxIconButton | n/a (icon only) | exactly 1 icon | 1 |
| MxFab | label `nowrap` | 1 short verb phrase; round = no text | 1 |
| MxChip | label `nowrap`; row scrolls | ≤ ~16 chars | 1 (+ optional lead icon) |
| MxBadge | `nowrap` | ≤ ~12 chars / count (99+ cap at call site) | 0 (non-interactive) |
| MxSegmentedControl | each segment `nowrap` | 2–3 segments, 1 word each; fit 320px | 2–3 |
| MxSwitch | none (no visible text) | requires external label + `ariaLabel` | 1 |
| MxTextField | value wraps only when `multiline` | label/helper/error reserve vertical space, never truncate error | 1 field |
| MxSearchDock | placeholder `nowrap` | short placeholder | 1 trailing control |
| MxBottomNav | label `nowrap` | 3–5 items, 1 word each | 3–5 |
| MxContextualAppBar | title single-line, truncates | title truncates; `context` short | **max 2** right actions (avatar counts as one; 3rd → overflow) |
| MxSectionHeader | title 1 line (may wrap/truncate), caption short | action ≤ 2 words | 1 trailing action |
| MxCard | content-driven, long text wraps (never clip) | sensible min-height for sparse content; no fixed height | arbitrary children |
| MxList | n/a | ≥1 item (empty → render empty-state) | n/a |
| MxAvatar / MxIconTile | n/a | 1 image/2 initials · 1 icon | 0 (non-interactive) |
| MxScaffold | n/a | one per screen | appBar + bottomNav + fab slots |

**Global rules.** Spacing only from `{4,8,12,16,24,32,48}`; screen padding 16; max 3 nested
surfaces; max 5 typography roles per screen; exactly one top-level heading and one primary CTA;
touch targets ≥ 44×44. No raw color/radius/typography/spacing above the token layer.

---

## 2. Supported vs excluded prop combinations

Only combinations that are meaningful are listed as **supported**; the TypeScript unions in each
`*.d.ts` constrain individual values, but the following combinations are semantically invalid even
though they type-check.

| Component | Supported combinations | Excluded / meaningless (do not ship) |
| --- | --- | --- |
| MxButton | `variant` × `danger` × `size` × `block` × `disabled`; `icon`/`trailingIcon` optional | `danger` on `contrast` (white pill on primary card can't also read as error) → use a plain button; `block` + used as a link → use `MxLink` |
| MxIconButton | `variant` × `size="sm"`; `ariaLabel` always | any usage without `ariaLabel`; raw ligature as `ariaLabel` |
| MxFab | extended (`label`) **or** `round`; `disabled` | `round` without `ariaLabel`; `label` + `round` together |
| MxChip | `selected` × `variant` × `icon` | a "disabled" chip (no disabled state — omit/hide instead, KIT-18-04) |
| MxBadge | `tone` × (`soft` \| `dot`) | `dot` + children (dot is bare); interactive badge |
| MxSwitch | `checked` × `disabled` × `ariaLabel` | switch without `ariaLabel`; switch used as a choice picker |
| MxTextField | `label`/`helper`/`error`; `multiline`+`rows`; `type`+`inputMode` | `error` + `helper` shown together (error hides helper); `multiline` + single-line `type` |
| MxSegmentedControl | 2–3 `segments` × `block` | >3 segments; per-segment disabled (not modeled) |
| MxContextualAppBar | one `variant`; slots per variant; ≤2 actions | >2 right actions; `count` on a non-`selection` variant; `avatar` on non-`root` variant; `search` object on a non-`search` variant |
| MxCard | `variant` × `padding` × `interactive` | `interactive` wrapping its own interactive children (see §3) |
| MxSectionHeader | title × caption × action(+`actionLabel`) | multiple actions; non-text action without `actionLabel` |

---

## 3. Nested-interactive & invalid-combination rule

**Rule (kit-wide):** an interactive element must never contain another independently interactive
element. A screen reader and a pointer both need exactly one target per region.

- **MxCard `interactive` (role=button + tabIndex):** its children must be static content only.
  If a card region needs its own buttons/links/switches, make the card **non-interactive** and
  give each child control its own affordance. Do **not** place `MxButton`, `MxLink`, `MxIconButton`,
  `MxSwitch`, `MxChip` (onClick) or a nested `interactive` `MxCard` inside an `interactive` card.
- **MxLink / MxButton:** never nest inside another interactive card, link or button.
- **MxContextualAppBar:** actions are icon buttons only — do not embed a composite interactive
  cluster; overflow the 3rd+ action.
- **MxSectionHeader:** the trailing `action` is the only interactive part; the title/caption stay
  non-interactive.

**Enforcement / detection.** During screen construction (per the mobile-ui-construction-contract),
verify no `interactive`/role=button surface contains a focusable descendant. A card that needs both
a whole-card tap *and* inner controls is an invalid composition — split it.
