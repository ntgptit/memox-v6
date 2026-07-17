/* Shared: DeckResetConfirmDialog — confirm resetting a deck's review progress. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;
function DeckResetConfirmDialog() {
  return (
    <window.ConfirmDialog align="center" scrimNode="deck-settings/reset-scrim"
      icon="restart_alt" tone="error" title="Reset progress?"
      text="Reset every card in this deck back to New? Their review boxes and due dates will be cleared."
      dialogNode="deck-settings/reset-dialog"
      actions={<React.Fragment>
        <MxButton variant="ghost" block node="deck-settings/reset-cancel">Cancel</MxButton>
        <MxButton variant="primary" danger block node="deck-settings/reset-ok">Reset</MxButton>
      </React.Fragment>} />
  );
}
window.DeckResetConfirmDialog = DeckResetConfirmDialog;
})();

export const DeckResetConfirmDialog = window.DeckResetConfirmDialog;
