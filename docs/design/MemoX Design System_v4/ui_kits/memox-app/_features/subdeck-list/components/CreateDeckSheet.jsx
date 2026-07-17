/* CreateDeckSheet — the create sheet for the nested-deck list screen. Deck-only:
   Create deck / Import decks. NEVER Add card / Import cards (that belongs to the
   Flashcard List). A "nested deck" is a Deck with parentId set — the same model, not a
   separate "Subdeck" object. (Node ids keep the frozen `subdeck-list/…` contract.) */
(function () {
function CreateDeckSheet() {
  const { Scrim, Sheet, MenuItem } = window;
  return (
    <Scrim align="end" node="subdeck-list/create-scrim">
      <Sheet title="Create" node="subdeck-list/create-sheet">
        <MenuItem icon="library_add" label="Create deck" node="subdeck-list/create-subdeck" />
        <MenuItem icon="account_tree" label="Import decks" node="subdeck-list/create-import" />
      </Sheet>
    </Scrim>
  );
}

window.MemoXSubdeckList = Object.assign(window.MemoXSubdeckList || {}, { CreateDeckSheet });
})();

export const CreateDeckSheet = (window.MemoXSubdeckList || {}).CreateDeckSheet;
