/* MemoX — Study-result local: Cta (primary/secondary action pair, varies by state). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;

function Cta({ state }) {
  if (state === 'goal-missed') {
    return (<React.Fragment>
      <MxButton variant="primary" icon="bolt" block node="study-result/continue">Keep going</MxButton>
      <MxButton variant="ghost" block node="study-result/later">Later</MxButton>
    </React.Fragment>);
  }
  if (state === 'many-wrong') {
    return (<React.Fragment>
      <MxButton variant="primary" icon="replay" block node="study-result/review-wrong">Review 8 cards</MxButton>
      <MxButton variant="ghost" block node="study-result/library">Back to library</MxButton>
    </React.Fragment>);
  }
  return (<React.Fragment>
    <MxButton variant="primary" icon="bolt" block node="study-result/continue">Keep studying</MxButton>
    <MxButton variant="ghost" block node="study-result/library">Back to library</MxButton>
  </React.Fragment>);
}

window.MemoXStudyResult = window.MemoXStudyResult || {};
window.MemoXStudyResult.Cta = Cta;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const Cta = (window.MemoXStudyResult || {}).Cta;
