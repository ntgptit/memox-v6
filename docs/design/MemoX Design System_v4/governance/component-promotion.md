# Candidate-promotion report — recurring shared composites → core

> Closes audit item **KIT-15-06** (dialog/sheet composites recur across ≥ 3 features at
> the feature layer with no candidate-promotion report into the core kit).

## Purpose

Some composites in `ui_kits/memox-app/_shared/` and `kit-helpers.jsx` recur across many
screens. This report evaluates whether any should be **promoted** from the pattern layer
into the frozen **core `Mx*` family** (`components/`). Promotion is warranted only when a
composite is (a) used in **≥ 3** features, (b) stable in anatomy, (c) built purely from
tokens + existing `Mx*`, and (d) generic enough that a frozen name/base class is
justified. Promotion is a **minor, additive** change (new `Mx*` name + base class);
existing composite names stay (additive-only), so no consumer breaks.

## Candidates evaluated

### Dialogs

| Candidate | Feature usages | Anatomy | Recommendation |
| --- | --- | --- | --- |
| `ConfirmDialog` (+ `kit-helpers` `Dialog` primitive) | Specializations across ≥ 3 features: `DeckDeleteConfirmDialog`, `DeckResetConfirmDialog`, `RemoveLanguageDialog`, `ExitDialog`, `AnswerSaveErrorDialog` | Scrim + centered `MxCard` + title/body + 1–2 `MxButton` actions | **Promote the primitive** — the underlying `Dialog` shell (scrim + card + title/body/actions) is generic and recurs ≥ 5×. Candidate frozen name **`MxDialog`** (base class `dialog`). Domain wrappers (`DeckDeleteConfirmDialog`, …) **stay feature-local** — they encode product copy/behavior. |

### Sheets (bottom sheets)

| Candidate | Feature usages | Anatomy | Recommendation |
| --- | --- | --- | --- |
| `SelectSheet` / `kit-helpers` `Sheet` primitive | ≥ 3: powers `DeckActionsSheet`, `DeckMoveSheet`, `DeckPlaySheet`, `ValuePickerSheet`, `ScopeSheet`, `TimePickerSheet`, `AddCardSheet`, `LibraryCreateSheet`, `CreateSubdeckSheet`, `OverflowMenuSheet`, `PairPickerSheet`, `SortSheet` | Scrim + bottom-anchored `MxCard` + grabber + header + row list/content | **Promote the primitive** — the bottom-sheet shell recurs > 10×. Candidate frozen name **`MxSheet`** (base class `sheet`), with `SelectSheet` as a promotable select-list variant. Domain sheets **stay feature-local**. |
| `DeckActionsSheet`, `DeckMoveSheet`, `DeckPlaySheet`, `ValuePickerSheet`, `ScopeSheet`, `TimePickerSheet` | 1–2 each (deck/settings/reminder-specific) | Sheet shell + domain rows | **Do not promote** — product-specific content/behavior; keep in `_shared`/`_features`. |

### Other recurring composites

| Candidate | Feature usages | Recommendation |
| --- | --- | --- |
| `DeckCard` | ≥ 3 (library, dashboard, deck-settings, move/play flows) | **Do not promote yet** — a domain card (deck title · counts · actions), not a generic surface. It is already a thin composition over `MxCard`; keep as a shared composite. Revisit if a second card type wants the same anatomy. |
| `StatusCardRow` | ≥ 2 (account-sync, settings) | **Hold** — below the ≥ 3 bar; monitor. |
| `ProfileCard` | 1–2 | Do not promote — feature-specific. |
| `ActionCallout` | ≥ 2 in this doc's count, but **10 usages across `_features/**`** — every feature screen that reports something in place composes it, while `.banner` is composed by none | **Promote (recommended).** The Flutter port had no equivalent and reached for `MxBanner` (the `.banner` port) in 6 places. They are not interchangeable: `ActionCallout` pads `s3/s4` on the control radius and centres its row, `.banner` pads `s4` on the card radius and aligns to the top — 8 logical px taller. That pushed `create-deck-firstrun--submit-failure` out of parity until it was measured. `MxActionCallout` now exists in the app (`lib/presentation/shared/widgets/mx_action_callout.dart`) sharing `MxBannerTone`, since the tone scale belongs to the kit rather than to either component. |
| `EmptyState`, `Skeleton`, `ProgressBar`, `ListRow`, `Stat` (`kit-helpers`) | many | **Strong future candidates** — generic, token-built, used across screens. Recommend promotion evaluation in the next minor as `Mx*` primitives (e.g. `MxEmptyState`, `MxSkeleton`, `MxProgressBar`). Deferred here to keep this batch docs-only. |

