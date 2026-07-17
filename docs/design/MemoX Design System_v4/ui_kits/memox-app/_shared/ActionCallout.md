# ActionCallout — shared composite

A soft-tinted inline banner: icon + text on a `*-soft` background, with an
optional trailing action. Fills the gap `window.Note` leaves (Note is icon+text
only) for the `import` (dup-warning) and `mode-picker` (not-enough) banners.

```jsx
<window.ActionCallout node="import/dup-warning" icon="warning"
  text="8 cards already exist — import anyway?" />

<window.ActionCallout node="mode-picker/not-enough" icon="info"
  text="This deck needs at least 4 words to play."
  action={<MxButton variant="primary" size="sm" node="mode-picker/add-cards">Add words</MxButton>} />
```

## Props
- `tone` — `warning` (default) | `success` | `error`; picks the `*-soft` /
  `on-*-soft` token pair.
- `node` — `data-mx-node` id.
- `icon` — Material Symbols glyph.
- `text` — the message (fills remaining width).
- `action` — optional trailing element (usually a small `MxButton`).

## Rules
- Row layout, single trailing action only. For a **stacked, two-button** callout
  (flashcard-editor DupBanner) or a tighter `gap-2` semibold status strip
  (account-sync sync banner) keep it screen-local — those are different shapes.
- Icon-and-text with no action and no tint variance → prefer `window.Note`.

## Flutter target
- Component → an `MxActionCallout` widget (tonal `Container` + icon + `Expanded`
  text + optional trailing `MxButton`).
- `tone` → `MxColors` `*Soft`/`on*Soft` roles · `node` → `ValueKey`.
