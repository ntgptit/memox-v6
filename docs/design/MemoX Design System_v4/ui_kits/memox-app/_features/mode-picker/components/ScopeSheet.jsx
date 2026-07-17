/* MemoX — Mode-picker local: ScopeSheet (card-source dropdown bottom sheet). */
(function () {

function ScopeSheet() {
  const opts = [
    { icon: 'schedule', label: 'By schedule', sel: true, id: 'srs' },
    { icon: 'apps', label: 'All cards', sel: false, id: 'all' },
    { icon: 'hourglass_empty', label: 'Unlearned only', sel: false, id: 'unlearned' },
  ];
  return (
    <window.Scrim node="mode-picker/scope-scrim">
      <window.SelectSheet title="Card source" node="mode-picker/scope-sheet"
        options={opts.map((o) => ({ key: o.id, icon: o.icon, label: o.label, node: 'mode-picker/scope-' + o.id, selected: o.sel }))} />
    </window.Scrim>
  );
}

window.MemoXModePicker = window.MemoXModePicker || {};
window.MemoXModePicker.ScopeSheet = ScopeSheet;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ScopeSheet = (window.MemoXModePicker || {}).ScopeSheet;
