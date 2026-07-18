# settings — Settings — screen spec

> Rebaselined 2026-07-18 from `../_features/settings/Settings.jsx`. Historical PNGs are compact
> references; SRS and Tier-1 adaptive evidence must be refreshed before sign-off.

## Objective (contract §1)

Configure the app and study behaviour (navigation hub).

Primary CTA: _none — a read / navigation surface (no competing CTA)_

## Archetype (contract §2)

Settings

## Composition map (contract §3)

Top → bottom: **nested MxContextualAppBar** → primary content → no primary action.
Exact layout order is owned by the source (`../_features/settings/Settings.jsx`) and the reference PNGs — read those for pixel
composition; the component map below is the authoritative set of pieces in play.

## Component map (contract §3) — auto-derived from source

`MxBottomNav`, `MxCard`, `MxContextualAppBar`, `MxIconButton`, `MxScaffold`, `MxSwitch`, `window.ListRow`, `window.ProfileCard`, `window.SectionLabel`

## State matrix (contract §6) — 7 states, each rendered light + dark

| # | state |
| --- | --- |
| 1 | `loaded` |
| 2 | `study-hub` |
| 3 | `study-worddisplay` |
| 4 | `study-srs` |
| 5 | `study-mode` |
| 6 | `study-voice` |
| 7 | `value-picker` |

## SRS information contract

- `study-srs` displays policy `leitner-8-box-v1`, eight boxes and intervals as read-only rows.
- Read-only SRS rows have no chevron, edit role, tap action or value-picker route.
- Due notifications remain a user preference and are the only interactive control on this child.
- The fixed policy is not copied into a settings mutation; implementation reads it from the
  versioned domain policy.

## Handoff notes

Spacing scale `{4,8,12,16,24,32,48}`; screen padding 16; tokens only (no raw hex / off-scale).
Exactly one primary objective; touch targets ≥ 48×48. Settings uses list/detail on expanded Web
and Android tablet widths as specified by the Flutter adaptive guide.
