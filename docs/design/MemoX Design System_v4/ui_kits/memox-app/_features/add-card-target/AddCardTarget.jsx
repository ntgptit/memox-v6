/* MemoX — Add Card · target picker (spec §16). Shown when Add Card is triggered from a global
   surface (Dashboard / global action) and the target deck is ambiguous. Only LEAF decks and EMPTY
   decks can receive cards; PARENT decks are disabled with a helper pointing to their nested decks
   (§13, §22 — global Add-Card never targets a parent). Node prefix: add-card-target/*.
   States: picker · no-target. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxButton, MxIconTile } = NS;
const { Scrim, Sheet } = window;

function DeckRow({ icon, name, meta, badge, disabled, helper, indent, node }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)' }}>
      <div data-mx-node={node} role="option" aria-disabled={disabled} className={disabled ? '' : 'card--interactive'}
        style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-3)', paddingLeft: indent ? 'var(--memox-space-8)' : 'var(--memox-space-3)', borderRadius: 'var(--memox-radius-control)', opacity: disabled ? 0.6 : 1 }}>
        <MxIconTile icon={icon} tone={disabled ? 'neutral' : 'accent'} size="sm" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 'var(--memox-font-weight-medium)' }}>{name}</div>
          {meta ? <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>{meta}</div> : null}
        </div>
        {badge ? <span style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', fontWeight: 'var(--memox-font-weight-medium)' }}>{badge}</span> : null}
        {disabled ? null : <span className="material-symbols-rounded" style={{ color: 'var(--memox-text-tertiary)' }}>chevron_right</span>}
      </div>
      {helper ? <div style={{ paddingLeft: 'var(--memox-space-8)', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }} data-mx-node={node + '-helper'}>{helper}</div> : null}
    </div>
  );
}

const backdrop = (
  <MxScaffold node="add-card-target/screen" appBar={<MxContextualAppBar variant="root" node="add-card-target/back-appbar" title="Today" />}>
    <div style={{ height: 'var(--memox-space-8)' }} />
  </MxScaffold>
);

function AddCardTarget({ state = 'picker' }) {
  /* §16 no valid target — every deck is a parent (or none exist) */
  if (state === 'no-target') {
    return (
      <React.Fragment>
        {backdrop}
        <Scrim align="end" node="add-card-target/scrim">
          <Sheet title="Choose a deck" node="add-card-target/sheet">
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 'var(--memox-space-3)', padding: 'var(--memox-space-4) 0' }}>
              <MxIconTile icon="library_add" tone="accent" />
              <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)' }}>No deck can receive cards yet</div>
              <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', maxWidth: 'var(--memox-size-4xl)' }}>Create a deck first, or open an empty deck and add a card there.</div>
              <MxButton variant="primary" icon="stacks" node="add-card-target/create-deck">Create deck</MxButton>
            </div>
          </Sheet>
        </Scrim>
      </React.Fragment>
    );
  }

  return (
    <React.Fragment>
      {backdrop}
      <Scrim align="end" node="add-card-target/scrim">
        <Sheet title="Choose a deck" node="add-card-target/sheet">
          <DeckRow icon="account_tree" name="Korean TOPIK I" badge="Parent" disabled
            helper="Choose one of its nested decks." node="add-card-target/parent" />
          <DeckRow icon="style" name="Vocabulary" meta="320 cards" indent node="add-card-target/child-vocab" />
          <DeckRow icon="style" name="Grammar" meta="120 cards" indent node="add-card-target/child-grammar" />
          <DeckRow icon="inbox" name="Japanese Basics" meta="0 cards · empty" node="add-card-target/empty-jp" />
        </Sheet>
      </Scrim>
    </React.Fragment>
  );
}

window.AddCardTarget = AddCardTarget;
})();

export const AddCardTarget = window.AddCardTarget;
