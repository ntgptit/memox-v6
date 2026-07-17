MxIconTile — a soft rounded square holding one Material Symbol; the leading visual for deck rows and stat cards.

```jsx
<MxIconTile icon="style" tone="accent" node="library/deck-icon" />
```

Tones: default (primary), `accent`, `success`, `warning`, `error`. `solid` fills with the strong primary; `size="lg"` for hero use.
---

**When not to use** — Not an interactive button — it's decorative leading art. Not for user avatars (use `MxAvatar`). Not for status/counts (use `MxBadge`).

**States** — tones default/`accent`/`success`/`warning`/`error`; size `lg`; `solid` fill. Non-interactive. RN: `View` + icon `Text`.

**Content limits / i18n** — Exactly one Material Symbol, no text. Direction-neutral for symmetric glyphs; a directional glyph inside must mirror under RTL. `tone` is decorative — never the sole carrier of meaning.

**Do / Don't** — Do use as deck / stat leading art. Don't rely on `tone` colour alone to convey meaning; don't make the tile the tap target.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
