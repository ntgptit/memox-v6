/* MemoX — Study-session local: StageReview (stage 1 — see term + meaning). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard, MxButton } = NS;

function StageReview() {
  return (
    <React.Fragment>
      <MxCard node="study-session/card" style={{ flex: 1, alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 'var(--memox-space-4)', minHeight: 'var(--memox-size-5xl)' }}>
        <div style={{ fontSize: 'var(--memox-font-size-3xl)', fontWeight: 'var(--memox-font-weight-bold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>학교</div>
        <div style={{ width: 'var(--memox-size-md)', height: 'var(--memox-size-3xs)', background: 'var(--memox-divider)', borderRadius: 'var(--memox-radius-xs)' }} />
        <div style={{ fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-bold)' }}>school</div>
        <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)' }}>noun · a place of learning</div>
      </MxCard>
      <MxButton variant="primary" icon="arrow_forward" block size="lg" node="study-session/next">Next</MxButton>
    </React.Fragment>
  );
}

window.MemoXStudySession = window.MemoXStudySession || {};
window.MemoXStudySession.StageReview = StageReview;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const StageReview = (window.MemoXStudySession || {}).StageReview;
