/* Shared: DeckActionsSheet — deck-level lifecycle actions, opened from the "More" action of
   Subdeck List / Flashcard List. Manages the deck itself, never its contents (no card /
   subdeck rows here). Promoted out of the old deck-detail feature so both list screens
   share one deck-settings contract. */
(function () {
function DeckActionsSheet({ title = 'Korean TOPIK I', leaf = false }) {
  const { Scrim, Sheet, MenuItem } = window;
  return (
    <Scrim align="end" node="deck-settings/actions-scrim">
      <Sheet title={title} node="deck-settings/actions-sheet">
        <MenuItem icon="edit" label="Rename deck" node="deck-settings/rename" />
        <MenuItem icon="drive_file_move" label="Move deck" node="deck-settings/move" />
        {/* Leaf-only (§14): a leaf that already holds cards can't get a child directly — this is
            the sole entry to the Leaf→Parent conversion dialog. Never shown for a parent deck. */}
        {leaf ? <MenuItem icon="account_tree" label="Organise into nested decks" node="deck-settings/organise" /> : null}
        <MenuItem icon="ios_share" label="Export deck" node="deck-settings/export" />
        <MenuItem icon="restart_alt" label="Reset progress" node="deck-settings/reset" />
        <MenuItem icon="delete" label="Delete deck" danger node="deck-settings/delete" />
      </Sheet>
    </Scrim>
  );
}
window.DeckActionsSheet = DeckActionsSheet;
})();

export const DeckActionsSheet = window.DeckActionsSheet;
