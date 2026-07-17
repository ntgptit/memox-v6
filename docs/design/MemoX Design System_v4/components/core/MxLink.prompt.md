MxLink — a text / navigation link button (accent colour, no filled or block chrome). Use for "go somewhere" affordances, not primary actions.

```jsx
<MxLink node="dashboard/see-all-decks">See all decks</MxLink>
<MxLink icon="open_in_new" trailingIcon={null} href="/help" node="settings/help">Learn more</MxLink>
```

- Renders a `<button>` by default; pass `href` for an `<a>`.
- Trailing `chevron_right` by default (the "more" affordance); pass `trailingIcon={null}` to omit.
- Prefer over `MxButton variant="ghost" block` for see-all / inline navigation — a link shouldn't look like a full-width button.
- Tap target is ≥48px even though the text is visually compact.

---

**When not to use** — Not for primary or confirming actions (use `MxButton`). Not icon-only (use `MxIconButton`). Not inside an already-tappable `MxCard` (nested-interactive — see the constraints matrix).

**States** — default, hover, `:focus-visible` ring, pressed; sizes default / `sm`; renders `<button>` or, with `href`, `<a>`. RN: `Pressable`/`Text`; `href` drives navigation.

**Content limits / i18n** — Inline text with a trailing chevron; keep to a couple of words ("See all"). Tap target stays ≥48px even when the text is visually small. Labels expand across locales — keep them short. RTL: trailing `chevron_right` mirrors to the leading edge.

**Do / Don't** — Do use for see-all / inline navigation. Don't nest a link inside a card that is itself the tap target.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
