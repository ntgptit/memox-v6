/* MemoX — Theme local: PreviewCard (live term/meaning/CTA preview of the theme). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard } = NS;

function PreviewCard({ termSize, accentColor }) {
  return (
    <MxCard node="theme/preview" style={{ gap: 'var(--memox-space-3)' }}>
      <window.SectionLabel style={{ margin: 0 }}>PREVIEW</window.SectionLabel>
      <div style={{ borderRadius: 'var(--memox-radius-control)', border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', padding: 'var(--memox-space-6)', textAlign: 'center' }}>
        <div style={{ fontSize: termSize, fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>학교</div>
        <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)' }}>school</div>
        <div style={{ marginTop: 'var(--memox-space-4)', display: 'inline-block', padding: 'var(--memox-space-2) var(--memox-space-6)', borderRadius: 'var(--memox-radius-pill)', background: accentColor, color: 'var(--memox-on-primary)', fontWeight: 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-sm)' }}>Study now</div>
      </div>
    </MxCard>
  );
}

window.MemoXTheme = window.MemoXTheme || {};
window.MemoXTheme.PreviewCard = PreviewCard;
})();

/* ESM export so the design-system compiler indexes this kit composite. */
export const PreviewCard = (window.MemoXTheme || {}).PreviewCard;
