/* MemoX — Deck Settings. Primary objective: manage deck metadata and lifecycle actions
   (rename, move, export, reset progress, delete). Opened from the "More" action of the
   Subdeck List / Flashcard List. NEVER shows a content list (no subdeck / card rows).
   Composes the shared Deck* overlays. States: action-sheet · rename · move · reset-confirm
   · delete-confirm. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxButton } = NS;
const TITLE = 'Korean TOPIK I';

function DeckSettings({ state = 'action-sheet' }) {
  const { DeckActionsSheet, DeckMoveSheet, DeckResetConfirmDialog, DeckDeleteConfirmDialog } = window;
  const { Scrim, Dialog, DialogInput } = window;

  // Backdrop the overlays sit on: the deck the user came from (title only, no content list).
  const bar = (
    <MxContextualAppBar variant="nested" node="deck-settings/appbar" title={TITLE}
      actions={<MxIconButton icon="more_vert" size="sm" node="deck-settings/more" ariaLabel="Deck settings" />} />
  );
  const base = (
    <MxScaffold node="deck-settings/screen" appBar={bar}>
      <div data-mx-node="deck-settings/caption" style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>Manage this deck.</div>
    </MxScaffold>
  );

  let overlay;
  if (state === 'rename') {
    overlay = (
      <Scrim align="center" node="deck-settings/rename-scrim">
        <Dialog icon="edit" title="Rename deck" node="deck-settings/rename-dialog"
          text={<DialogInput label="Deck name" value={TITLE} />}
          actions={<React.Fragment>
            <div style={{ flex: 1 }} />
            <MxButton variant="ghost" node="deck-settings/rename-cancel">Cancel</MxButton>
            <MxButton variant="primary" node="deck-settings/rename-ok">Save</MxButton>
          </React.Fragment>} />
      </Scrim>
    );
  } else if (state === 'move') overlay = <DeckMoveSheet title={TITLE} />;
  else if (state === 'reset-confirm') overlay = <DeckResetConfirmDialog />;
  else if (state === 'delete-confirm') overlay = <DeckDeleteConfirmDialog />;
  // leaf-actions (§14): a LEAF deck's overflow — adds "Organise into nested decks", the entry to
  // the Leaf→Parent conversion dialog. Parent decks use the plain action-sheet (no Organise).
  else if (state === 'leaf-actions') overlay = <DeckActionsSheet title={TITLE} leaf />;
  else overlay = <DeckActionsSheet title={TITLE} />; // action-sheet (default)

  return <React.Fragment>{base}{overlay}</React.Fragment>;
}

window.DeckSettings = DeckSettings;
})();

export const DeckSettings = window.DeckSettings;
