MxMenu — the one action menu: a vertical list of labelled actions (a raised popover, or embedded in an `MxSheet`). Each item has an optional leading icon and can be selected, destructive, or disabled; overflow scrolls inside the menu. Pass items as data, never hand-build rows.

```jsx
<MxMenu node="deck/sort" ariaLabel="Sort decks" onSelect={setSort} items={[
  { id: 'recent', icon: 'schedule', label: 'Recently studied', selected: true },
  { id: 'name',   icon: 'sort_by_alpha', label: 'Name (A–Z)' },
  { id: 'due',    icon: 'event', label: 'Most due' },
  { id: 'archive', icon: 'inventory_2', label: 'Archived only', disabled: true },
  { id: 'delete', icon: 'delete', label: 'Delete deck', destructive: true },
]} />
```

**Anatomy** — `menu` (raised surface, scrolls past the height cap) → `menu__item` rows, each = optional icon + `menu__item-label`. A selected item with no icon renders a `check`.

**Variants (item states)** — default; `selected` (tinted row, `aria-current`, bold); `destructive` (error color, error-soft hover); `disabled` (dimmed, unfocusable, blocks select). Item states compose; the menu surface itself has no variants.

**States** — per item: rest / hover / active / `:focus-visible` (branded ring) / selected / destructive / disabled; menu-level: overflow scroll when items exceed the cap. RN: list of `Pressable` rows; disabled maps to `disabled` + `accessibilityState`.

**When not to use** — Not for a single blocking decision (use `MxDialog`). Not for a persistent inline message (use `MxBanner`). Not as primary on-screen navigation (use `MxBottomNav`). Not for one-of-a-few inline choices (use `MxSegmentedControl`).

**Content limits / i18n** — Labels are single-line and truncate; keep the list short (group or scroll rather than sprawl); at most one `selected` per exclusive set. Budget 30–50% text growth. RTL: icon leads the logical start; rows align to the logical start.

**Do / Don't** — Do use `destructive` for the delete-style action and keep it last; do disable (not hide) an action that is temporarily unavailable when its absence would confuse. Don't express destructive intent with color alone outside this flag, and don't put more than one primary/selected item per exclusive group.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
