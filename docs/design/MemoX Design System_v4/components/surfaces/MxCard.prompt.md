MxCard — the rounded content surface everything sits on. Elevated by default; `variant` switches to flat, muted, solid primary, or soft-primary tint.

```jsx
<MxCard node="dashboard/due-summary" variant="primary" interactive>
  <div className="section-head__title">142 cards due</div>
</MxCard>
```

Variants: `flat` (hairline), `muted` (sunken), `primary` (brand solid), `primary-soft` (tint). `interactive` adds lift + press scale.
---

**When not to use** — Not as a button substitute unless `interactive`. Not nesting another interactive card or control inside an interactive card (nested-interactive — see the constraints matrix). Not to space a card list (use `MxList`).

**States** — variants `elevated`/`flat`/`muted`/`primary`/`primary-soft`; padding `sm`/`md`/`lg`; `interactive` (hover + press scale, `:focus-visible` when it carries `role="button"`). RN: `View`, or `Pressable` when interactive.

**Content limits / i18n** — Holds arbitrary children; must handle long text (wrap, never clip) and sparse/dense content via a sensible min-height. Content-driven height — never fixed to the English string. Direction-neutral container; children own direction.

**Do / Don't** — Do set `interactive` + role only when the whole card is one tap target. Don't put a button/link/switch inside an interactive card — split into a non-interactive card with explicit child controls.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
