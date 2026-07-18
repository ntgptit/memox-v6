/* Shared: DeckResetConfirmDialog — confirm resetting a deck's review progress. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;
function DeckResetConfirmDialog() {
  return (
    <window.ConfirmDialog align="center" scrimNode="deck-settings/reset-scrim"
      icon="restart_alt" tone="error" title="Reset learning progress?"
      text={"This will reset progress for 84 cards in “Korean TOPIK I”. Your cards and nested decks will stay in place."}
      dialogNode="deck-settings/reset-dialog"
      actions={<React.Fragment>
        <MxButton variant="ghost" block node="deck-settings/reset-cancel">Keep progress</MxButton>
        <MxButton variant="primary" danger block node="deck-settings/reset-ok">Reset progress</MxButton>
      </React.Fragment>} />
  );
}
window.DeckResetConfirmDialog = DeckResetConfirmDialog;
})();

export const DeckResetConfirmDialog = window.DeckResetConfirmDialog;
