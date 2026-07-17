# Keyboard focus-order & reading-order contract

> Guideline / spec layer (documentation side of KIT-42-02). Defines the focus and reading order
> every screen must satisfy and how each `Mx*` component participates. Additive only — no
> token/class/name changes. The routing/keyboard-execution harness and focus-order logs are the
> code agent's deliverable; this file is the contract they verify against.
>
> Owner: Design System team · Status: Current (v4, additive-only).

---

## 1. Principles

- **DOM order = reading order = focus order.** Author markup top-to-bottom, leading-to-trailing in
  the visual order a sighted user scans. Never use `tabIndex > 0` to reorder; the only allowed
  values are `0` (in natural order) and `-1` (programmatically focusable / removed from tab order).
- **One heading landmark per screen.** Each screen exposes exactly one top-level heading
  (`role="heading"` / `<h1>` equivalent) so screen-reader users can orient. The app-bar title is
  contextual text, not the body heading — the screen's primary heading lives in the body
  (see KIT-42-01, code side).
- **Every interactive element is reachable and operable by keyboard**, with a visible
  `:focus-visible` ring (`--memox-ring-focus`), and activates on Enter/Space.
- **Focus is never lost.** After any action that removes the focused element (delete, close, submit)
  focus moves to a defined anchor (see overlays guide §2).

---

## 2. Screen-level reading / focus order

Top → bottom for a standard scaffolded screen:

1. **App bar** — leading nav (back/close) → title (non-focusable text) → actions (left-to-right) →
   notification → avatar.
2. **Body** — the screen's primary heading first, then sections in visual order; within a section:
   section header (title, then its trailing action) → list items in order → within a card:
   leading art (non-focusable) → primary text → inline controls.
3. **FAB** — the primary action; placed late in DOM but is a peer of the body; ensure it is reachable
   without wading through a long list (it may be given an early tab stop via focus management, not
   `tabIndex>0`).
4. **Bottom nav** — destinations left-to-right, last.

Overlays (sheet/dialog/menu) take over the focus order while open — see the navigation & overlays
guide §2 (trap, then restore to trigger).

---

## 3. Per-component focus behaviour

| Component | Focusable? | Order / role notes |
| --- | --- | --- |
| MxContextualAppBar | its actions are | leading → title(text, not focusable) → actions → notification → avatar |
| MxButton / MxFab / MxIconButton / MxLink | yes | natural order; Enter/Space; visible focus ring |
| MxChip | yes (interactive) | in row order; Enter/Space |
| MxSegmentedControl | yes | roving focus across 2–3 segments; arrow keys move, Enter selects |
| MxSwitch | yes | Enter/Space toggles; `role="switch"` + `aria-checked` announced |
| MxTextField | yes | label associated; error announced via `role="alert"`; focus ring visible |
| MxSearchDock | yes (input) | focus shown via `focused` ring |
| MxBottomNav | yes | tabs in order; `role="tab"` + `aria-current`/selected on active |
| MxSectionHeader | its action is | title/caption non-focusable; trailing action focusable (Enter/Space) |
| MxCard | only when `interactive` | as a single `role="button"` tab stop; must contain no other focusable child (nested-interactive rule) |
| MxList / MxScaffold | no (structure) | provide the DOM order that becomes focus order |
| MxAvatar / MxIconTile / MxBadge | no | non-interactive; skipped by tab |

---

## 4. Full-task keyboard walkthrough (what to verify)

For each primary task (e.g. Dashboard → Start review → answer → finish) confirm a keyboard-only user
can complete it end to end:

1. Tab reaches every control in the documented order; no keyboard trap (except intended overlay
   traps, which release on close).
2. The primary CTA is reachable and operable; Enter/Space activates it.
3. Opening/closing an overlay moves and restores focus per the overlays guide.
4. State changes (selection count, expand/collapse, loading, success/error) are announced
   (`aria-current`, `aria-expanded`, `aria-busy`, `role="status"`/`"alert"`).
5. Record the resulting focus-order log as the evidence artifact (code-agent deliverable).

---

## 5. Worked walkthrough — the "add a card" task (executable checklist)

A concrete, tab-by-tab keyboard run for a representative primary task (add a flashcard to
a deck). Tick each stop; a failure at any row is a blocking defect. Autofill hints on the
text fields follow `input-autofill.md` and must not disturb this order.

