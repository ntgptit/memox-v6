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
| `ActionCallout` | ≥ 2 | Hold — below the bar; monitor. |
| `EmptyState`, `Skeleton`, `ProgressBar`, `ListRow`, `Stat` (`kit-helpers`) | many | **Strong future candidates** — generic, token-built, used across screens. Recommend promotion evaluation in the next minor as `Mx*` primitives (e.g. `MxEmptyState`, `MxSkeleton`, `MxProgressBar`). Deferred here to keep this batch docs-only. |

## Recommendation summary

| Action | Artifacts | Bump | Notes |
| --- | --- | --- | --- |
| **Promote (recommended, next minor)** | `Dialog`→`MxDialog`, `Sheet`→`MxSheet` (+ `SelectSheet` variant) | Minor / additive | New frozen names + base classes; domain wrappers unchanged; must ship full state matrix + parity per `acceptance-criteria.md` |
| **Evaluate next** | `EmptyState`, `Skeleton`, `ProgressBar` from `kit-helpers` | Minor / additive | Generic, high reuse |
| **Keep feature-local** | All `Deck*` dialogs/sheets, `ValuePickerSheet`, `TimePickerSheet`, `ProfileCard`, `DeckCard` | — | Encode product copy/behavior; promoting would leak domain into core |
| **Hold (below ≥ 3)** | `StatusCardRow`, `ActionCallout` | — | Monitor usage |

## Promotion checklist (when acted on)

Any promotion follows `versioning.md` (minor bump) + `acceptance-criteria.md` (Component
criteria C1–C8): assign a stable PascalCase `Mx*` name + base class, consume only tokens,
render the full state matrix in light+dark, add `role`/`aria-*`, register in
`_ds_manifest.json`, keep the old composite name (additive), and record the change in
`CHANGELOG.md`. This report is the evaluation record; **no promotion is executed in this
docs batch** — executing one changes source, which is out of scope here.
