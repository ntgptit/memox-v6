MxChip — a filter or choice chip; outlined when idle, primary-tinted when `selected`.

```jsx
<MxChip label="Due today" icon="schedule" selected node="library/filter-due" />
<MxChip label="All" node="library/filter-all" />
```
---

**When not to use** — Not for on/off settings (use `MxSwitch`). Not for 2–3 mutually-exclusive views (use `MxSegmentedControl`). Not a primary action.

**States** — idle (outlined), `selected` (tinted); variants `accent`/`ghost`; with / without leading `icon`; interactive (`onClick`). Disabled is not yet a modeled state (see constraints matrix / KIT-18-04) — omit or hide an unavailable chip rather than graying it. RN: `Pressable` pill.

**Content limits / i18n** — One short label, `nowrap`; keep ≤ ~16 chars; an overflowing chip row scrolls horizontally rather than wrapping/truncating mid-word. Labels expand in other locales — rely on the scroll row. RTL: leading `icon` mirrors to the trailing edge via logical properties.

**Do / Don't** — Do keep chip labels parallel and short. Don't build destructive/multi-select flows from chips; don't invent a raw-colour disabled look (no disabled token yet).

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; disabled state planned — see KIT-18-04).
