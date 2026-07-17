MxProgress — the one progress indicator. A linear bar or an inline spinner, determinate (`value` 0–100) or indeterminate (omit `value`). Use it for ongoing work; for a message use `MxBanner`, for a blocking wait pair it inside `MxDialog`/`MxSheet`.

```jsx
// Determinate import bar
<MxProgress value={64} ariaLabel="Importing deck" node="import/progress" />

// Indeterminate inline spinner (e.g. a submitting button/section)
<MxProgress variant="spinner" ariaLabel="Saving" node="editor/saving" />
```

**Anatomy** — bar: `progress` → `progress__track` → `progress__fill` (width = `value`% when determinate, sliding when not). spinner: `progress.progress--spinner` → `progress__spinner` (rotating ring).

**Variants** — `bar` (base) and `spinner`. Orthogonal mode: determinate (`value` given) vs indeterminate (`value` omitted). The spinner is always indeterminate motion but still reports `value` to AT when supplied.

**States** — determinate (fill/arc reflects value) and indeterminate (looping). role="progressbar" with aria-valuenow when determinate. Looping motion settles under `prefers-reduced-motion`. RN: `accessibilityRole="progressbar"` + `accessibilityValue`.

**When not to use** — Not for a persistent status message (use `MxBanner`). Not as a button's own affordance (MxButton owns its `loading` spinner). Not for empty-state or long multi-step flows where explicit step UI is clearer.

**Content limits / i18n** — No visible text — `ariaLabel` names the task and carries all i18n. Determinate values are clamped to 0–100. Direction-neutral; the bar fills from the logical start under RTL.

**Do / Don't** — Do prefer a determinate bar whenever progress is knowable, and give every instance a task-specific `ariaLabel`. Don't leave an indeterminate spinner spinning with no surrounding context, and don't animate against a user's reduced-motion preference.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
