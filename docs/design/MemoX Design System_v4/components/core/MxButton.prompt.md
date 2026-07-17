MxButton — the standard text button; `variant` sets emphasis (filled primary → tonal secondary → outline → ghost text).

```jsx
<MxButton variant="primary" icon="play_arrow" block node="dashboard/start-review">Start review</MxButton>
<MxButton variant="outline" node="deck/edit">Edit deck</MxButton>
```

`block` fills width; `danger` recolors to error; `sm`/`lg` sizes.
---

**When not to use** — Not for "go somewhere" / see-all navigation (use `MxLink`). Not icon-only (use `MxIconButton`). Not the screen's floating primary action (use `MxFab`). At most one `primary` button per screen.

**States** — variants `primary`/`secondary`/`outline`/`ghost`/`contrast`; `danger`; sizes `sm`/`lg`; `block`; `disabled`; hover / active / `:focus-visible` (branded focus ring, `--memox-ring-focus`). No built-in loading state — the parent disables the button and shows progress while submitting. RN: `Pressable`; focus ring maps to platform focus.

**Content limits / i18n** — Single line, label does not wrap; keep to ≤ ~24 chars / 1–2 words; icon optional. Budget 30–50% text growth for other locales — prefer `block` or an auto-width container, never a width fixed to the English string. RTL: leading `icon` becomes trailing under `dir=rtl` via logical order.

**Do / Don't** — Do keep exactly one primary CTA per screen. Don't fake a link with `ghost`+`block`; don't express destructive intent with a variant — use `danger`.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
