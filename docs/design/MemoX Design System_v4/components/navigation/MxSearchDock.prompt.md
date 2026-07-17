MxSearchDock — the pill-shaped search field at the top of list screens.

```jsx
<MxSearchDock node="library/search-dock" placeholder="Search decks & cards"
  trailing={<MxIconButton icon="tune" size="sm" node="library/filter" />} />
```

`focused` shows the focus ring; `flat` uses the muted (un-elevated) treatment.
---

**When not to use** — Not for the app-bar search mode (use `MxContextualAppBar variant="search"`). Not as a generic form input (use `MxTextField`).

**States** — idle, `focused` (ring), `flat` (muted / un-elevated), with a `trailing` control. The input suppresses the native outline, so keyboard focus must be shown via the `focused` ring. RN: `TextInput` in a pill, `accessibilityRole="search"`.

**Content limits / i18n** — Placeholder short; at most one `trailing` control (e.g. filter). Externalise the placeholder; it expands across locales. RTL: the leading search glyph mirrors to the logical start edge.

**Do / Don't** — Do keep a single trailing control. Don't reuse it for inline form fields.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
