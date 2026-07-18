# recall-mode — Recall — screen spec

> Rebaselined 2026-07-18 from `../_features/recall-mode/RecallMode.jsx`. Historical PNGs remain
> compact references; the new timed-out state requires fresh Tier-1 evidence.

## Objective (contract §1)

Recall a term within 20 seconds, reveal it, then self-grade. Timeout is a distinct terminal answer.

Primary CTA: **Got it**

## Archetype (contract §2)

Focused task/study flow

## Composition map (contract §3)

Top → bottom: **nested MxContextualAppBar** → primary content → primary action (Got it).
Exact layout order is owned by the source (`../_features/recall-mode/RecallMode.jsx`) and the reference PNGs — read those for pixel
composition; the component map below is the authoritative set of pieces in play.

## Component map (contract §3) — auto-derived from source

`MxButton`, `MxContextualAppBar`, `MxIconButton`, `MxScaffold`, `window.EmptyState`, `window.Note`, `window.ProgressHeader`, `window.StudyPromptCard`

## State matrix (contract §6) — 6 states

| # | state |
| --- | --- |
| 1 | `before-reveal` |
| 2 | `revealed` |
| 3 | `forgot` |
| 4 | `remembered` |
| 5 | `timed-out` |
| 6 | `complete` |

## Timer behaviour

- Duration is exactly 20 seconds from the injected session/monotonic clock.
- Widget rebuild, resize, rotation and background/resume do not restart the countdown.
- At zero, reveal the meaning, record `Timeout` exactly once, show the timeout note and expose only
  **Continue**. Do not silently map timeout to Forgot and do not show both grading buttons.
- Screen-reader status announces the remaining-time threshold and terminal timeout without
  announcing every tick. Reduced motion does not change the duration or outcome.

## Handoff notes

Spacing scale `{4,8,12,16,24,32,48}`; screen padding 16; tokens only (no raw hex / off-scale).
Exactly one primary objective; touch targets ≥ 48×48. Medium/expanded and compact-height layouts
follow the Flutter adaptive guide.
