/* MemoX — Create Deck · FIRST-RUN flow (fresh install). Focused, full-screen (spec §4–7).
   Landing (Selection) → Step 1 Learning setup → Step 2 First deck setup → submit lifecycle.
   Create makes an EMPTY deck: no card, no nested deck, no "Default view", no cards-vs-nested
   question at create time (§1). Outcome states land back in the real app shell — not-now →
   Dashboard (bottom nav), success → Library (bottom nav) with the first-deck callout.
   States: landing · step1 · step1-validation · step2 · step2-optional · duplicate · name-too-long ·
   submitting · submit-failure · resume-draft · success · import-branch · not-now.
   Node prefix: create-deck-firstrun/*. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxButton, MxLink, MxIconButton } = NS;
const { SectionLabel } = window;

const LONG_NAME = 'Advanced Korean Honorific Speech Registers and Formal Writing for the Full TOPIK II Band';
const DISABLED = { opacity: 'var(--memox-opacity-disabled, 0.5)', pointerEvents: 'none' };

// A labelled field: a single control box holding the value/placeholder (static in the kit — no
// forced focus ring); long text truncates with an ellipsis. Optional error line + trailing icon.
function Field({ label, value, placeholder, error, node, trailing }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
      <SectionLabel>{label}</SectionLabel>
      <div data-mx-node={node} style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', boxSizing: 'border-box', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-2) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: 'var(--memox-surface)', border: error ? 'var(--memox-stroke-emphasis) solid var(--memox-error)' : 'var(--memox-stroke-hairline) solid var(--memox-divider)' }}>
        <span style={{ flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: value ? 'var(--memox-text)' : 'var(--memox-text-tertiary)' }}>{value || placeholder}</span>
        {trailing ? <span className="material-symbols-rounded" style={{ color: 'var(--memox-text-secondary)' }}>{trailing}</span> : null}
      </div>
      {error ? <div className="field-group__error" data-mx-node={node + '-error'} role="alert">{error}</div> : null}
    </div>
  );
}

// A read-only "select" row (language pair pickers on the focused steps).
function SelectRow({ label, value, node, disabled }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
      <SectionLabel>{label}</SectionLabel>
      <div data-mx-node={node} className={disabled ? '' : 'card--interactive'} style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', boxSizing: 'border-box', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-2) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: disabled ? 'var(--memox-surface-sunken)' : 'var(--memox-surface)', border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', color: disabled ? 'var(--memox-text-secondary)' : 'var(--memox-text)' }}>
        <span style={{ flex: 1 }}>{value}</span>
        {disabled ? null : <span className="material-symbols-rounded" style={{ color: 'var(--memox-text-secondary)' }}>expand_more</span>}
      </div>
    </div>
  );
}

const stepBar = (label, backNode, locked) => (
  <MxContextualAppBar variant="nested" node="create-deck-firstrun/appbar" title=""
    leading={<MxIconButton icon="arrow_back" size="sm" node={backNode} ariaLabel="Back" disabled={!!locked} />}
    actions={<span style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>{label}</span>} />
);

function CreateDeckFirstRun({ state = 'landing' }) {
  /* §4 First-use landing — Selection, no app bar, no bottom nav */
  if (state === 'landing') {
    return (
      <MxScaffold node="create-deck-firstrun/screen">
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 'var(--memox-space-6)', paddingBottom: 'var(--memox-space-8)' }}>
          <div data-mx-node="create-deck-firstrun/wordmark" style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)', color: 'var(--memox-primary)' }}>MemoX</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
            <h1 data-mx-node="create-deck-firstrun/heading" style={{ margin: 0, fontSize: 'var(--memox-font-size-2xl)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>Build your learning library</h1>
            <p style={{ margin: 0, fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)', lineHeight: 'var(--memox-line-height-relaxed)' }}>Create your first deck and add content whenever you’re ready. MemoX will schedule reviews after you start studying.</p>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
            <MxButton variant="primary" icon="stacks" block node="create-deck-firstrun/create">Create your first deck</MxButton>
            <MxButton variant="secondary" icon="upload_file" block node="create-deck-firstrun/import">Import existing cards</MxButton>
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'center', paddingBottom: 'var(--memox-space-4)' }}>
          <MxLink size="sm" trailingIcon={null} node="create-deck-firstrun/not-now">Not now</MxLink>
        </div>
      </MxScaffold>
    );
  }

  /* §4 outcome — Not now → the REAL Dashboard in its NEUTRAL post-skip state, composed (not a
     hand-built copy): the user declined onboarding, so we must NOT drop them into a SECOND
     onboarding. They land in a normal Today shell and navigate freely. */
  if (state === 'not-now') return window.Dashboard({ state: 'empty-after-onboarding-skip' });

  /* §4 outcome — Import branch (first-run import entry) */
  if (state === 'import-branch') {
    return (
      <MxScaffold node="create-deck-firstrun/screen" appBar={stepBar('Import', 'create-deck-firstrun/import-back')}>
        <h1 style={{ margin: 0, fontSize: 'var(--memox-font-size-2xl)', fontWeight: 'var(--memox-font-weight-extrabold)' }}>Import existing cards</h1>
        <p style={{ margin: 0, fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)' }}>Bring in a file or paste text. We’ll create your first deck from it.</p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
          <MxButton variant="secondary" icon="upload_file" block node="create-deck-firstrun/import-file">Choose a file</MxButton>
          <MxButton variant="secondary" icon="content_paste" block node="create-deck-firstrun/import-paste">Paste text</MxButton>
        </div>
      </MxScaffold>
    );
  }

  /* §5 Step 1 — Learning setup (Focused form) */
  if (state === 'step1' || state === 'step1-validation') {
    const invalid = state === 'step1-validation';
    return (
      <MxScaffold node="create-deck-firstrun/screen" appBar={stepBar('Step 1 of 2', 'create-deck-firstrun/s1-back')}>
        {/* xl (not 2xl) so this in-flow step heading keeps a comfortable right-edge gutter at 390px
            — the landing/import hero headings stay 2xl. */}
        <h1 style={{ margin: 0, fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-extrabold)' }}>Set up your learning</h1>
        <SelectRow label="What are you learning? *" value={invalid ? 'Select a language' : 'Korean'} node="create-deck-firstrun/s1-learn" />
        {invalid ? <div className="field-group__error" data-mx-node="create-deck-firstrun/s1-learn-error" role="alert">Choose a language to learn.</div> : null}
        <SelectRow label="Show meanings in *" value="Vietnamese" node="create-deck-firstrun/s1-native" />
        <p style={{ margin: 0, fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>You can add more language pairs later.</p>
        <MxButton variant="primary" block disabled={invalid} node="create-deck-firstrun/s1-continue">Continue</MxButton>
      </MxScaffold>
    );
  }

  /* §6/§7 Step 2 — First Deck setup + submit lifecycle */
  const optional = state === 'step2-optional';
  const submitting = state === 'submitting';
  const failure = state === 'submit-failure';
  const resume = state === 'resume-draft';
  const nameError =
    state === 'duplicate' ? 'A deck with this name already exists in your Library.'
    : state === 'name-too-long' ? 'Use a shorter deck name.'
    : null;
  const deckName = state === 'name-too-long' ? LONG_NAME
    : (state === 'duplicate' || resume || state === 'step2' || optional || submitting || failure) ? 'Korean TOPIK I'
    : '';

  /* §7 success — lands in the REAL Library with the first-deck callout, composed (not a hand-built
     copy). Library's first-deck-created state owns the deck highlight + celebratory callout. */
  if (state === 'success') return window.Library({ state: 'first-deck-created' });

  // Submit lifecycle: exactly ONE primary CTA. On failure the callout only reports the error and
  // the bottom CTA becomes "Try again"; while submitting the whole form is locked (back + fields
  // + Change + Show all disabled), only the "Creating…" CTA stays.
  return (
    <MxScaffold node="create-deck-firstrun/screen" appBar={stepBar('Step 2 of 2', 'create-deck-firstrun/s2-back', submitting)}>
      {failure ? (
        <window.ActionCallout node="create-deck-firstrun/error" tone="error" icon="error"
          text="Couldn’t create the deck. Your information is still here." />
      ) : null}
      {resume ? (
        <window.ActionCallout node="create-deck-firstrun/resume" tone="info" icon="history"
          text="We kept your draft."
          action={<MxLink size="sm" trailingIcon={null} node="create-deck-firstrun/start-over">Start over</MxLink>} />
      ) : null}

      <h1 style={{ margin: 0, fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-extrabold)' }}>Create your first deck</h1>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-6)', ...(submitting ? DISABLED : {}) }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--memox-space-3)' }}>
          <span style={{ fontSize: 'var(--memox-font-size-base)', fontWeight: 'var(--memox-font-weight-medium)' }}>Korean → Vietnamese</span>
          <MxLink size="sm" trailingIcon={null} disabled={submitting} node="create-deck-firstrun/change-pair">Change</MxLink>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
          <SectionLabel>REQUIRED</SectionLabel>
          <Field label="Deck name *" value={deckName} placeholder="Name your deck" error={nameError} node="create-deck-firstrun/name" />
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <SectionLabel>OPTIONAL</SectionLabel>
            <MxLink size="sm" trailingIcon={null} disabled={submitting} node="create-deck-firstrun/optional-toggle">{optional ? 'Hide' : 'Show'}</MxLink>
          </div>
          {optional ? (
            <Field label="Description" value="Vocabulary and grammar for TOPIK I" placeholder="Add a description" node="create-deck-firstrun/description" />
          ) : null}
        </div>
      </div>

      <MxButton variant="primary" icon={submitting ? undefined : 'add'} block disabled={submitting} node={failure ? 'create-deck-firstrun/retry' : 'create-deck-firstrun/create-deck'}>
        {submitting ? 'Creating…' : failure ? 'Try again' : 'Create deck'}
      </MxButton>
    </MxScaffold>
  );
}

window.CreateDeckFirstRun = CreateDeckFirstRun;
})();

export const CreateDeckFirstRun = window.CreateDeckFirstRun;
