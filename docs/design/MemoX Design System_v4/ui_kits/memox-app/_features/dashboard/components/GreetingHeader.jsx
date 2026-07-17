/* MemoX — Dashboard local: GreetingHeader (date eyebrow + greeting headline).
   Lives in the scroll body — split OUT of the app bar so the greeting scrolls
   away with content while the slim bar (actions only) stays. Same type ramp the
   large app bar used: sm/semibold secondary eyebrow, 2xl/extrabold title. */
(function () {

function GreetingHeader({ eyebrow, title, node }) {
  return (
    <div data-mx-node={node} style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)' }}>
      <div style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-semibold)', color: 'var(--memox-text-secondary)' }}>{eyebrow}</div>
      <div style={{ fontSize: 'var(--memox-font-size-2xl)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)', lineHeight: 'var(--memox-line-height-tight)' }}>{title}</div>
    </div>
  );
}

window.MemoXDashboard = window.MemoXDashboard || {};
window.MemoXDashboard.GreetingHeader = GreetingHeader;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const GreetingHeader = (window.MemoXDashboard || {}).GreetingHeader;
