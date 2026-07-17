# Navigation, overlays & state-preservation rules

> Guideline / spec layer for how screens, overlays and navigation state behave. Additive
> documentation only — no token/class/name changes. Production RN navigation implements these
> rules; the static kit demonstrates single-overlay states.
>
> Owner: Design System team · Status: Current (v4, additive-only).
> Closes audit items: KIT-24-05 (nested modal-stack limit + focus restoration),
> KIT-24-06 (preserve vs reset scroll/search/filter on tab/route change),
> KIT-29-06 (approved/forbidden overlay-combination matrix).

---

## 1. Overlay taxonomy

| Overlay | Component / helper | Dismiss | Focus trap |
| --- | --- | --- | --- |
| Bottom sheet | `kit-helpers` sheet (`SelectSheet`, `SortSheet`, create sheet…) | scrim tap, back, drag-down, explicit action | yes |
| Dialog | `_shared/ConfirmDialog` and kin | scrim tap (non-destructive), back, explicit action | yes |
| Menu | `kit-helpers` menu / `MenuItem` | scrim tap, back, item select | yes |
| Search mode | `MxContextualAppBar variant="search"` | back / clear | no (in-place) |
| Selection mode | `MxContextualAppBar variant="selection"` | close (X), back | no (in-place) |
| Full-screen modal task | `MxContextualAppBar variant="modal"` in an `MxScaffold` | close (X), back | it is a route, not a layer |

---

## 2. Modal / overlay stack limit & focus restoration (KIT-24-05)

**Stack limit.** At most **one dismissable layer open at a time** over a screen (see §4). The only
sanctioned nesting is a **confirm dialog raised from within a sheet** (e.g. a discard-confirm over
an open editor sheet) — depth **2 maximum**. Never stack sheet-on-sheet or menu-on-menu; replace the
current layer instead of stacking.

**Focus restoration (required).**
1. On open, move focus into the overlay: to its first focusable control, or its heading if it has no
   immediate control. Focus is trapped inside the overlay while open (Tab cycles within).
2. Content behind the overlay is inert (`aria-hidden` / not focusable / not hit-testable).
3. On close, **return focus to the trigger** that opened the overlay. If the trigger no longer
   exists (e.g. the row was deleted), move focus to the nearest logical anchor (the list heading or
   the app bar), never to `document.body`.
4. Back gesture / hardware back closes the **top-most** overlay only and restores focus per (3); it
   does not navigate the route until no overlay is open.
5. `Esc`/back on a dirty form triggers the discard-confirm rather than losing input.

---

## 3. State preservation on tab / route change (KIT-24-06)

When the user leaves a screen and returns, some UI state is **preserved** and some is **reset**:

| State | On tab switch (bottom nav) | On push→back (detail) | On full route replace |
| --- | --- | --- | --- |
| Scroll position | preserve | preserve (restore list offset) | reset |
| Active search query | preserve while the tab lives; clear on leaving search mode | preserve | reset |
| Active filters / sort | preserve | preserve | reset |
| Selection mode | **exit** before leaving (see below) | exit | reset |
| Expanded/collapsed sections | preserve | preserve | reset |
| Form input (editor) | preserve as draft (dirty guard) | preserve as draft | prompt discard |

**Rules.**
- **Back exits a transient mode before it navigates.** If selection or search mode is active, back
  first exits that mode; a second back navigates.
- **Selection is dropped when the underlying set changes.** Changing filter/sort/search clears the
  current selection (hidden-but-selected items must never be acted on silently) — re-enter selection
  after the set settles.
- **Search/filter reset scope.** Filters persist within a destination's session; they reset when the
  destination is fully re-entered from a different top-level route, not on every back.

---

## 4. Approved / forbidden overlay combinations (KIT-29-06)

Baseline: **one dismissable overlay at a time.**

| Combination | Verdict | Reason |
| --- | --- | --- |
| Sheet **then** confirm dialog raised from it (depth 2) | Approved | Confirms a destructive/irreversible action taken in the sheet; return focus to the sheet on cancel |
| Dialog only / sheet only / menu only | Approved | The normal case |
| Search mode + a sheet (e.g. filter sheet) opened from the search screen | Approved | Search is in-place (not a layer); the sheet is the single layer |
| Selection mode + confirm dialog (bulk destructive) | Approved | Selection is in-place; the dialog is the single layer |
| Sheet **on** sheet | Forbidden | Replace, don't stack — the second sheet supersedes the first |
| Menu **on** menu, dialog **on** dialog | Forbidden | Ambiguous dismiss target and focus owner |
| Two independent overlays from different triggers at once | Forbidden | Only the top-most can own focus |
| Toast/snackbar + any overlay | Allowed (non-modal) | A transient status message is not a focus layer; it must not trap focus or block dismiss |

**Enforcement.** Opening a new dismissable layer while one is open must **replace** it (or be
blocked), except the single approved sheet→dialog depth-2 case above.
