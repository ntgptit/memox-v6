/* MemoX — Create Deck DIALOG (spec §8, §10, §18). Second deck onward. A CENTERED modal
   (window.FormDialog — caps at the frame, scrolls its body, never a bottom sheet): name + language
   pair, optional description, ONE primary CTA. Creates an EMPTY deck. Root picks a pair; nested
   inherits it (read-only) + shows "Inside <parent>". Submit lifecycle keeps a single primary and
   locks the whole form while submitting; a dirty dialog confirms discard on dismiss (§18).
   Node prefix: create-deck-dialog/*.
   States: root-default · root-multi-pair · root-missing-pair · nested · optional-expanded ·
   validation · duplicate-root · duplicate-sibling · name-too-long · submitting · submit-failure ·
   long-name · keyboard-open · discard-confirm. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxButton } = NS;
const { FormDialog, ConfirmDialog } = window;

const LONG_NAME = 'Advanced Korean Honorific Speech Registers and Formal Writing — TOPIK II';
const LONG_DESC = 'Vocabulary, grammar and set phrases for formal and honorific speech, covering business, academic and ceremonial registers across the full TOPIK II band.';
const PAIRS = ['Korean → Vietnamese', 'English → Vietnamese', 'Japanese → Vietnamese'];
const DISABLED = { opacity: 'var(--memox-opacity-disabled, 0.5)', pointerEvents: 'none' };

// A dialog field: label + a single sunken box (~48px) with the value/placeholder, ellipsis on
// overflow. Optional error line + trailing affordance (select chevron).
function DField({ label, value, placeholder, error, trailing, muted, node }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
      <div style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-semibold)', color: 'var(--memox-text-secondary)' }}>{label}</div>
      <div data-mx-node={node} style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', boxSizing: 'border-box', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-2) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: 'var(--memox-surface-sunken)', border: error ? 'var(--memox-stroke-emphasis) solid var(--memox-error)' : 'var(--memox-stroke-hairline) solid var(--memox-divider)' }}>
        <span style={{ flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: value ? (muted ? 'var(--memox-text-secondary)' : 'var(--memox-text)') : 'var(--memox-text-tertiary)' }}>{value || placeholder}</span>
        {trailing}
      </div>
      {error ? <div className="field-group__error" data-mx-node={node + '-error'} role="alert">{error}</div> : null}
    </div>
  );
}

const chevron = <span className="material-symbols-rounded" style={{ color: 'var(--memox-text-secondary)' }}>expand_more</span>;

function CreateDeckDialog({ state = 'root-default', backdrop }) {
  const nested = state === 'nested' || state === 'duplicate-sibling';
  const optional = state === 'optional-expanded';
  const submitting = state === 'submitting';
  const failure = state === 'submit-failure';
  const longText = state === 'long-name';
  const multiPair = state === 'root-multi-pair';
  const keyboard = state === 'keyboard-open';
  const discard = state === 'discard-confirm';

  const nameError =
    state === 'validation' ? 'Give your deck a name.'
    : state === 'name-too-long' ? 'Use a shorter deck name.'
    : state === 'duplicate-root' ? 'A deck with this name already exists in your Library.'
    : state === 'duplicate-sibling' ? 'A deck with this name already exists here.'
    : null;
  const pairError = state === 'root-missing-pair' ? 'Choose a language pair.' : null;
  const pairValue = state === 'root-missing-pair' ? '' : 'Korean → Vietnamese';
  const name = state === 'validation' ? ''
    : state === 'name-too-long' || longText ? LONG_NAME
    : nested ? 'Grammar' : 'Korean TOPIK II';

  // Compose the dialog OVER the real screen it was opened from (§13), so the app bar / breadcrumb /
  // filter / deck list / bottom-nav stay visible behind the scrim and context is never lost — not a
  // fake 3-skeleton placeholder. Root opens over the loaded Library; nested opens over the parent
  // deck (Library nested-loaded → SubdeckList loaded). Entry points may pass their own `backdrop`.
  const bg = backdrop || (nested ? window.Library({ state: 'nested-loaded' }) : window.Library({ state: 'loaded' }));

  const actions = (
    <React.Fragment>
      <MxButton variant="ghost" disabled={submitting} node="create-deck-dialog/cancel">Cancel</MxButton>
      <MxButton variant="primary" icon={submitting ? undefined : 'add'} disabled={submitting} node={failure ? 'create-deck-dialog/retry' : 'create-deck-dialog/create'}>
        {submitting ? 'Creating…' : failure ? 'Try again' : 'Create deck'}
      </MxButton>
    </React.Fragment>
  );

  const pairField = nested
    ? <DField label="Language pair" value="Korean → Vietnamese" muted trailing={<span style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>Inherited</span>} node="create-deck-dialog/pair-inherited" />
    : <DField label="Language pair *" value={pairValue} placeholder="Choose a language pair" error={pairError} trailing={chevron} node="create-deck-dialog/pair" />;

  // root-multi-pair: the picker is OPEN, showing the available pairs (first selected) — distinct
  // from root-default's single collapsed value.
  const pairPicker = multiPair ? (
    <div data-mx-node="create-deck-dialog/pair-options" role="listbox" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)', border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', borderRadius: 'var(--memox-radius-control)', overflow: 'hidden' }}>
      {PAIRS.map((p, i) => (
        <div key={p} role="option" aria-selected={i === 0} className="card--interactive" style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-2) var(--memox-space-4)', background: i === 0 ? 'var(--memox-state-selected)' : 'transparent' }}>
          <span style={{ flex: 1 }}>{p}</span>
          {i === 0 ? <span className="material-symbols-rounded" style={{ color: 'var(--memox-primary)', fontVariationSettings: "'FILL' 1" }}>check</span> : null}
        </div>
      ))}
    </div>
  ) : null;

  const body = (
    <React.Fragment>
      {failure ? (
        <window.ActionCallout node="create-deck-dialog/error" tone="error" icon="error"
          text="Couldn’t create the deck. Your information is still here." />
      ) : null}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-4)', ...(submitting ? DISABLED : {}) }}>
        <DField label="Deck name *" value={name} placeholder="Name your deck" error={nameError} node="create-deck-dialog/name" />
        {pairField}
        {pairPicker}
        {optional || longText
          ? <DField label="Description" value={longText ? LONG_DESC : 'Vocabulary and grammar for TOPIK II'} node="create-deck-dialog/description" />
          : (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-semibold)', color: 'var(--memox-text-secondary)' }}>Add a description</div>
              <NS.MxLink size="sm" trailingIcon={null} disabled={submitting} node="create-deck-dialog/optional-toggle">Add</NS.MxLink>
            </div>
          )}
      </div>
    </React.Fragment>
  );

  return (
    <React.Fragment>
      {bg}
      <FormDialog title="Create deck" subtitle={nested ? 'Inside Korean TOPIK I' : 'Inside Library'}
        node="create-deck-dialog/dialog" scrimNode="create-deck-dialog/scrim" keyboard={keyboard} actions={actions}>
        {body}
      </FormDialog>
      {/* §18 dismiss with unsaved input → confirm discarding the draft (one primary: Discard). */}
      {discard ? (
        <ConfirmDialog align="center" scrimNode="create-deck-dialog/discard-scrim"
          icon="delete" tone="warning" title="Discard this deck draft?"
          text="Your deck name won’t be saved."
          dialogNode="create-deck-dialog/discard-dialog"
          actions={<React.Fragment>
            <MxButton variant="ghost" block node="create-deck-dialog/discard-keep">Keep editing</MxButton>
            <MxButton variant="primary" danger block node="create-deck-dialog/discard-ok">Discard</MxButton>
          </React.Fragment>} />
      ) : null}
    </React.Fragment>
  );
}

window.CreateDeckDialog = CreateDeckDialog;
})();

export const CreateDeckDialog = window.CreateDeckDialog;
