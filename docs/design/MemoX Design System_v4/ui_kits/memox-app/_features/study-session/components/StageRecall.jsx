/* MemoX — Study-session local: StageRecall (stage 4 — recall then reveal). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard, MxButton } = NS;

function StageRecall() {
  const { PromptCard } = window.MemoXStudySession || {};
  return (
    <React.Fragment>
      <PromptCard term="친구" />
      <MxCard style={{ alignItems: 'center', minHeight: 'var(--memox-size-xl)', justifyContent: 'center', color: 'var(--memox-text-tertiary)' }}>Recall the meaning, then tap “Show”</MxCard>
      <MxButton variant="primary" icon="visibility" block size="lg" node="study-session/reveal">Show</MxButton>
    </React.Fragment>
  );
}

window.MemoXStudySession = window.MemoXStudySession || {};
window.MemoXStudySession.StageRecall = StageRecall;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const StageRecall = (window.MemoXStudySession || {}).StageRecall;
