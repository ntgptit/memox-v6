/* MemoX shared composite: SelectSheet — a single-select option list inside a
   bottom Sheet. Owns the "title + rows, primary check on the active one" pattern
   that mode-picker (ScopeSheet), library (SortSheet) and settings (ValuePickerSheet)
   previously spelled out row-by-row. Thin wrapper over window.Sheet + window.MenuItem;
   carries no copy of its own — title, each row's icon/label, the per-row node id and
   which one is `selected` are all passed in by the caller. The caller wraps it in a
   window.Scrim when the sheet is presented as an overlay (mode-picker / settings do;
   library renders it inside its existing overlay). */
(function () {

function SelectSheet({ title, node, options }) {
  return (
    <window.Sheet title={title} node={node}>
      {options.map((o) => (
        <window.MenuItem key={o.key} icon={o.icon} label={o.label} node={o.node} selected={o.selected} onClick={o.onClick} />
      ))}
    </window.Sheet>
  );
}

window.SelectSheet = SelectSheet;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const SelectSheet = window.SelectSheet;
