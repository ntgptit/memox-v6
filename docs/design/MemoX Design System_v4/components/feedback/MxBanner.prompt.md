MxBanner — the one inline tone banner: a non-blocking message that sits in the content column, tinted by tone (info / success / warning / error) with a leading tone icon, a title + optional body, and an optional trailing action. For a blocking decision use `MxDialog`; for progress use `MxProgress`.

```jsx
<MxBanner tone="warning" title="Offline"
  action={<MxLink node="sync/retry">Retry</MxLink>}
  node="sync/offline">
  Changes are saved on this device and will sync when you reconnect.
</MxBanner>
```

**Anatomy** — `banner` (tinted surface) → `banner__icon` (tone glyph) + `banner__content` (`banner__title` + `banner__body`) + optional `banner__action`.

**Variants (tone)** — `info` (base), `success`, `warning`, `error`. Tone sets the tint (`*-soft` bg + `on-*-soft` text), the default icon, and the live-region role. `icon` overrides the glyph; `action` adds a trailing affordance.

**States** — static message; the optional `action` carries its own hover/press/`:focus-visible`. info/success announce politely (`role="status"`), warning/error assertively (`role="alert"`). No dismiss state built in — the parent controls mounting. RN: a `View` with `accessibilityLiveRegion` matching the tone.

**When not to use** — Not for a blocking decision (use `MxDialog`). Not for transient toast-style confirmation that auto-dismisses off-screen. Not for field-level validation (use `MxTextField` `error`). Not for progress (use `MxProgress`).

**Content limits / i18n** — Title is one short line; body wraps and must never clip; keep to one message + at most one action. Budget 30–50% text growth. Meaning must survive without color (icon + text + role). RTL: icon leads the logical start, action mirrors to the logical end.

**Do / Don't** — Do let tone match severity and keep the message to one idea with a single action. Don't rely on color alone to convey severity, and don't use a banner where a blocking decision or a field error is the right surface.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
