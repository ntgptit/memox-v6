MxAvatar — a circular user/entity avatar; shows the image, or initials derived from `name`.

```jsx
<MxAvatar name="Linh Tran" node="settings/avatar" ring />
<MxAvatar src="/me.jpg" size="lg" node="profile/avatar" />
```
---

**When not to use** — Not for brand/app imagery or decorative pictures. Not as a standalone tap target (wrap it in an action if it must be tappable). Not to convey status or counts — use `MxBadge`.

**States** — image (with `src`), initials-fallback (no `src`, derived from `name`), optional `ring`; sizes `sm`/`md`/`lg`; `variant="accent"`. Non-interactive, so no hover/focus/disabled of its own. RN: image → `<Image>`, initials → `<Text>`; `ring` is a bordered `View`.

**Content limits / i18n** — Initials use up to 2 words of `name`; long names never overflow (only initials render). For scripts without case/initials (e.g. CJK) fall back to the first glyph. RTL-neutral (circular, no directional layout); localize `name` upstream.

**Do / Don't** — Do pass `name` even when `src` is set (alt + fallback). Don't render more than 2 initials; don't rely on `variant` colour alone to identify a user.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
