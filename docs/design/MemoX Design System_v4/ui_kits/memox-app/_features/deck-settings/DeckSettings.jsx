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
    // Edit deck metadata (ADR-009 / CF-04): business edit-deck.md defines name (required) +
    // description (optional) + a read-only language pair — the same form serves rename and edit.
    overlay = (
      <Scrim align="center" node="deck-settings/rename-scrim">
        <Dialog icon="edit" title="Edit deck" node="deck-settings/rename-dialog"
          text={<React.Fragment>
            <DialogInput label="Deck name" value={TITLE} />
            <DialogInput label="Description" value="Vocabulary and grammar for TOPIK I" />
            <div data-mx-node="deck-settings/rename-pair" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)' }}>
              <span style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text-secondary)' }}>Language pair</span>
              <span style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-tertiary)' }}>한국어 → English · read-only</span>
            </div>
          </React.Fragment>}
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
  // `leaf-actions` is retained as a frozen fixture alias. Deck kinds are exclusive and there is
  // no Leaf→Parent conversion, so the action set is intentionally identical to the default.
  else if (state === 'leaf-actions') overlay = <DeckActionsSheet title={TITLE} />;
  else overlay = <DeckActionsSheet title={TITLE} />; // action-sheet (default)

  return <React.Fragment>{base}{overlay}</React.Fragment>;
}

window.DeckSettings = DeckSettings;
})();

export const DeckSettings = window.DeckSettings;
