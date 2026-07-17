/* DeckCard — the ONE deck/subdeck list card, shared across Dashboard, Library, search…
   Standardized from Dashboard "Recent decks" so anatomy + spacing never drift between
   screens. Anatomy: [ visual ] [ title / meta (+ optional progress) ] [ trailing ].
   - visual: an MxIconTile (icon+tone) OR a progress Ring (pass `ring`) OR, in selection
     mode, a check/radio indicator (pass `selected`).
   - trailing: any node (a due MxBadge, a quick-study MxIconButton…). Hidden in selection.
   - newBadge: light "just created" marker — a soft "New" pill takes the trailing slot; the card
     stays a STANDARD deck row (no thick border, no full selected tint, same layout) so it reads
     as newly-created, not selected/focused.
   Registered on window for the runtime gallery; ESM-exported for the compiler. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxCard, MxIconTile, MxBadge } = NS;

function DeckCard({ icon, tone = 'accent', ring, title, titleWeight, meta, progress, trailing, selected, newBadge, node }) {
  let visual;
  if (selected != null) {
    visual = <span className="material-symbols-rounded" style={{ flexShrink: 0, fontSize: 'var(--memox-icon-size-lg)', color: selected ? 'var(--memox-accent)' : 'var(--memox-text-tertiary)' }}>{selected ? 'check_circle' : 'radio_button_unchecked'}</span>;
  } else if (ring != null) {
    visual = <div style={{ flexShrink: 0 }}><window.Ring pct={ring} size={40}>{ring >= 100
      ? <span className="material-symbols-rounded" aria-label="Complete" style={{ fontSize: 'var(--memox-icon-size-sm)', color: 'var(--memox-success)' }}>check</span>
      : <span style={{ fontSize: 'var(--memox-font-size-xs)', fontWeight: 'var(--memox-font-weight-bold)' }}>{ring}%</span>}</window.Ring></div>;
  } else {
    visual = <MxIconTile icon={icon} tone={tone} />;
  }
  return (
    <MxCard padding="sm" interactive variant={selected ? 'primary-soft' : undefined} node={node}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-4)', minWidth: 0 }}>
        {visual}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: titleWeight || 'var(--memox-font-weight-bold)', fontSize: 'var(--memox-font-size-base)', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', overflowWrap: 'anywhere' }}>{title}</div>
          <div style={{ marginTop: 'var(--memox-space-1)', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{meta}</div>
          {progress != null ? <div style={{ marginTop: 'var(--memox-space-2)' }}><window.ProgressBar value={progress} height={6} /></div> : null}
        </div>
        {selected != null ? null : (newBadge ? <MxBadge soft node={node ? node + '-new' : undefined}>New</MxBadge> : (trailing || null))}
      </div>
    </MxCard>
  );
}

window.DeckCard = DeckCard;
})();

export const DeckCard = window.DeckCard;
