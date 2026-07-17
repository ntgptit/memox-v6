/* MemoX — Flashcard-editor local: AudioRow. The pronunciation control, collapsed from a
   full-width row into a COMPACT icon button that sits inside the Term field (trailing slot).
   Pronunciation is auto-generated from the term, so it no longer needs its own section — a
   tap plays it; no autoplay. Status: auto (speaker, tap to hear) · generating (spinner,
   disabled) · ready (speaker) · error (retry icon). Kept as the `AudioRow` export + stable
   `flashcard-editor/audio-*` nodes so the component id/contract stays stable. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;

function AudioRow({ status = 'auto' }) {
  const { MxIconButton } = NS;
  const MAP = {
    auto:       { icon: 'volume_up', node: 'flashcard-editor/audio-play',  label: 'Play pronunciation' },
    ready:      { icon: 'volume_up', node: 'flashcard-editor/audio-play',  label: 'Play pronunciation' },
    generating: { loading: true,     node: 'flashcard-editor/audio-play',  label: 'Generating pronunciation' },
    error:      { icon: 'error', tone: 'error', node: 'flashcard-editor/audio-retry', label: 'Retry pronunciation' },
  };
  const s = MAP[status] || MAP.auto;
  if (s.loading) {
    return (
      <span data-mx-node="flashcard-editor/audio-row" role="status" aria-label="Generating pronunciation"
        style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 'var(--memox-touch-min)', height: 'var(--memox-touch-min)', flexShrink: 0 }}>
        <span className="spinner" aria-hidden="true" />
      </span>
    );
  }
  return (
    <span data-mx-node="flashcard-editor/audio-row" style={{ display: 'inline-flex', flexShrink: 0, color: s.tone === 'error' ? 'var(--memox-error)' : 'var(--memox-text-secondary)' }}>
      <MxIconButton icon={s.icon} size="sm" node={s.node} ariaLabel={s.label} />
    </span>
  );
}

window.MemoXFlashcardEditor = window.MemoXFlashcardEditor || {};
window.MemoXFlashcardEditor.AudioRow = AudioRow;
})();

export const AudioRow = (window.MemoXFlashcardEditor || {}).AudioRow;