### Split candidate — `MxTextField` multiline

| Candidate | Feature usages | Recommendation |
| --- | --- | --- |
| `MxTextField` `multiline` prop → a separate **`MxTextArea`** | Single-line: many. Multi-line: deck description (`create-deck` step 2, `edit-deck`), with note/paste fields expected in `13.x` import and `5.3.x` card content | **Split recommended (minor / additive)** — the two are different controls, not one control with a flag. Multiline renders `<textarea>`, keeps intentional line breaks (`docs/business/deck/edit-deck.md` §Description) and gives Enter to the text; single-line renders `<input>` and gives Enter to the form. One component with a boolean hides that difference behind a default: the Flutter port defaulted a multiline field to two resting rows, which silently cost ~4.4% against `create-deck-firstrun--step2-optional` until it was measured. Proposed frozen name **`MxTextArea`** (base class `field--multiline`, already in `components.css`), keeping `rows`/`maxRows`. `MxTextField` then drops `multiline`/`rows`, so the wrong control cannot be selected by accident. |

**Status:** implemented on the Flutter side ahead of the kit (`lib/presentation/shared/widgets/inputs/mx_text_area.dart`), matching how `MxEmptyState`, `MxSelectRow`, `MxSectionLabel` and `MxLink` were adopted. The kit-side rename is what needs an owner decision; until it lands, the app carries an `Mx*` name the kit does not define.

## Recommendation summary

| Action | Artifacts | Bump | Notes |
| --- | --- | --- | --- |
| **Promote (recommended, next minor)** | `Dialog`→`MxDialog`, `Sheet`→`MxSheet` (+ `SelectSheet` variant) | Minor / additive | New frozen names + base classes; domain wrappers unchanged; must ship full state matrix + parity per `acceptance-criteria.md` |
| **Evaluate next** | `EmptyState`, `Skeleton`, `ProgressBar` from `kit-helpers` | Minor / additive | Generic, high reuse |
| **Split (recommended)** | `MxTextField` `multiline` → `MxTextArea` | Minor / additive | Different control, not a flag; already split in the Flutter port |
| **Promote (recommended)** | `ActionCallout` → `MxActionCallout` | Minor / additive | 10 feature usages vs 0 for `.banner`; the two differ by 8 logical px and are not interchangeable |
| **Keep feature-local** | All `Deck*` dialogs/sheets, `ValuePickerSheet`, `TimePickerSheet`, `ProfileCard`, `DeckCard` | — | Encode product copy/behavior; promoting would leak domain into core |
| **Hold (below ≥ 3)** | `StatusCardRow` | — | Monitor usage |

## Promotion checklist (when acted on)

Any promotion follows `versioning.md` (minor bump) + `acceptance-criteria.md` (Component
criteria C1–C8): assign a stable PascalCase `Mx*` name + base class, consume only tokens,
render the full state matrix in light+dark, add `role`/`aria-*`, register in
`_ds_manifest.json`, keep the old composite name (additive), and record the change in
`CHANGELOG.md`. This report is the evaluation record; **no promotion is executed in this
docs batch** — executing one changes source, which is out of scope here.
