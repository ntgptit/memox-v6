/* MemoX — Reminder local: TimePickerSheet (hour:minute picker bottom sheet). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;

function TimePickerSheet() {
  const { TimeCol } = window.MemoXReminder || {};
  return (
    <window.Scrim node="reminder/picker-scrim">
      <window.Sheet title="Pick reminder time" node="reminder/picker-sheet">
        <div style={{ display: 'flex', gap: 'var(--memox-space-3)', alignItems: 'center', justifyContent: 'center' }}>
          <TimeCol values={['11', '12', '13', '14', '15']} sel="13" />
          <div style={{ fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-extrabold)' }}>:</div>
          <TimeCol values={['00', '15', '30', '45']} sel="00" />
        </div>
        <div style={{ marginTop: 'var(--memox-space-2)' }}><MxButton variant="primary" block node="reminder/picker-done">Done</MxButton></div>
      </window.Sheet>
    </window.Scrim>
  );
}

window.MemoXReminder = window.MemoXReminder || {};
window.MemoXReminder.TimePickerSheet = TimePickerSheet;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const TimePickerSheet = (window.MemoXReminder || {}).TimePickerSheet;
