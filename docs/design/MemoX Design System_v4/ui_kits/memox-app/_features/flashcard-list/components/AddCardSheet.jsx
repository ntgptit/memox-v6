/* AddCardSheet — the create sheet for the Flashcard List screen. Card-only:
   Add card / Import cards. NEVER Create subdeck (that belongs to the Subdeck List). */
(function () {
function AddCardSheet() {
  const { Scrim, Sheet, MenuItem } = window;
  return (
    <Scrim align="end" node="flashcard-list/add-scrim">
      <Sheet title="Add" node="flashcard-list/add-sheet">
        <MenuItem icon="note_add" label="Add card" node="flashcard-list/add-card" />
        <MenuItem icon="upload_file" label="Import cards" node="flashcard-list/add-import" />
      </Sheet>
    </Scrim>
  );
}

window.MemoXFlashcardList = Object.assign(window.MemoXFlashcardList || {}, { AddCardSheet });
})();

export const AddCardSheet = (window.MemoXFlashcardList || {}).AddCardSheet;
