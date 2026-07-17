/* MemoX — Study-session local: StageFill (stage 5 / answer-save-error — type answer). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;

function StageFill() {
  const { PromptCard } = window.MemoXStudySession || {};
  return (
    <React.Fragment>
      <PromptCard term="school" sub="MEANING" />
      <div style={{ border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', background: 'var(--memox-surface)', borderRadius: 'var(--memox-radius-control)', padding: 'var(--memox-space-4)', minHeight: 'var(--memox-size-md)', color: 'var(--memox-text-tertiary)', fontWeight: 'var(--memox-font-weight-semibold)' }}>Type the Korean word…</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--memox-space-3)' }}>
        <MxButton variant="ghost" icon="lightbulb" block node="study-session/hint">Help</MxButton>
        <MxButton variant="primary" block node="study-session/check">Check</MxButton>
      </div>
    </React.Fragment>
  );
}

window.MemoXStudySession = window.MemoXStudySession || {};
window.MemoXStudySession.StageFill = StageFill;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const StageFill = (window.MemoXStudySession || {}).StageFill;
