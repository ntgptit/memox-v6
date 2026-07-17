/* MemoX — Card Editor. A focused create/update form for ONE flashcard; single primary
   action = Save (a sticky full-width button at the bottom, easy to reach one-handed).
   Progressive disclosure: the default view shows only Term → Meaning (+ tags); Example,
   translation and advanced options are one tap away, so a blank card fits one screen with
   no scroll.
   10 states: create · edit · validation · duplicate · additional-translation ·
   audio-generating · submitting · submit-error · submit-success · discard-confirm.
   Language labels are DECK-DRIVEN (never hard-coded) so every language pair reads correctly.
   Runtime keyboard/focus intent is annotated on the fields (see Field.jsx) for production.
   Dirty-cancel (KIT-25-06): production tracks `isDirty` = "any field diverged from the loaded
   card". Cancel (X) and hardware BACK are GUARDED — if isDirty they open the discard-confirm
   overlay (the shared ConfirmDialog, same reference as Deck Settings) instead of closing; if
   clean they close immediately. The `discard-confirm` state renders that overlay.
   Feature-local components: components/{Field,DupBanner,AudioRow}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxButton, MxIconButton, MxChip, MxSwitch } = NS;
const { Field, DupBanner, AudioRow } = window.MemoXFlashcardEditor;

// Deck defines the language pair; the editor reads term/meaning/alt languages from it.
// Beginner Grammar = Korean term → English meaning, with an optional Vietnamese translation.
const DECK = {
  name: 'Beginner Grammar',
  term: { label: '한국어', code: 'ko' },
  meaning: { label: 'English', code: 'en' },
  alt: { label: 'Tiếng Việt', code: 'vi' },
};

// Prominent deck-context pill — anchors which deck the card is saved into without
// outweighing the screen title.
function DeckContext() {
  return (
    <div data-mx-node="flashcard-editor/deck-context" style={{ alignSelf: 'flex-start', display: 'inline-flex', alignItems: 'center', gap: 'var(--memox-space-2)', padding: 'var(--memox-space-2) var(--memox-space-3)', borderRadius: 'var(--memox-radius-pill)', background: 'var(--memox-surface-sunken)' }}>
      <span className="material-symbols-rounded" aria-hidden="true" style={{ fontSize: 'var(--memox-icon-size-sm)', color: 'var(--memox-primary)' }}>folder</span>
      <span style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-tertiary)' }}>Deck</span>
      <span style={{ fontSize: 'var(--memox-font-size-base)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text)' }}>{DECK.name}</span>
    </div>
  );
}

// Recoverable inline banner (submit error / success) — same soft-tone treatment as the
// Library offline/error banners; carries an optional action.
function Banner({ tone, icon, text, action, node }) {
  const bg = tone === 'error' ? 'var(--memox-error-soft)' : tone === 'success' ? 'var(--memox-success-soft)' : 'var(--memox-warning-soft)';
  const fg = tone === 'error' ? 'var(--memox-on-error-soft)' : tone === 'success' ? 'var(--memox-on-success-soft)' : 'var(--memox-on-warning-soft)';
  return (
    <div data-mx-node={node} role="status" style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-card)', background: bg, color: fg }}>
      <span className="material-symbols-rounded" aria-hidden="true" style={{ fontSize: 'var(--memox-icon-size-md)', flexShrink: 0 }}>{icon}</span>
      <div style={{ flex: 1, minWidth: 0, fontSize: 'var(--memox-font-size-sm)', lineHeight: 'var(--memox-line-height-normal)' }}>{text}</div>
      {action ? <div style={{ flexShrink: 0 }}>{action}</div> : null}
    </div>
  );
}

// Compact tag input — chips for filtering / SRS cycles. Low-weight surface, never competes
// with Term/Meaning.
function TagsField({ tags, disabled }) {
  return (
    <div data-mx-node="flashcard-editor/tags" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)', opacity: disabled ? 'var(--memox-opacity-muted)' : 1 }}>
      <label style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text-secondary)' }}>Tags</label>
      <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: 'var(--memox-space-2)', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-2) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: 'var(--memox-surface)', border: 'var(--memox-stroke-hairline) solid var(--memox-divider)' }}>
        <span className="material-symbols-rounded" aria-hidden="true" style={{ fontSize: 'var(--memox-icon-size-sm)', color: 'var(--memox-text-tertiary)', flexShrink: 0 }}>sell</span>
        {tags && tags.length
          ? tags.map((t, i) => <MxChip key={i} label={t} node={'flashcard-editor/tag-' + i} />)
          : <span style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-tertiary)' }}>Add tags — e.g. #TOPIK_I, #동사</span>}
      </div>
    </div>
  );
}

// Compact "hide during study" switch (advanced) — tucked inside More options, flat sunken
// surface, switch trailing. No icon tile, no elevation.
function VisibilityRow({ disabled }) {
  const [on, setOn] = React.useState(false);
  return (
    <div data-mx-node="flashcard-editor/visibility" style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: 'var(--memox-surface-sunken)', opacity: disabled ? 'var(--memox-opacity-muted)' : 1 }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 'var(--memox-font-weight-semibold)', fontSize: 'var(--memox-font-size-base)' }}>Hide during study</div>
        <div style={{ marginTop: 'var(--memox-space-1)', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>Excluded from study and review sessions.</div>
      </div>
      <MxSwitch checked={on} onChange={setOn} disabled={disabled} node="flashcard-editor/visibility-switch" ariaLabel="Hide during study" />
    </div>
  );
}

// "Keep adding" option — a checkbox that changes what Save does (see spec / runtime notes):
// checked → save, transient toast, clear the form, refocus Term (rapid entry); unchecked →
// save and return to the card list. Production persists the last choice so it's a one-time tick.
function KeepAdding({ initial, disabled }) {
  const [on, setOn] = React.useState(!!initial);
  return (
    <button type="button" role="checkbox" aria-checked={on} onClick={() => setOn((v) => !v)}
      data-mx-node="flashcard-editor/keep-adding" data-persist="last-choice" disabled={disabled}
      style={{ display: 'inline-flex', alignItems: 'center', gap: 'var(--memox-space-2)', alignSelf: 'flex-start', padding: 'var(--memox-space-1) 0', border: 'none', background: 'transparent', cursor: 'pointer', opacity: disabled ? 'var(--memox-opacity-muted)' : 1 }}>
      <span className="material-symbols-rounded" aria-hidden="true" style={{ fontSize: 'var(--memox-icon-size-md)', color: on ? 'var(--memox-primary)' : 'var(--memox-text-tertiary)' }}>{on ? 'check_box' : 'check_box_outline_blank'}</span>
      <span style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)' }}>Create another card after saving</span>
    </button>
  );
}

// Sticky bottom action bar — the single primary CTA, full-width, always reachable one-handed
// even with the keyboard open. Width/label stable so it never shifts across submit states.
// Carries the "keep adding" checkbox above Save, where the option is applied.
function SaveBar({ label, disabled, keepAdding }) {
  return (
    <div data-mx-node="flashcard-editor/save-bar" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)', padding: 'var(--memox-space-3) var(--memox-space-4) var(--memox-space-4)', borderTop: 'var(--memox-stroke-hairline) solid var(--memox-divider)', background: 'var(--memox-surface)' }}>
      <KeepAdding initial={keepAdding} disabled={disabled} />
      <MxButton variant="primary" block disabled={disabled} node="flashcard-editor/save">{label}</MxButton>
    </div>
  );
}

function FlashcardEditor({ state = 'create' }) {
  // discard-confirm renders the form as 'edit' (overlay on top); keyboard-open renders the
  // populated edit form with a simulated software keyboard raised (KIT-25-04/35-01/36-01).
  // registry-state: keyboard-open
  const keyboardOpen = state === 'keyboard-open';
  const view = state === 'discard-confirm' || keyboardOpen ? 'edit' : state;
  const blank = view === 'create' || view === 'validation';
  const invalid = view === 'validation';
  const submitting = view === 'submitting';
  const success = view === 'submit-success';
  const submitError = view === 'submit-error';
  const title = view === 'create' ? 'New card' : 'Edit card';
  const disabledForm = submitting;                                   // freeze editable controls while saving
  const saveDisabled = view === 'create' || invalid || submitting || success; // never active on blank/invalid/pristine
  const saveLabel = submitting ? 'Saving…' : success ? 'Done' : 'Save';
  // isDirty (KIT-25-06): true once any field diverges from the loaded card. Editing an existing
  // card is the dirty case here; a pristine blank create is clean. Cancel/back consult this.
  const isDirty = view === 'edit';

  const term = blank ? '' : '안녕하세요';
  const meaning = blank ? '' : 'Hello (formal)';
  const tags = blank ? [] : ['#TOPIK_I', '#인사'];
  const [moreOpen, setMoreOpen] = React.useState(view === 'edit');

  // Focused app bar: Close (X) · title · (no top-right — Save moved to the sticky bottom bar).
  // Cancel is the GUARDED exit (KIT-25-06): data-guard="dirty" → when isDirty the handler opens
  // discard-confirm instead of closing; when clean it closes straight away. Same guard applies
  // to hardware/gesture back. (Static kit annotates intent; Flutter wires the handler.)
  const bar = (
    <MxContextualAppBar variant="modal" node="flashcard-editor/appbar" title={title}
      leading={<MxIconButton icon="close" size="sm" node="flashcard-editor/cancel" ariaLabel="Cancel"
        data-guard="dirty" data-is-dirty={isDirty ? 'true' : 'false'} disabled={submitting} />}
      actions={<span aria-hidden="true" />} />
  );

  // Keyboard-avoidance layout (KIT-25-04/35-01): the SaveBar is the first child of the
  // bottomNav slot and the faux keyboard is BELOW it, so the sticky primary action stays
  // pinned directly above the keyboard and never gets covered. Short-portrait stress
  // (KIT-36-01): the body scrolls under the app bar so on the shortest supported portrait
  // (~640px tall) Term + Meaning + SaveBar remain reachable — the keyboard only ever
  // overlays the scrolling body, never the SaveBar.
  const bottomBar = keyboardOpen
    ? <React.Fragment><SaveBar label={saveLabel} disabled={saveDisabled} keepAdding /><window.KeyboardInset node="flashcard-editor/keyboard" /></React.Fragment>
    : <SaveBar label={saveLabel} disabled={saveDisabled} keepAdding={view === 'edit'} />;

  const screen = (
    <MxScaffold node="flashcard-editor/screen" appBar={bar} bottomNav={bottomBar}>
      <DeckContext />

      {view === 'duplicate' ? <DupBanner /> : null}
      {submitError ? <Banner node="flashcard-editor/save-error" tone="error" icon="error_outline" text="Couldn’t save the card. Your changes are still here." action={<MxButton variant="secondary" size="sm" node="flashcard-editor/save-retry">Try again</MxButton>} /> : null}
      {success ? <Banner node="flashcard-editor/save-success" tone="success" icon="check_circle" text="Card saved." /> : null}

      {/* CARD CONTENT — the primary focus. Term & Meaning share the same base height; Meaning
          grows as it wraps. Labels are deck-driven; pronunciation is a compact icon in Term. */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
        <Field label={'Term · ' + DECK.term.label} required node="flashcard-editor/term"
          value={term} placeholder="Enter a term"
          lang={DECK.term.code} inputMode="text" autoFocus={view === 'create'} enterKeyHint="next"
          focused={keyboardOpen}
          error={invalid ? 'Enter a term.' : null} disabled={disabledForm}
          trailing={<AudioRow status={view === 'audio-generating' ? 'generating' : 'auto'} />} />

        <Field label={'Meaning · ' + DECK.meaning.label} required multiline node="flashcard-editor/meaning"
          value={meaning} placeholder="Enter the meaning"
          lang={DECK.meaning.code} enterKeyHint="next"
          labelAction={<MxIconButton icon="add" size="sm" node="flashcard-editor/add-translation" ariaLabel={'Add ' + DECK.alt.label + ' translation'} disabled={disabledForm} />}
          error={invalid ? 'Enter a meaning.' : null} disabled={disabledForm} />

        {/* Additional translation — expands under Meaning; language-scoped, with a Remove action */}
        {view === 'additional-translation'
          ? <Field label={'Translation · ' + DECK.alt.label} node="flashcard-editor/translation"
              value="Xin chào" placeholder="Enter a translation" lang={DECK.alt.code}
              labelAction={<MxIconButton icon="close" size="sm" node="flashcard-editor/translation-remove" ariaLabel="Remove translation" />} />
          : null}
      </div>

      <TagsField tags={tags} disabled={disabledForm} />

      {/* MORE OPTIONS — collapsed by default so the base form stays Term → Meaning. Holds the
          optional Example pair and the advanced Hide-during-study switch. */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
        {/* Collapsible show-more control (KIT-21-03): aria-expanded exposes the
            open/closed state to AT, aria-controls points at the region it toggles.
            Attribute-only — no pixel change to the existing shots. */}
        <button type="button" onClick={() => setMoreOpen((v) => !v)} data-mx-node="flashcard-editor/more-toggle"
          aria-expanded={moreOpen} aria-controls="flashcard-editor/more-region"
          style={{ alignSelf: 'flex-start', display: 'inline-flex', alignItems: 'center', gap: 'var(--memox-space-1)', padding: 'var(--memox-space-2) 0', border: 'none', background: 'transparent', cursor: 'pointer', fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text-secondary)' }}>
          <span className="material-symbols-rounded" aria-hidden="true" style={{ fontSize: 'var(--memox-icon-size-sm)' }}>{moreOpen ? 'expand_less' : 'expand_more'}</span>
          More options
        </button>
        {moreOpen ? (
          <div id="flashcard-editor/more-region" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
            <Field label="Example" multiline node="flashcard-editor/example"
              value={blank ? '' : '오늘 날씨가 좋네요.'} placeholder="Add an example sentence"
              lang={DECK.term.code} disabled={disabledForm} />
            <Field label="Example translation" multiline node="flashcard-editor/example-translation"
              value={blank ? '' : 'The weather is nice today.'} placeholder="Translate the example"
              lang={DECK.meaning.code} disabled={disabledForm} />
            <VisibilityRow disabled={disabledForm} />
          </div>
        ) : null}
      </div>
    </MxScaffold>
  );

  // Dirty-cancel overlay (KIT-25-06): reuses the shared ConfirmDialog. Copy names the loss
  // ("Discard changes?"), keeps the safe path as the ghost default, and makes Discard the
  // destructive action. Dismiss returns to the still-populated editor (nothing is lost).
  if (state === 'discard-confirm') {
    const ConfirmDialog = window.ConfirmDialog;
    return (
      <React.Fragment>
        {screen}
        <ConfirmDialog align="center" scrimNode="flashcard-editor/discard-scrim"
          icon="delete_outline" tone="error" title="Discard changes?"
          text="You’ve edited this card. If you leave now, your changes won’t be saved."
          dialogNode="flashcard-editor/discard-dialog"
          actions={<React.Fragment>
            <MxButton variant="ghost" block node="flashcard-editor/discard-cancel">Keep editing</MxButton>
            <MxButton variant="primary" danger block node="flashcard-editor/discard-ok">Discard</MxButton>
          </React.Fragment>} />
      </React.Fragment>
    );
  }

  return screen;
}

window.FlashcardEditor = FlashcardEditor;
})();

export const FlashcardEditor = window.FlashcardEditor;
