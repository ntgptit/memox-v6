/* MemoX — Study-session local: ExitDialog (leave-session confirm overlay).
   Composes the shared window.ConfirmDialog (_shared/ConfirmDialog.jsx). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxButton } = NS;

function ExitDialog() {
  return (
    <window.ConfirmDialog align="center" scrimNode="study-session/exit-scrim"
      icon="logout" tone="error" title="Leave the session?"
      text="Cards that haven't finished all 5 stages will stay New."
      dialogNode="study-session/exit-dialog"
      actions={<React.Fragment>
        <MxButton variant="ghost" block node="study-session/exit-cancel">Stay</MxButton>
        <MxButton variant="primary" danger block node="study-session/exit-ok">Leave</MxButton>
      </React.Fragment>} />
  );
}

window.MemoXStudySession = window.MemoXStudySession || {};
window.MemoXStudySession.ExitDialog = ExitDialog;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const ExitDialog = (window.MemoXStudySession || {}).ExitDialog;
