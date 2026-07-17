/* MemoX — Empty Deck (spec §11). A deck with NO cards and NO child decks. The first content the
   user adds decides how the deck is used (leaf vs parent) — the cards-vs-nested choice lives HERE,
   after creation, not at create time (§1, §22). Also the state a Leaf reaches after its last card
   is deleted, or a Parent after its last child is removed (§15, §20).
   Actions: Add card (primary → card editor), Create nested deck (secondary → create dialog, this
   deck as parent), Import cards (tertiary → import). Node prefix: empty-deck/*.
   States: default · create-nested-dialog · import-target. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxButton, MxIconButton, MxLink } = NS;
const { Scrim, Sheet, MenuItem, EmptyState } = window;

const nestedBar = (
  <MxContextualAppBar variant="nested" node="empty-deck/appbar" title="Korean TOPIK I"
    actions={<React.Fragment>
      <MxIconButton icon="search" size="sm" node="empty-deck/search" ariaLabel="Search" />
      <MxIconButton icon="more_vert" size="sm" node="empty-deck/more" ariaLabel="More" />
    </React.Fragment>} />
);

function Content() {
  // Shared EmptyState (proven at 200% font / narrow width — scrolls rather than clipping).
  return (
    <EmptyState node="empty-deck/empty" icon="inbox" title="This deck is empty"
      text="Add cards directly, or organise this deck into smaller decks."
      action={<div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', width: '100%', maxWidth: 'var(--memox-size-4xl)' }}>
        <MxButton variant="primary" icon="add" block node="empty-deck/add-card">Add card</MxButton>
        <MxButton variant="secondary" icon="account_tree" block node="empty-deck/create-nested">Create nested deck</MxButton>
        <div style={{ display: 'flex', justifyContent: 'center', marginTop: 'var(--memox-space-1)' }}>
          <MxLink size="sm" icon="upload_file" trailingIcon={null} node="empty-deck/import">Import cards</MxLink>
        </div>
      </div>} />
  );
}

function EmptyDeck({ state = 'default' }) {
  /* §11 Create nested deck → Create Deck dialog with THIS deck as parent (delegates to the
     shared dialog so the create form has one implementation). */
  if (state === 'create-nested-dialog') {
    return window.CreateDeckDialog({ state: 'nested' });
  }

  /* §17 Import into an empty deck — the deck is a valid flat-card target, so import goes
     straight in (no "select a nested deck" branch, which is Parent-only). */
  if (state === 'import-target') {
    return (
      <React.Fragment>
        <MxScaffold node="empty-deck/screen" appBar={nestedBar}><Content /></MxScaffold>
        <Scrim align="end" node="empty-deck/import-scrim">
          <Sheet title="Import cards" node="empty-deck/import-sheet">
            <div style={{ marginTop: 'calc(-1 * var(--memox-space-2))', marginBottom: 'var(--memox-space-2)', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>Into Korean TOPIK I</div>
            <MenuItem icon="upload_file" label="Choose a file" node="empty-deck/import-file" />
            <MenuItem icon="content_paste" label="Paste text" node="empty-deck/import-paste" />
          </Sheet>
        </Scrim>
      </React.Fragment>
    );
  }

  return <MxScaffold node="empty-deck/screen" appBar={nestedBar}><Content /></MxScaffold>;
}

window.EmptyDeck = EmptyDeck;
})();

export const EmptyDeck = window.EmptyDeck;
