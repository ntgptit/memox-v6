MxSegmentedControl — a pill of 2–3 mutually-exclusive segments; the active one gets a raised surface.

```jsx
<MxSegmentedControl node="stats/range" value={range} onChange={setRange} block
  segments={[{value:'week',label:'Week'},{value:'month',label:'Month'},{value:'year',label:'Year'}]} />
```
---

**When not to use** — Not for more than 3 options (use tabs / a menu). Not for multi-select (use `MxChip`). Not for on/off (use `MxSwitch`).

**States** — per-segment active / inactive (active gets a raised surface); `block`; segment `:focus-visible`. Per-segment disabled is not modeled (see constraints matrix). RN: `Pressable` segments with roving focus.

**Content limits / i18n** — 2–3 segments, each one short word, `nowrap`; the full control must fit one row at 320px width. With text expansion prefer icon+short-label or drop to 2 segments — never truncate a segment. RTL: segment order mirrors.

**Do / Don't** — Do keep segment labels equal in weight and length. Don't exceed 3 segments; don't mix icon-only and text segments that misalign.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
