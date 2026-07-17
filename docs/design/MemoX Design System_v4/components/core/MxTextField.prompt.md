MxTextField — inline text input. Base class `field`. Bare by default (just the token-styled input, for editor fields / game answers / paste boxes); pass `label`, `helper` or `error` to get a full labelled field group with an accessible name, description and validation state.

```jsx
// Bare (single-line):
<MxTextField value={term} onChange={setTerm} placeholder="Enter a term" node="editor/term" />

// Labelled + validated:
<MxTextField
  label="Email"
  type="email"
  inputMode="email"
  required
  value={email}
  onChange={setEmail}
  error={emailError}          // sets aria-invalid + role="alert"; hides helper
  helper="We never share it." // shown when there is no error
  node="account/email"
/>

// Multi-line:
<MxTextField multiline rows={2} placeholder="Enter the meaning" node="editor/meaning" />
```

Accessibility: with a `label` the input is wired via `htmlFor`/`id`; without one it takes `ariaLabel` (falling back to `placeholder`). `required` sets `aria-required` and a visual `*`; `error` sets `aria-invalid` and announces via `role="alert"`. Use `type` for the input kind and `inputMode` for the on-screen keyboard. Never hard-code colors — the error/disabled states are token-driven modifiers (`field--error`, `field--disabled`).

---

**When not to use** — Not for choosing from a fixed set (use segmented / chips / a menu). Not for on/off (use `MxSwitch`). When `bare`, the visible box belongs to the surrounding container, not this component.

**States** — empty, filled, focus, `error` (`aria-invalid` + `role="alert"`, hides helper), `disabled` (`field--disabled`), `multiline`. Read-only is not yet a distinct state (see constraints matrix / KIT-18-02). RN: `TextInput`.

**Content limits / i18n** — Label / helper / error text expand — reserve vertical space and never truncate an error. `type`/`inputMode` pick the keyboard; support Vietnamese diacritics and IME composition (don't commit on each keystroke). Externalise `label`/`helper`/`error`/`placeholder`. RTL: `align` uses logical `start`/`center`.

**Do / Don't** — Do give every field a `label` or `ariaLabel`. Don't use the placeholder as the only label; don't block IME composition.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; read-only state planned — see KIT-18-02).
