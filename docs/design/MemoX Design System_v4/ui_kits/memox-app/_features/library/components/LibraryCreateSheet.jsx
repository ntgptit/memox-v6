/* LibraryCreateSheet — context-aware create sheet (§6). Root: Add card / Create deck /
   Import. Deck detail (`deck` truthy): Add card / Create subdeck / Import into this deck.
   A subdeck always has a parent deck — there is no top-level grouping to create. */
(function () {
function LibraryCreateSheet({ deck }) {
  const { Scrim, Sheet, MenuItem } = window;
  return (
    <Scrim align="end" node="library/create-scrim">
      <Sheet title="Create" node="library/create-sheet">
        <MenuItem icon="note_add" label="Add card" node="library/create-card" />
        {deck
          ? <MenuItem icon="library_add" label="Create subdeck" node="library/create-subdeck" />
          : <MenuItem icon="stacks" label="Create deck" node="library/create-deck" />}
        <div style={{ height: 'var(--memox-stroke-hairline)', background: 'var(--memox-divider)', margin: 'var(--memox-space-2)' }} />
        <MenuItem icon="upload_file" label={deck ? 'Import into this deck' : 'Import cards'} node="library/create-import" />
      </Sheet>
    </Scrim>
  );
}

window.MemoXLibrary = Object.assign(window.MemoXLibrary || {}, { LibraryCreateSheet });
})();

export const LibraryCreateSheet = (window.MemoXLibrary || {}).LibraryCreateSheet;
