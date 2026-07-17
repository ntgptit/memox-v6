/* MemoX — Settings local: ValuePickerSheet (words-per-round picker bottom sheet). */
(function () {

function ValuePickerSheet() {
  return (
    <window.Scrim node="settings/picker-scrim">
      <window.SelectSheet title="Words per round" node="settings/picker-sheet"
        options={['5', '10', '20'].map((v, i) => ({ key: v, icon: i === 0 ? 'check' : 'circle', label: v + ' words', node: 'settings/words-' + v, selected: i === 0 }))} />
    </window.Scrim>
  );
}

window.MemoXSettings = window.MemoXSettings || {};
window.MemoXSettings.ValuePickerSheet = ValuePickerSheet;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ValuePickerSheet = (window.MemoXSettings || {}).ValuePickerSheet;
