MxSwitch — a settings on/off toggle; the thumb grows and the track fills with primary when on.

```jsx
<MxSwitch checked={dark} onChange={setDark} node="settings/dark-mode" />
```
---

**When not to use** — Not for actions with side effects that need confirmation (use a button + `ConfirmDialog`). Not for mutually-exclusive choices (use `MxSegmentedControl`). Not where "applies immediately" is unclear.

**States** — off, on, `disabled` (truly disables and blocks `onChange`), `:focus-visible`. Exposes `role="switch"` + `aria-checked` so state is announced. RN: `Switch`/`Pressable`; `disabled` blocks change.

**Content limits / i18n** — No visible text — `ariaLabel` is required; the row's visible label lives outside the switch and carries all i18n. RTL: thumb travel mirrors.

**Do / Don't** — Do pair with an external text label. Don't use for anything that isn't instantly reversible on/off.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
