# mode-picker — Mode Picker — screen spec

> Rebaselined 2026-07-18 from `../_features/mode-picker/ModePicker.jsx`. Historical PNGs are
> compact-profile references; updated Tier-1 evidence is required before sign-off.

## Objective (contract §1)

Choose exactly one mode and scope, then explicitly start a **Practice Session**. This flow does
not replace the five-stage New-learning Session and does not activate/schedule cards.

Primary CTA: **Start session**

## Archetype (contract §2)

Selection

## Composition map (contract §3)

Top → bottom: **nested MxContextualAppBar** → primary content → primary action (Start session).
Exact layout order is owned by the source (`../_features/mode-picker/ModePicker.jsx`) and the reference PNGs — read those for pixel
composition; the component map below is the authoritative set of pieces in play.

## Component map (contract §3) — auto-derived from source

`MxButton`, `MxContextualAppBar`, `MxIconButton`, `MxList`, `MxScaffold`, `window.ActionCallout`

## State matrix (contract §6) — 3 states, each rendered light + dark

| # | state |
| --- | --- |
| 1 | `default` |
| 2 | `scope-dropdown` |
| 3 | `not-enough` |

Within `default` and `scope-dropdown`, one option is selected with radio semantics. Selecting a row
updates the selection only; **Start session** is the sole session-creation action. `not-enough`
uses a threshold of **five distinct normalized meanings** and disables both mode rows and Start.

## Handoff notes

Spacing scale `{4,8,12,16,24,32,48}`; screen padding 16; tokens only (no raw hex / off-scale).
Exactly one primary objective; touch targets ≥ 48×48. On compact height the list scrolls while
Start remains reachable; medium/expanded layout follows the Flutter adaptive guide.
