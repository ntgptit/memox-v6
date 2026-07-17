# SelectSheet — shared composite

A single-select option list inside a bottom `Sheet`: an uppercase title and a
column of rows, each an icon + label, with a primary-tinted check on the active
one. Owns the pattern that `mode-picker` (ScopeSheet), `library` (SortSheet) and
`settings` (ValuePickerSheet) previously spelled out row-by-row.

```jsx
// mode-picker: presented as an overlay → wrap in a Scrim
<window.Scrim node="mode-picker/scope-scrim">
  <window.SelectSheet title="Card source" node="mode-picker/scope-sheet"
    options={[
      { key: 'srs', icon: 'schedule', label: 'By schedule', node: 'mode-picker/scope-srs', selected: true },
      { key: 'all', icon: 'apps', label: 'All cards', node: 'mode-picker/scope-all' },
    ]} />
</window.Scrim>

// library: rendered inside the screen's existing overlay → no Scrim here
<window.SelectSheet title="Sort by" node="library/sort-sheet"
  options={[
    { key: 0, icon: 'sort_by_alpha', label: 'Alphabetical A → Z', node: 'library/sort-0', selected: true },
    { key: 1, icon: 'sort_by_alpha', label: 'Alphabetical Z → A', node: 'library/sort-1' },
  ]} />
```

## Props
- `title` — uppercase section title (from ARB).
- `node` — `data-mx-node` id for the sheet surface.
- `options[]` — `{ key, icon, label, node, selected, onClick }` per row.

## Rules
- One shared layout; **per-row content, node ids and which row is `selected`
  stay at the call site** — this composite carries no copy of its own.
- The active-row check is the `MenuItem` `selected` prop (primary-tinted `check`);
  do not re-add trailing check markup at the call site.
- Wrap in a `Scrim` at the call site only when the sheet is a standalone overlay
  (mode-picker / settings); library renders it inside its own overlay.
- Sheets that also carry non-select actions (e.g. library PairPickerSheet's
  "Add language") are **not** SelectSheets — keep those on `MenuItem` directly.

## Flutter target
- Component → an `MxSelectSheet<T>` composite (`presentation/shared/composites/`),
  presented with `showMxSheet`.
- `options[]` → `List<MxSelectOption<T>>` (`value` + `icon` + `label`); `selected`
  → `value == selected` → `MxListRow.selected`; each row pops then calls
  `onSelect(value)`. `node` → `ValueKey`.
