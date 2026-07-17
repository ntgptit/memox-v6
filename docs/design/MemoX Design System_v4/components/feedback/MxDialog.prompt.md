MxDialog — the one centered modal decision surface. A scrim over the app plus a raised panel that holds a title, body, and a right-aligned action row. Use it for a single blocking decision (confirm, discard, rename); pass content by slot and never build a per-feature modal.

```jsx
<MxDialog node="deck/delete" title="Delete this deck?"
  actions={<><MxButton variant="ghost" onClick={cancel}>Cancel</MxButton>
             <MxButton variant="primary" danger onClick={confirm}>Delete</MxButton></>}
  onDismiss={cancel}>
  All 142 cards in “Korean Basics” will be permanently removed.
</MxDialog>
```

**Anatomy** — `dialog-layer` (centers the panel, paints `dialog__scrim`) → `dialog` panel → `dialog__title` (the accessible name) + `dialog__body` + `dialog__actions` (right-aligned). Max 3 nested surfaces: layer + panel + any single inner control.

**Variants** — One canonical surface (no visual variants). Behavioural switch: `dismissible` (default) vs required-decision (`dismissible={false}` removes Escape/scrim dismissal). Tone is carried by the action buttons (`danger`), never by the panel.

**States** — `open`/closed (closed renders nothing); panel focused on open (`tabIndex=-1`, no visible ring); actions inherit MxButton hover/press/`:focus-visible`/disabled. Enter/exit fade honours reduced motion. RN: `Modal` with `transparent` + focus trap.

**When not to use** — Not for non-blocking feedback (use `MxBanner`). Not for a list of actions on an item (use `MxMenu`) or a set of options / long content (use `MxSheet`). Not for transient status (use `MxProgress`). Never stack two dialogs.

**Content limits / i18n** — `title` is one short line; body wraps and must never clip; keep to one decision and ≤ ~2 actions. Budget 30–50% text growth; actions wrap to a second row rather than overflow. RTL: actions mirror to the logical end; direction-neutral panel, children own direction.

**Do / Don't** — Do keep exactly one primary action and phrase the title as the decision. Don't use a dialog for routine confirmation of instantly-reversible toggles, and don't disable dismissal unless the decision is genuinely required.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
