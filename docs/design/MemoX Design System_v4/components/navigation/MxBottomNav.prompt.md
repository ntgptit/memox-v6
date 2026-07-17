MxBottomNav — the persistent bottom tab bar; the active item gets a tinted pill behind its icon.

```jsx
<MxBottomNav node="shell/bottom-nav" value={tab} onChange={setTab}
  items={[{id:'home',label:'Today',icon:'today'},{id:'library',label:'Library',icon:'style'}]} />
```
---

**When not to use** — Not for more than 5 destinations. Not for in-screen actions (use `MxFab`/`MxButton`). Not for wizard steps or a filtered subset that appears/disappears.

**States** — per-item active / inactive (active shows a tinted pill); active exposes `aria-current`/selected to AT (see KIT-24-02); per-item `:focus-visible`. No disabled item. RN: tab bar, `accessibilityRole="tab"`, honours bottom safe-area inset (`--memox-safe-area-bottom`).

**Content limits / i18n** — 3–5 items, one short word each, `icon` required, `nowrap`. Labels expand in other locales — keep to a single word. RTL: item order mirrors.

**Do / Don't** — Do keep 3–5 fixed destinations. Don't conditionally hide/disable a tab; don't duplicate a tab as an app-bar action.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; aria-current wiring tracked in KIT-24-02).
