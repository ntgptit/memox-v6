MxBadge — a compact count or status pill; primary by default, `tone` for semantic colors, `soft` for tinted, `dot` for a bare indicator.

```jsx
<MxBadge tone="error">12</MxBadge>
<MxBadge tone="success" soft>New</MxBadge>
<MxBadge tone="warning" dot />
```
---

**When not to use** — Not for interactive filters (use `MxChip`). Not for long text — counts / one-word status only. Not a button.

**States** — solid (default, primary), `soft` (tinted), `dot` (bare indicator); tones `success`/`warning`/`error`. Non-interactive. RN: `View` + `Text`; `dot` is a bare `View`.

**Content limits / i18n** — Numeric counts should be capped at the call site (99+ rule); text ≤ ~12 chars / one token, no wrapping. Compose count+noun ("3 new") at the call site, not inside the badge, so it can be pluralised/localised. RTL-neutral.

**Do / Don't** — Do use `dot` for a binary "has new". Don't encode meaning by colour alone — keep an adjacent text/icon anchor.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
