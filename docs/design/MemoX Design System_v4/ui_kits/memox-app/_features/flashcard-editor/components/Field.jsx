/* MemoX — Flashcard-editor local: Field. A labeled text field used ONLY for real user
   input (Term, Meaning, Translation, Example…). Anatomy: label row (label + optional
   labelAction) · input surface · supporting or error text. Visual states: default · filled ·
   focused (accent border) · error (error border + message) · disabled (sunken, dimmed).
   NOT for audio/settings/status rows.

   Term and Meaning share the SAME base height (min = touch target); multiline just lets the
   surface grow line-by-line as content wraps — so a short meaning matches the term height and
   a long one extends downward.

   Runtime keyboard intent (production behaviour the static kit can't execute) is recorded as
   design-intent data-* annotations: data-lang, data-input-mode, data-autofocus,
   data-enter-key-hint. Production maps these to the real input's lang/inputMode/autoFocus/
   enterKeyHint so the OS shows the right keyboard and Next/Done flows field-to-field.

   Validation timing (KIT-25-03) — the static kit shows one `error` snapshot, but the runtime
   contract, recorded on `data-validate-on`, is: (1) a REQUIRED/format error surfaces on BLUR,
   but only once the field has been touched (never while the user is still typing a pristine
   field); (2) on SUBMIT, every still-invalid field validates at once and focus moves to the
   first error; (3) ASYNC checks (e.g. duplicate term) resolve after the server responds and
   render through the same `error` slot. Errors are exposed to AT: the input carries
   aria-invalid and the message is a role="alert" live region so it is spoken when it appears. */
(function () {
function Field({ label, labelAction, value, placeholder, multiline, error, supporting, required, disabled, focused, node, trailing, lang, inputMode, autoFocus, enterKeyHint }) {
  const emphasis = focused || error;
  const borderColor = error ? 'var(--memox-error)' : focused ? 'var(--memox-accent)' : 'var(--memox-divider)';
  return (
    <div data-mx-node={node} style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)', opacity: disabled ? 'var(--memox-opacity-muted)' : 1 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--memox-space-2)' }}>
        <label style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-1)', fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text-secondary)' }}>
          {label}{required ? <span style={{ color: 'var(--memox-error)' }} aria-hidden="true">*</span> : null}
        </label>
        {labelAction || null}
      </div>
      <div
        data-lang={lang || null}
        data-input-mode={inputMode || null}
        data-autofocus={autoFocus ? 'true' : null}
        data-enter-key-hint={enterKeyHint || null}
        data-validate-on="blur-then-submit"
        aria-invalid={error ? 'true' : null}
        style={{ display: 'flex', alignItems: multiline ? 'flex-start' : 'center', gap: 'var(--memox-space-2)', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: disabled ? 'var(--memox-surface-sunken)' : 'var(--memox-surface)', border: (emphasis ? 'var(--memox-stroke-emphasis)' : 'var(--memox-stroke-hairline)') + ' solid ' + borderColor }}>
        <span style={{ flex: 1, minWidth: 0, fontSize: 'var(--memox-font-size-base)', color: value ? 'var(--memox-text)' : 'var(--memox-text-tertiary)', lineHeight: 'var(--memox-line-height-normal)', whiteSpace: multiline ? 'normal' : 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', overflowWrap: 'anywhere' }}>{value || placeholder}</span>
        {trailing}
      </div>
      {error
        ? <div role="alert" style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-error)' }}>{error}</div>
        : supporting
          ? <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-tertiary)' }}>{supporting}</div>
          : null}
    </div>
  );
}

window.MemoXFlashcardEditor = window.MemoXFlashcardEditor || {};
window.MemoXFlashcardEditor.Field = Field;
})();

export const Field = (window.MemoXFlashcardEditor || {}).Field;
