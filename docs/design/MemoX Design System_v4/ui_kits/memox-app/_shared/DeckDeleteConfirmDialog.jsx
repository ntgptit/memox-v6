/* Shared: DeckDeleteConfirmDialog — confirm deleting a whole deck. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;
function DeckDeleteConfirmDialog() {
  return (
    <window.ConfirmDialog align="center" scrimNode="deck-settings/delete-scrim"
      icon="delete" tone="error" title="Delete this deck?"
      text="Deleting removes every nested deck, card and review state inside. This can't be undone."
      dialogNode="deck-settings/delete-dialog"
      actions={<React.Fragment>
        <MxButton variant="ghost" block node="deck-settings/delete-cancel">Cancel</MxButton>
        <MxButton variant="primary" danger block node="deck-settings/delete-ok">Delete</MxButton>
      </React.Fragment>} />
  );
}
window.DeckDeleteConfirmDialog = DeckDeleteConfirmDialog;
})();

export const DeckDeleteConfirmDialog = window.DeckDeleteConfirmDialog;
