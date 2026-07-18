# dashboard — Today — screen spec

> Rebaselined 2026-07-18 from `../_features/dashboard/Dashboard.jsx`. Historical PNGs are compact
> references; paused/offline/partial/error and Tier-1 adaptive states require fresh evidence.

## Objective (contract §1)

Resume studying: surface what is due and the fastest way back in.

Primary CTA: **Start review**

## Archetype (contract §2)

Dashboard

## Composition map (contract §3)

Top → bottom: **root MxContextualAppBar** → primary content → primary action (Start review).
Exact layout order is owned by the source (`../_features/dashboard/Dashboard.jsx`) and the reference PNGs — read those for pixel
composition; the component map below is the authoritative set of pieces in play.

## Component map (contract §3) — auto-derived from source

`MxAvatar`, `MxBadge`, `MxBottomNav`, `MxButton`, `MxCard`, `MxContextualAppBar`, `MxFab`, `MxFabAdd`, `MxIconButton`, `MxLink`, `MxList`, `MxScaffold`, `MxSectionHeader`, `window.DeckCard`, `window.Note`, `window.Skeleton`

## State matrix (contract §6) — 13 states

| # | state |
| --- | --- |
| 1 | `loaded` |
| 2 | `not-studied` |
| 3 | `goal-met` |
| 4 | `streak-reset` |
| 5 | `caught-up` |
| 6 | `paused` |
| 7 | `offline` |
| 8 | `partial` |
| 9 | `error` |
| 10 | `create-sheet` |
| 11 | `empty` |
| 12 | `empty-after-onboarding-skip` |
| 13 | `loading` |

`offline` may start only the saved local due queue. `partial` keeps the due action available while
marking goal/streak/statistics unavailable. `paused` prioritizes Resume and preserves the session
snapshot. `error` never implies data loss and offers Retry plus Library fallback.

## Handoff notes

Spacing scale `{4,8,12,16,24,32,48}`; screen padding 16; tokens only (no raw hex / off-scale).
Exactly one primary objective; touch targets ≥ 48×48. On medium/expanded widths, due/resume content
precedes goal/streak supporting content in semantic and focus order.
