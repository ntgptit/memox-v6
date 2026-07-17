MxList — the one vertical list wrapper for any stack of cards or rows (decks, subdecks, flashcards, search results). It owns the standard 12px inter-card gap (`--memox-space-3`) so every list in the app spaces its items identically. Always wrap a card list in this instead of dropping cards straight into the scroll body, whose section gap is the larger 24px.

```jsx
<MxList node="library/decks">
  {decks.map((d) => <DeckCard key={d.id} deck={d} />)}
</MxList>
```

Pass `gap` (any spacing token) to override the default, e.g. `gap="var(--memox-space-2)"` for a denser list. Never hard-code a pixel gap.

---

**When not to use** — Not for a single item. Not for form-field stacks (use section spacing). Not a grid.

**States** — default 12px gap (`--memox-space-3`); `gap` override with any spacing token. Non-interactive wrapper. An empty list renders an explicit empty-state child, never an empty `MxList`. RN: `FlatList`/`View` with a virtualised item stack.

**Content limits / i18n** — No inherent max item count — must stay virtualisable in RN for long lists. Direction-neutral (vertical stack); items handle their own i18n/RTL.

**Do / Don't** — Do wrap every card list in `MxList`. Don't hard-code a pixel gap; don't drop cards straight into the scroll body (that uses the larger 24px section gap).

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
