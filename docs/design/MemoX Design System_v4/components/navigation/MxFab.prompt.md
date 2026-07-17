MxFab — the primary screen action; extended with a label, or round when icon-only.

```jsx
<MxFab node="library/new-deck" icon="add" label="New deck" />
<MxFab node="study/shuffle" icon="shuffle" round />
```
---

**When not to use** — Not for secondary actions. Not more than one per screen. Not for destructive actions.

**States** — extended (icon+`label`), `round` (icon-only, requires `ariaLabel`), `disabled`, `:focus-visible`; parks above the bottom nav and honours the bottom safe-area. RN: `Pressable`, elevated.

**Content limits / i18n** — Label is one short verb phrase ("New deck"), `nowrap`; the round form has no text. The extended label expands across locales — allow width growth or collapse to `round` on narrow devices. RTL: icon/label order and the FAB's resting corner mirror to the logical end.

**Do / Don't** — Do use for the single primary create/action. Don't stack multiple FABs; don't ship a `round` FAB without `ariaLabel`.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
