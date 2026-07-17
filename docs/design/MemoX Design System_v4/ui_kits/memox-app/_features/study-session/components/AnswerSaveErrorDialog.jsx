/* MemoX — Study-session local: AnswerSaveErrorDialog (answer-save-error overlay).
   Composes the shared window.ConfirmDialog (_shared/ConfirmDialog.jsx). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;

function AnswerSaveErrorDialog() {
  return (
    <window.ConfirmDialog align="center" scrimNode="study-session/save-error-scrim"
      icon="sync_problem" tone="error" title="Couldn't save your answer"
      text="Your result for this card wasn't saved. Retry so your review schedule stays correct."
      dialogNode="study-session/save-error-dialog"
      actions={<React.Fragment>
        <MxButton variant="ghost" block node="study-session/save-error-back">Back</MxButton>
        <MxButton variant="primary" icon="refresh" block node="study-session/save-error-retry">Retry</MxButton>
      </React.Fragment>} />
  );
}

window.MemoXStudySession = window.MemoXStudySession || {};
window.MemoXStudySession.AnswerSaveErrorDialog = AnswerSaveErrorDialog;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const AnswerSaveErrorDialog = (window.MemoXStudySession || {}).AnswerSaveErrorDialog;
