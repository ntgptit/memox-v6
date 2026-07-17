/* MemoX shared composite: StatusCardRow — term + meaning (+ optional deck line) with a
   status badge. Owns the single new/due/mastered STATUS map shared by the Flashcard List
   (every card row) and Search (ResultRow).
   Layout: a top row pins the term (left) and the status badge (right) together, and the
   meaning flows FULL-WIDTH below the row.
   Render variants encode the only differences between callers:
     - tightTerm       : tighten the term letter-spacing
     - truncateMeaning : ellipsis-clip the meaning to one line (Search)
     - clampMeaning    : COLLAPSIBLE meaning — clamp to N lines (true → 1). A "Show more" toggle
                         row is ALWAYS reserved (invisible/inert until the meaning overflows),
                         so EVERY card is exactly the same height; the toggle expands the
                         meaning in place on demand (Flashcard List).
   search adds a `deck` line under the meaning. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxBadge } = NS;

const STATUS = {
  new: { label: 'New', tone: undefined },
  due: { label: 'Due', tone: 'error' },
  mastered: { label: 'Mastered', tone: 'success' },
};

function StatusCardRow({ term, meaning, deck, status, hidden, node, onClick, tightTerm, truncateMeaning, clampMeaning }) {
  const s = STATUS[status];
  // Collapsible meaning: clamp to a fixed N lines so every card keeps a uniform, bounded
  // height no matter how long the meaning is; a "Show more" toggle expands it in place.
  const collapsible = !!clampMeaning && !truncateMeaning;
  const lines = typeof clampMeaning === 'number' ? clampMeaning : 1;
  const [expanded, setExpanded] = React.useState(false);
  const [overflowing, setOverflowing] = React.useState(false);
  const meaningRef = React.useRef(null);
  React.useLayoutEffect(() => {
    if (!collapsible) return undefined;
    let done = false;
    const measure = () => { const el = meaningRef.current; if (el && !done) setOverflowing(el.scrollHeight > el.clientHeight + 1); };
    measure(); // fonts are already warmed by the time screens render; re-measure once ready anyway
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(measure);
    return () => { done = true; };
  }, [meaning, collapsible, lines]);

  const termStyle = { fontWeight: 'var(--memox-font-weight-extrabold)', fontSize: 'var(--memox-font-size-md)' };
  if (tightTerm) termStyle.letterSpacing = 'var(--memox-letter-spacing-tight)';
  const meaningStyle = { fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)', overflowWrap: 'anywhere' };
  if (truncateMeaning) { meaningStyle.whiteSpace = 'nowrap'; meaningStyle.overflow = 'hidden'; meaningStyle.textOverflow = 'ellipsis'; }
  else if (collapsible && !expanded) { meaningStyle.display = '-webkit-box'; meaningStyle.WebkitLineClamp = lines; meaningStyle.WebkitBoxOrient = 'vertical'; meaningStyle.overflow = 'hidden'; }
  return (
    <div data-mx-node={node} onClick={onClick} style={{ opacity: hidden ? .5 : 1 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)' }}>
        <div style={{ flex: 1, minWidth: 0, display: 'flex', alignItems: 'center', gap: 'var(--memox-space-2)' }}>
          <span style={termStyle}>{term}</span>
          {hidden ? <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-tertiary)' }}>visibility_off</span> : null}
        </div>
        <div style={{ flexShrink: 0 }}><MxBadge tone={s.tone} soft>{s.label}</MxBadge></div>
      </div>
      <div ref={meaningRef} style={meaningStyle}>{meaning}</div>
      {collapsible ? (
        // Always render the toggle row so every card reserves the same height (uniform cards);
        // it stays invisible/inert until the 1-line meaning actually overflows.
        <button type="button" className="card-more" data-mx-node={node ? node + '-more' : undefined}
          aria-hidden={overflowing || expanded ? undefined : true} tabIndex={overflowing || expanded ? undefined : -1}
          style={overflowing || expanded ? undefined : { visibility: 'hidden', pointerEvents: 'none' }}
          onClick={(e) => { e.stopPropagation(); setExpanded((v) => !v); }}>{expanded ? 'Show less' : 'Show more'}</button>
      ) : null}
      {deck ? <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-tertiary)', marginTop: 'var(--memox-space-1)' }}>{deck}</div> : null}
    </div>
  );
}

window.StatusCardRow = StatusCardRow;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const StatusCardRow = window.StatusCardRow;
