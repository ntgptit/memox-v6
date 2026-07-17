/* MemoX — Study-session local: PromptCard (centered term + optional sub-label).
   Shared by StageGuess / StageRecall / StageFill — load before them. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard } = NS;

function PromptCard({ term, sub }) {
  return (
    <MxCard style={{ alignItems: 'center', textAlign: 'center', gap: 'var(--memox-space-3)', padding: 'var(--memox-space-6)' }}>
      <div style={{ fontSize: 'var(--memox-font-size-3xl)', fontWeight: 'var(--memox-font-weight-bold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>{term}</div>
      {sub ? <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)' }}>{sub}</div> : null}
    </MxCard>
  );
}

window.MemoXStudySession = window.MemoXStudySession || {};
window.MemoXStudySession.PromptCard = PromptCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const PromptCard = (window.MemoXStudySession || {}).PromptCard;
