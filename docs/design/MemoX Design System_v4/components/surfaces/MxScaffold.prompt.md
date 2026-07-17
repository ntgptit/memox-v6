MxScaffold — the root phone shell every screen mounts into; slots an app bar, scrolling body, bottom nav and an optional FAB. Use it once per screen.

```jsx
<MxScaffold
  node="dashboard/screen"
  appBar={<MxContextualAppBar variant="root" title="Today" />}
  bottomNav={<MxBottomNav items={tabs} value="home" onChange={setTab} />}
  fab={<MxFab icon="add" label="New deck" />}
>
  {/* cards, sections… */}
</MxScaffold>
```

- `flush` drops body side-padding for full-bleed lists.
- Body scrolls; app bar and nav stay fixed.
---

**When not to use** — Once per screen only — never nested. Not for overlays/sheets/dialogs (those layer above the scaffold — see the navigation & overlays guide).

**States** — with / without `appBar`, `bottomNav`, `fab`; `flush` (no body side-padding). Body scrolls while bars stay fixed; honours top and bottom safe-areas. RN: safe-area frame + fixed header/footer + scrolling body.

**Content limits / i18n** — Body accepts arbitrary content and must handle empty (render an empty-state), overflow (scroll) and short viewports (min-height stress). Uses logical padding so the whole frame mirrors under `dir=rtl`.

**Do / Don't** — Do mount every screen in exactly one `MxScaffold`. Don't nest scaffolds; don't place the FAB inside the body.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
