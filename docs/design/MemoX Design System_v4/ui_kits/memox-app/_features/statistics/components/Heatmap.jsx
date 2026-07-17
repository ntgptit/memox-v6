/* MemoX — Statistics local: Heatmap (14-week study calendar grid). */
(function () {

function Heatmap() {
  return (
    <div style={{ display: 'flex', gap: 'var(--memox-space-1)', overflowX: 'auto' }}>
      {Array.from({ length: 14 }).map((_, w) => (
        <div key={w} style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)' }}>
          {Array.from({ length: 7 }).map((_, d) => {
            const op = [0.08, 0.25, 0.45, 0.7, 1][(w * 7 + d * 3) % 5];
            return <div key={d} style={{ width: 'var(--memox-size-xs)', height: 'var(--memox-size-xs)', borderRadius: 'var(--memox-radius-xs)', background: 'var(--memox-viz-1)', opacity: op }} />;
          })}
        </div>
      ))}
    </div>
  );
}

window.MemoXStatistics = window.MemoXStatistics || {};
window.MemoXStatistics.Heatmap = Heatmap;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const Heatmap = (window.MemoXStatistics || {}).Heatmap;
