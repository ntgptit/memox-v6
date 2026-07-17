/* MemoX — Languages local: RemoveLanguageDialog (remove-pair confirm overlay).
   Composes the shared window.ConfirmDialog (_shared/ConfirmDialog.jsx). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;

function RemoveLanguageDialog() {
  return (
    <window.ConfirmDialog align="center" scrimNode="languages/remove-scrim"
      icon="delete" tone="error" title="Remove 한국어 → English?"
      text="All decks and cards for this pair will be deleted. This can't be undone."
      dialogNode="languages/remove-dialog"
      actions={<React.Fragment>
        <MxButton variant="ghost" block node="languages/remove-cancel">Cancel</MxButton>
        <MxButton variant="primary" danger block node="languages/remove-ok">Remove</MxButton>
      </React.Fragment>} />
  );
}

window.MemoXLanguages = window.MemoXLanguages || {};
window.MemoXLanguages.RemoveLanguageDialog = RemoveLanguageDialog;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const RemoveLanguageDialog = (window.MemoXLanguages || {}).RemoveLanguageDialog;
