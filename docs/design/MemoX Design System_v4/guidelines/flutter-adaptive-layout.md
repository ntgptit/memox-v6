# Flutter adaptive layout — Web and Android Tier 1

> Owner: Design System team · Status: Current · Decision date: 2026-07-18
>
> This is the canonical responsive/adaptive handoff for MemoX v6. It closes the
> specification portion of KIT-11-05, KIT-32, KIT-33, KIT-34, KIT-35 and KIT-36.
> Runtime screenshots and walkthrough recordings remain release evidence, not documentation.

## 1. Window profiles

Choose a profile from the **available window width**, never device model or orientation name.
All values are logical pixels.

| Profile | Width | Compact-height modifier | Required Tier-1 fixtures |
| --- | ---: | ---: | --- |
| Compact | `< 600` | usable height `< 480` | 320, 390 and 599; portrait and landscape/short window |
| Medium | `600–839` | usable height `< 480` | 600 and 839; Android tablet and Web |
| Expanded | `>= 840` | usable height `< 480` | 840, 1200 and 1440 Web/large tablet |

Flutter mapping: a single app-level `MxWindowProfile` value is derived from
`MediaQuery.sizeOf(context)`. Features consume the profile through the existing theme/layout
contract; they do not inspect `Platform`, browser user-agent or physical screen size.

## 2. Gutters and max widths

| Surface | Compact | Medium | Expanded |
| --- | --- | --- | --- |
| Screen gutter | `--memox-gutter` | `--memox-gutter-medium` | `--memox-gutter-expanded` |
| Reading/forms/settings | full available width | max `--memox-content-width-reading` | max `--memox-content-width-reading` |
| Focused study | full available width | max `--memox-content-width-study` | max `--memox-content-width-study` |
| Lists/search | one pane | max `--memox-content-width-list`; optional supporting pane | max `--memox-content-width-list`; list/detail allowed |
| Today/dashboard | one column | two-column reflow when content fits | max `--memox-content-width-dashboard`; primary due content first |

Content is centered after max width is reached. Reflow preserves semantic reading order; no
profile may merely scale the compact frame or stretch cards to the window edge.

## 3. Navigation and pane rules

- **Compact:** four destinations in `MxBottomNav`; pushed detail uses one pane and app-bar Back.
- **Medium/expanded:** the same destinations render as a navigation rail owned by `MxScaffold`.
  The public destination ids and `data-mx-node="shell/bottom-nav"` remain stable even when the
  visual presentation is a rail.
- List/detail uses two panes only at expanded width and only when both panes meet their readable
  minimum. List is leading, detail is trailing. At `< 840`, detail collapses to a pushed route.
- Resizing from two panes to one keeps the selected item as the pushed detail and preserves list
  scroll/filter state. Back closes detail before leaving the feature.
- Browser Back, Android system Back and app-bar Back resolve through the same route-pop contract.
  Back first dismisses an overlay or selection mode, then pops detail, then leaves the feature.

## 4. Adaptive overlays

| Intent | Compact | Medium/expanded |
| --- | --- | --- |
| Short selection/action list | bottom `MxSheet` | anchored `MxMenu` when a stable trigger exists; otherwise centered `MxDialog` |
| Destructive confirmation | `MxDialog` | `MxDialog` |
| Multi-field editor/import mapping | full-height pushed route | centered constrained dialog or supporting pane |
| Date/time/file/media capability | platform/browser adapter | platform/browser adapter |

An overlay never crosses a hinge/unsafe region, always fits within safe bounds, and scrolls its
body when compact height would hide the primary action. Escape/Web and Android Back cancel the
top overlay; cancellation preserves user input and restores focus to the trigger.

## 5. Web keyboard and pointer contract

- Tab/Shift+Tab follow semantic reading order; every interactive element has visible focus.
- Enter activates links/default actions; Space activates buttons, switches and selections.
- Escape closes the top overlay or exits selection/search mode without discarding form data.
- Pointer hover is supplementary. The same action works by touch and keyboard.
- No hover-only content or context menu is the sole route to an action.
- Scroll wheel/trackpad scroll the focused pane. Focus must not jump when async content refreshes.
- Tooltips describe icon-only actions after hover/focus delay and never contain required content.

## 6. Android and system UI

- `MxScaffold` consumes top/bottom/view insets once; nested content must not add them again.
- IME opening keeps the focused field and primary action reachable and allows body scroll.
- Android system Back follows §3/§4. Predictive-back animation is runtime-owned and must not
  commit navigation before cancellation is resolved.
- Phone/tablet portrait and landscape are supported by the same width profiles.
- Foldables re-evaluate on every window change. A separated hinge is an unsafe gap; content may
  use either side or two panes, but no control or text may straddle the hinge.

## 7. State preservation on resize/rotation

Preserve route, selected Deck/card, draft input, current Study Session snapshot, answer state,
filters, search query and scroll anchor. Do not restart a timer or schedule an answer because the
window changed. Overlays may adapt presentation, but retain their draft and focus target.

Recall countdown is based on the injected monotonic/session clock, not widget rebuilds. Background,
rotation and resize render the remaining duration from persisted/session state.

## 8. Per-feature adaptation

| Feature | Medium/expanded behaviour | Compact-height rule |
| --- | --- | --- |
| Today | due/continue section precedes goal/streak supporting column | hide decorative supporting copy before moving primary action |
| Library/Search | list/detail at expanded; filter/sort stays with list | list scrolls; selection actions remain reachable |
| Deck/Flashcard editor | constrained form; optional preview supporting pane | focused field + Save remain visible above IME |
| Mode Picker | selection list + sticky Start session; max reading width | list scrolls; Start session remains reachable |
| Study Session/modes | centered study width; no unrelated side pane | progress, answer and primary action remain reachable |
| Settings | category list/detail at expanded | active child scrolls independently |

## 9. Verification matrix

Before Tier-1 design sign-off, capture light/dark and `en`/`vi` evidence for representative
screens at every boundary in §1. The minimum flow set is: first run, Library list/detail, create
Deck, create Flashcard with IME, Mode Picker, all five new-learning stages, Recall timeout, due
review, session recovery/finalize, Today loaded/offline/error/partial/paused, and Settings SRS.

Run keyboard/pointer walkthroughs on Web and resize/rotation/IME tests on Android. Mark a KIT item
PASS only when the evidence file/version/state is linked from its Evidence Log.
