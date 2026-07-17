/* MemoX — Flashcard-editor local: DupBanner. A compact WARNING (not an error — a duplicate
   isn't a system failure) that steers the user to the safe action. Hierarchy: "View existing"
   is the emphasized action; "Add anyway" is a low-emphasis ghost override. Actions wrap safely
   at 320px. No nested card. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxButton } = NS;

function DupBanner() {
  return (
    <div data-mx-node="flashcard-editor/dup-warning" role="status" style={{ background: 'var(--memox-warning-soft)', color: 'var(--memox-on-warning-soft)', borderRadius: 'var(--memox-radius-control)', padding: 'var(--memox-space-3) var(--memox-space-4)', display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
      <div style={{ display: 'flex', gap: 'var(--memox-space-2)', alignItems: 'flex-start' }}>
        <span className="material-symbols-rounded" aria-hidden="true" style={{ fontSize: 'var(--memox-icon-size-md)', flexShrink: 0 }}>warning</span>
        <span style={{ flex: 1, minWidth: 0, fontSize: 'var(--memox-font-size-sm)', lineHeight: 'var(--memox-line-height-normal)' }}>A card “안녕하세요” already exists in this deck.</span>
      </div>
      <div style={{ display: 'flex', gap: 'var(--memox-space-2)', flexWrap: 'wrap' }}>
        <MxButton variant="secondary" size="sm" node="flashcard-editor/dup-view">View existing</MxButton>
        <MxButton variant="ghost" size="sm" node="flashcard-editor/dup-add">Add anyway</MxButton>
      </div>
    </div>
  );
}

window.MemoXFlashcardEditor = window.MemoXFlashcardEditor || {};
window.MemoXFlashcardEditor.DupBanner = DupBanner;
})();

export const DupBanner = (window.MemoXFlashcardEditor || {}).DupBanner;
