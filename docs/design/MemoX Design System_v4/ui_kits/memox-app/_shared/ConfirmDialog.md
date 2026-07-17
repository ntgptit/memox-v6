# ConfirmDialog — shared composite

A centered confirm overlay: `Scrim` (dimmed backdrop) + `Dialog` (icon, title,
body, action row). Carries no copy of its own — the caller passes every string,
node id and action. Lives in `_shared/` because it is used by **6 sites across 3
screens** (study-session exit + save-error; deck-settings delete / reset /
deck-delete; languages remove-pair).

```jsx
<window.ConfirmDialog align="center" scrimNode="deck-settings/delete-scrim"
  icon="delete" tone="error" title="Delete this card?"
  text="The card will be removed from this deck. This can't be undone."
  dialogNode="deck-settings/delete-dialog"
  actions={<React.Fragment>
    <MxButton variant="ghost" block node="deck-settings/delete-cancel">Cancel</MxButton>
    <MxButton variant="primary" danger block node="deck-settings/delete-ok">Delete</MxButton>
  </React.Fragment>} />
```

## Props
- `align` — Scrim alignment; `center` (default) for dialogs, `end` for sheets.
- `scrimNode` / `dialogNode` — `data-mx-node` ids for the backdrop and the dialog.
- `icon` — Material Symbols name shown in the dialog header.
- `tone` — `warning` | `error` (drives the icon tint via `Dialog`); `null` = neutral.
- `title` / `text` — heading + body copy.
- `actions` — the button row (typically a ghost cancel + a primary/`danger` confirm).

## States — risk classification (KIT-31-01)
The dialog itself is static; its meaning comes from `tone` + `actions`. Three risk tiers,
each with a fixed tone so the rubric and the shipped dialogs stay in sync:

| Tier | Meaning | `tone` | Confirm button | Examples in the kit |
|---|---|---|---|---|
| **undoable** | Fully reversible; the confirm exists only to prevent an accidental tap. Recoverable with no data loss. | `null` (neutral) or `warning` | `variant="primary"` (no `danger`) | discard unsaved edits (draft only) |
| **destructive-recoverable** | Significant but the underlying data is not erased — state can be re-derived or resumed. | `error` | `variant="primary" danger` | leave the session (progress lost for this run), reset progress (scheduling erased, cards kept) |
| **destructive** | Permanent data loss; nothing to re-derive. | `error` | `variant="primary" danger` | delete card/deck, remove language pair |

Note: leave-session and reset-progress ship as `tone="error"` + `danger` (see
`study-session/components/ExitDialog.jsx`, `_shared/DeckResetConfirmDialog.jsx`) because they
destroy run/scheduling state — the rubric row above matches that implementation. The `warning`
tone is reserved for the undoable tier when a softer cue than neutral is wanted.

## Rules
- Exactly one primary/confirm action; cancel is always `variant="ghost"` (the always-safe exit).
- Any destructive or destructive-recoverable confirm → `tone="error"` + `danger` on the confirm button.
- Never hardcode copy inside `ConfirmDialog`; pass it from the calling screen so
  l10n and node ids stay owned by that screen.

## Flutter target
- Component → a `showMxConfirmDialog(...)` helper / shared confirm dialog widget
  (Material `showDialog` hosting an `MxCard`-styled body).
- `icon` → `MxIconTile`/Material symbol · `tone` → `MxColors` role · `title`/`text`
  → `MxTypography.title` / `.body` · `actions` → `MxButton` row.
- `scrimNode` / `dialogNode` → `ValueKey`s on the barrier + dialog (parity).
