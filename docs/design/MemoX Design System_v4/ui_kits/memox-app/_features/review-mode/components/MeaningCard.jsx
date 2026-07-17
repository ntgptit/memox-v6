/* MemoX — Review local: MeaningCard (meaning + inline edit affordance). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard, MxIconButton, MxButton } = NS;

function MeaningCard({ editing }) {
  return (
    <MxCard node="review-mode/meaning" style={{ flex: 1, gap: 'var(--memox-space-3)' }}>
      <div style={{ display: 'flex', alignItems: 'center' }}>
        <window.SectionLabel style={{ flex: 1, margin: 0 }}>MEANING</window.SectionLabel>
        <MxIconButton icon={editing ? 'close' : 'edit'} size="sm" node="review-mode/edit" />
      </div>
      {editing ? (
        <React.Fragment>
          <div style={{ border: 'var(--memox-stroke-emphasis) solid var(--memox-primary)', borderRadius: 'var(--memox-radius-control)', padding: 'var(--memox-space-3) var(--memox-space-4)', fontSize: 'var(--memox-font-size-md)', fontWeight: 'var(--memox-font-weight-bold)' }}>school<span style={{ color: 'var(--memox-primary)' }}>|</span></div>
          <div style={{ display: 'flex', gap: 'var(--memox-space-2)', justifyContent: 'flex-end' }}>
            <MxButton variant="ghost" size="sm" node="review-mode/edit-cancel">Cancel</MxButton>
            <MxButton variant="primary" size="sm" node="review-mode/edit-save">Save</MxButton>
          </div>
        </React.Fragment>
      ) : (
        <div style={{ fontSize: 'var(--memox-font-size-xl)', fontWeight: 'var(--memox-font-weight-bold)' }}>school</div>
      )}
    </MxCard>
  );
}

window.MemoXReviewMode = window.MemoXReviewMode || {};
window.MemoXReviewMode.MeaningCard = MeaningCard;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const MeaningCard = (window.MemoXReviewMode || {}).MeaningCard;
