MxSectionHeader — labels a group of cards; title + optional caption on the left, a tappable text action on the right.

```jsx
<MxSectionHeader node="dashboard/decks-head" title="Your decks" caption="6 active" action="See all" onAction={...} />
```
---

**When not to use** — Not the top app bar (use `MxContextualAppBar`). Not a card title. Not for a single item.

**States** — title only, title+`caption`, with a trailing `action` (fires on click AND Enter/Space; needs `actionLabel` when the action content is non-text); action has `:focus-visible`. RN: `View` + `Text` + `Pressable` action.

**Content limits / i18n** — Title one line; caption short; action ≤ 2 words. All three expand across locales — allow the title to wrap or truncate and keep the action short. RTL: the trailing action moves to the logical start edge.

**Do / Don't** — Do use a single "See all"-style trailing action. Don't add multiple actions; don't rely on it as a page-heading landmark on its own.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
