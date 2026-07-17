/* MemoX — Deck Content Choice ("New deck"). A FORM: name the deck, pick how it is
   organised (radio cards — "Add cards directly" is preselected as the common case),
   then commit with the single primary CTA "Create deck". Import is a tertiary action.
   States: default · subdecks · validation · duplicate · submitting · submit-error.
   Reached for an existing deck (rename + reorganise) the CTA reads "Save" — same form. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxButton, MxIconTile, MxTextField } = NS;

const OPTIONS = [
  { id: 'cards', icon: 'playing_cards', title: 'Add cards directly', text: 'Use this as a final study deck.', node: 'deck-content-choice/cards' },
  { id: 'subdecks', icon: 'account_tree', title: 'Organise with subdecks', text: 'Create nested topics before adding cards.', node: 'deck-content-choice/subdecks' },
];

function OrganiseOption({ opt, selected }) {
  return (
    <div
      data-mx-node={opt.node}
      role="radio"
      aria-checked={selected}
      className="card card--interactive"
      style={{
        padding: 'var(--memox-space-4)',
        display: 'flex',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 'var(--memox-space-4)',
        border: selected
          ? 'var(--memox-stroke-emphasis) solid var(--memox-primary)'
          : 'var(--memox-stroke-hairline) solid var(--memox-divider)',
        background: selected ? 'var(--memox-state-selected)' : 'var(--memox-surface)',
      }}
    >
      <MxIconTile icon={opt.icon} tone="accent" />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)' }}>{opt.title}</div>
        <div style={{ marginTop: 'var(--memox-space-1)', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>{opt.text}</div>
      </div>
      <span
        className="material-symbols-rounded"
        style={
          selected
            ? { color: 'var(--memox-primary)', fontVariationSettings: "'FILL' 1" }
            : { color: 'var(--memox-text-tertiary)' }
        }
      >
        {selected ? 'check_circle' : 'radio_button_unchecked'}
      </span>
    </div>
  );
}

function DeckContentChoice({ state = 'default' }) {
  const selected = state === 'subdecks' ? 'subdecks' : 'cards';
  const submitting = state === 'submitting';
  const fieldError =
    state === 'validation' ? 'Give your deck a name.'
    : state === 'duplicate' ? 'You already have a deck called “Korean TOPIK I”.'
    : null;
  const name = state === 'validation' ? '' : 'Korean TOPIK I';

  const bar = <MxContextualAppBar variant="nested" node="deck-content-choice/appbar" title="New deck" />;
  return (
    <MxScaffold node="deck-content-choice/screen" appBar={bar}>
      {state === 'submit-error' ? (
        <window.ActionCallout
          node="deck-content-choice/error"
          tone="error"
          icon="error"
          text="Couldn’t save the deck. Check storage and try again."
          action={<MxButton variant="primary" size="sm" node="deck-content-choice/retry">Retry</MxButton>}
        />
      ) : null}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
        <window.SectionLabel>DECK NAME</window.SectionLabel>
        <div style={{ display: 'flex', alignItems: 'center', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: 'var(--memox-surface)', border: fieldError ? 'var(--memox-stroke-emphasis) solid var(--memox-error)' : 'var(--memox-stroke-hairline) solid var(--memox-divider)' }}>
          <MxTextField placeholder="Name your deck" defaultValue={name} autoFocus node="deck-content-choice/name" />
        </div>
        {fieldError ? <div className="field-group__error" data-mx-node="deck-content-choice/name-error" role="alert">{fieldError}</div> : null}
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }} role="radiogroup" aria-label="How to organise the deck">
        <window.SectionLabel>ORGANISE</window.SectionLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
          {OPTIONS.map((opt) => <OrganiseOption key={opt.id} opt={opt} selected={selected === opt.id} />)}
        </div>
      </div>

      <MxButton variant="primary" icon={submitting ? undefined : 'add'} block disabled={submitting} node="deck-content-choice/create">
        {submitting ? 'Creating…' : 'Create deck'}
      </MxButton>

      <div style={{ display: 'flex', justifyContent: 'center' }}>
        <NS.MxLink size="sm" icon="upload_file" trailingIcon={null} node="deck-content-choice/import">Import from a file</NS.MxLink>
      </div>
    </MxScaffold>
  );
}

window.DeckContentChoice = DeckContentChoice;
})();

export const DeckContentChoice = window.DeckContentChoice;
