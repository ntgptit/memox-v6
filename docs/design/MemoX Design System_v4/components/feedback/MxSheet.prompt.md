MxSheet — the one bottom sheet. A surface that rises from the bottom edge for a set of options, a short form, or secondary content: scrim, drag handle, optional title, and a height-capped scrollable body that honours the bottom safe-area. Pass content by slot; never build a per-feature sheet.

```jsx
<MxSheet node="card/actions" title="Card actions" onDismiss={close}>
  <MxMenu node="card/actions/menu" items={[
    { id: 'edit', icon: 'edit', label: 'Edit card' },
    { id: 'move', icon: 'drive_file_move', label: 'Move to deck…' },
    { id: 'delete', icon: 'delete', label: 'Delete', destructive: true },
  ]} onSelect={run} />
</MxSheet>
```

**Anatomy** — `sheet-layer` (pins to the bottom edge, paints `sheet__scrim`) → `sheet` → `sheet__handle` (decorative grabber) + optional `sheet__title` + `sheet__body` (scrolls, reserves `--memox-safe-area-bottom`). Max 3 nested surfaces.

**Variants** — One canonical surface. `title` optional; height via the base cap or a `maxHeight` override; `dismissible` toggles Escape/scrim dismissal. No tonal variants.

**States** — `open`/closed (closed renders nothing); sheet focused on open (`tabIndex=-1`); body scrolls when content exceeds the cap; safe-area padding at the bottom. Enter/exit slide honours reduced motion. RN: `Modal` anchored to bottom, safe-area inset applied.

**When not to use** — Not for a single blocking decision (use `MxDialog`). Not for a bare list of item actions with no header when a lightweight anchored `MxMenu` fits. Not for persistent inline messaging (use `MxBanner`). Not as a navigation drawer.

**Content limits / i18n** — Title is one short line; the body must scroll, never grow past the cap or clip; keep to one task. Budget 30–50% text growth. RTL: handle stays centered; content and the title align to the logical start; children own direction.

**Do / Don't** — Do let the body own its scroll and keep the sheet to a single task. Don't nest a sheet inside a dialog, and don't put a full multi-step flow in a sheet — promote it to a screen.

**Meta** — v4 · Owner: Design System team · Status: Current (frozen, additive-only; no deprecation).
