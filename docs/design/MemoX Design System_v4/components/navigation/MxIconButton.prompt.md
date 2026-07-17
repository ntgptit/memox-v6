MxIconButton — a round, icon-only action; transparent by default, `filled` (surface chip) or `primary` (tinted) variants.

```jsx
<MxIconButton icon="arrow_back" node="study/back" ariaLabel="Back" />
<MxIconButton icon="bolt" variant="primary" node="dashboard/streak" />
```
---

**When not to use** — Not for primary text actions (use `MxButton`). Not when a visible label is essential to comprehension. Not as a navigation destination (use `MxBottomNav`).

**States** — variants `plain`/`filled`/`primary`; size `sm`; hover / active / `:focus-visible` ring. No disabled variant is modeled — omit the action instead of showing a dead control. RN: `Pressable`, min 44×44 target, `accessibilityLabel` required.

**Content limits / i18n** — Exactly one icon; `ariaLabel` is REQUIRED and must be a human label ("Back", "More options"), never the raw ligature. Externalise/translate `ariaLabel`. RTL: directional icons (`arrow_back`, `chevron_*`) must mirror; symmetric icons don't.

**Do / Don't** — Do supply a human `ariaLabel`. Don't leak the ligature to AT; don't place more than 2 in an app bar.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
