# Ownership index — MemoX Design System

> Closes audit item **KIT-46-01** (foundation/component/pattern/theme areas had no owner or reviewer).

Every area of the kit has a single accountable **owner** and a named **reviewer role**
that must approve changes before merge. There is one team behind the kit; ownership is
expressed by area so that review responsibility is unambiguous, not so that work is
siloed.

- **Owner** — accountable for the area's correctness, its frozen-identifier contract,
  and its audit status. For every area in this kit the owner is the **Design System team**.
- **Reviewer role** — the review lens that must sign off a PR touching the area (see
  `CONTRIBUTING.md` and `acceptance-criteria.md` for what each lens checks).

## Foundation (tokens)

| Area | Source | Owner | Required reviewer role |
| --- | --- | --- | --- |
| Color roles + themes | `tokens/colors.css` | Design System team | Token reviewer + Accessibility reviewer (contrast) |
| Typography + `@font-face` | `tokens/typography.css` | Design System team | Token reviewer |
| Spacing / gutter / layout metrics | `tokens/spacing.css` | Design System team | Token reviewer |
| Component metrics | `tokens/component.css` | Design System team | Token reviewer |
| Radius | `tokens/radius.css` | Design System team | Token reviewer |
| Stroke / size / icon-size | `tokens/stroke.css`, `tokens/size.css`, `tokens/icon-size.css` | Design System team | Token reviewer |
| Elevation / focus ring | `tokens/elevation.css` | Design System team | Token reviewer |
| Motion / duration / easing | `tokens/motion.css` | Design System team | Token reviewer |
| Opacity | `tokens/opacity.css` | Design System team | Token reviewer |

## Components (the frozen `Mx*` family)

| Area | Source | Owner | Required reviewer role |
| --- | --- | --- | --- |
| Core (`MxButton`, `MxTextField`, `MxChip`, `MxBadge`, `MxSwitch`, `MxSegmentedControl`, `MxAvatar`, `MxLink`) | `components/core/` | Design System team | Component reviewer + Accessibility reviewer |
| Surfaces (`MxScaffold`, `MxContextualAppBar`, `MxCard`, `MxSectionHeader`, `MxIconTile`, `MxList`) | `components/surfaces/` | Design System team | Component reviewer |
| Navigation (`MxBottomNav`, `MxFab`, `MxSearchDock`, `MxIconButton`) | `components/navigation/` | Design System team | Component reviewer + Accessibility reviewer |
| Layer-2 base-class styling | `components.css` | Design System team | Component reviewer |

## Patterns (feature composites + shared composites)

| Area | Source | Owner | Required reviewer role |
| --- | --- | --- | --- |
| Cross-screen shared composites (`ConfirmDialog`, `DeckActionsSheet`, `DeckMoveSheet`, `SelectSheet`, `StatusCardRow`, `StudyPromptCard`, …) | `ui_kits/memox-app/_shared/` | Design System team | Pattern reviewer + Component reviewer |
| Per-screen feature composites (26 screens) | `ui_kits/memox-app/_features/<screen>/` | Design System team | Pattern reviewer |
| Kit-only composites (`ProgressBar`, `Skeleton`, `EmptyState`, `Dialog`, `Sheet`, …) | `ui_kits/memox-app/kit-helpers.jsx` | Design System team | Pattern reviewer |

## Theme

| Area | Source | Owner | Required reviewer role |
| --- | --- | --- | --- |
| Light theme (`:root`) + dark theme (`[data-theme='dark']`) role values | `tokens/colors.css`, `tokens/elevation.css` | Design System team | Token reviewer + Accessibility reviewer |
| Theme picker composites | `ui_kits/memox-app/_features/theme/` | Design System team | Pattern reviewer |

## Governance & tooling

| Area | Source | Owner | Required reviewer role |
| --- | --- | --- | --- |
| Adherence lint rules | `_adherence.oxlintrc.json` | Design System team | Governance reviewer |
| Kit shot / contrast verification | `tool/ui_kit_shots/` | Design System team | Governance reviewer |
| Kit ↔ app parity gate | `tool/parity/` | Design System team | Governance reviewer |
| Governance docs (this folder) + `CHANGELOG.md`, `SCOPE.md` | `governance/`, root | Design System team | Governance reviewer |

## Sign-off authority

Release sign-off (see `release-signoff.md`) requires three owner roles to record
approval: **design owner**, **accessibility owner**, and **governance owner** — all
currently filled by the Design System team acting in those capacities.