| # | Focus stop (component) | Key(s) | Expected behaviour | Announced |
| --- | --- | --- | --- | --- |
| 0 | *(screen mounts)* | — | Focus rests on the app frame, **not** trapped; first Tab enters the app bar. | Screen primary heading is the first heading landmark. |
| 1 | App-bar leading **close** (`MxIconButton`) | Tab → Enter | Focusable, visible ring; Enter discards + returns to the list (confirm-if-dirty). | `aria-label="Close"`. |
| 2 | *(title text)* | Tab | **Skipped** — non-focusable contextual text. | — |
| 3 | App-bar trailing **Save** action | Tab | Reached but **disabled** until the form is valid; `aria-disabled` so it's announced, and Tab still passes through. | `aria-disabled="true"` while invalid. |
| 4 | **Front** field (`MxTextField`) | Tab → type | Label associated; caret in field; visible focus ring; autofill hint `off` (free text). | Label + any helper read. |
| 5 | **Back** field (`MxTextField`) | Tab → type | Same; the two fields are in DOM/reading order front→back. | Label read. |
| 6 | **Deck** selector (`MxCard interactive` → opens `SelectSheet`) | Tab → Enter | Single tab stop (`role="button"`, no focusable child); Enter opens the sheet. | `aria-haspopup`, `aria-expanded`. |
| 6a | *(sheet open)* deck options | Arrow/Tab → Enter | Focus **traps** in the sheet; Enter selects; Esc closes. | `role="dialog"`, option `aria-selected`. |
| 6b | *(sheet closes)* | — | Focus **restores** to the Deck selector (stop 6), never lost (overlays guide §2). | Selected deck name announced. |
| 7 | **Add** primary CTA (`MxButton`) | Tab → Enter/Space | Now the last body stop; enabled once fields valid; Enter/Space submits. | `role="button"`; on press `aria-busy="true"`. |
| 7a | submit → **error** | — | Focus moves to the first invalid field or the `role="alert"` summary; no trap. | Error announced via `role="alert"`. |
| 7b | submit → **success** | — | Success is announced (`role="status"`); focus moves to a defined anchor (new-row or a fresh empty Front field to add another). | Success status announced. |
| 8 | **Bottom nav** (`MxBottomNav`) | Tab | Destinations reachable last, left-to-right; no earlier stop is skipped or duplicated. | `role="tab"` + `aria-current`. |

**No-trap proof:** from stop 1 you can Tab forward through 8 and Shift+Tab back to 1
without getting stuck (the only intended trap is the deck sheet 6a, which releases on
close). **Completion proof:** a keyboard-only user reaches and activates the single primary
CTA (stop 7) and lands on a defined post-submit anchor (7a/7b). Capture the actual focus
order as the log artifact (code-agent deliverable) and diff it against this table.

---

## 6. Dismiss-keyboard behaviour matrix (KIT-35-04)

How each keyboard-dismissal path behaves for a form with unsaved input (the Card Editor is
the reference). The invariant: **the software keyboard is dismissed without submitting the
form and without discarding typed input, unless the user explicitly confirms a discard.**
Submit happens ONLY through the primary CTA (`flashcard-editor/save`), never as a side effect
of a dismissal gesture. Text fields declare their runtime intent via `data-enter-key-hint` /
`data-input-mode` / `data-validate-on` (see `Field.jsx`); production maps these to React
Native `enterKeyHint` / `inputMode` / `onSubmitEditing` and the OS keyboard.

| Dismiss path | Keyboard | Submits? | Input kept? | Focus after | Production contract |
| --- | --- | --- | --- | --- | --- |
| Hardware BACK (Android) / edge-swipe (iOS), keyboard open | closes | no | yes | stays on field | First BACK only lowers the keyboard (`keyboardWillHide`); the screen is NOT popped. |
| BACK again (keyboard already down) | — | no | only if confirmed | leaves screen | Guarded by the dirty-check (KIT-25-06): `isDirty` → `discard-confirm` overlay; clean → close. Input is discarded ONLY after the user confirms discard. |
| Tap outside a field (inert background) | closes | no | yes | no focused field | Blur runs validate-on-blur for **touched** fields only (`data-validate-on="blur-then-submit"`); a pristine field is never error-flagged. |
| Tap another field | stays | no | yes | new field | Focus moves field→field; the keyboard morphs to the new field's `inputMode`. |
| Scroll / drag the form body | stays\* | no | yes | stays on field | \*iOS interactive-dismiss lowers it on drag; Android keeps it up. Never submits; the sticky SaveBar stays reachable above `--memox-safe-area-bottom`. |
| Return / Done key (`enterKeyHint`) | field-dependent | no\*\* | yes | next field or none | `next` → advances to the next field; `done` → lowers the keyboard. \*\*Only an explicit single-field search/send (`enterKeyHint="search"`/`"send"`) runs its action — a multi-field editor's Done never auto-submits. |
| OS interruption (app switch, call, notification) | closes | no | yes | restores on return | Draft state and caret position are preserved and restored on resume. |

**Verification.** The overlay-dismiss half of this matrix is executable and is exercised by
`tool/a11y/keyboard-walkthrough.mjs` (Esc / overlay close + focus restore; a dirty BACK
surfaces `discard-confirm`). The field-level blur / scroll / enter-key semantics are a runtime
contract — the static kit's text fields are non-focusable design-intent spans (§3 and
`Field.jsx`), so, exactly like the autofill hints in `input-autofill.md`, they are annotated
on the fields and asserted in production rather than executed in the static kit.
