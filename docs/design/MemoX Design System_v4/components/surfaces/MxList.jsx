/* MxList — the ONE vertical list wrapper for ANY stack of cards (decks, subdecks,
   flashcards, search results…). Owns the standard inter-card gap (space-3 = 12px, matching
   Dashboard "Recent decks") so every list in the app spaces its items identically. Always
   wrap a card list in this instead of dropping cards straight into the scroll body (whose
   section gap is the larger 24px). Optional `gap` token overrides the default.

   Runtime-authored (IIFE + global React) on the NS namespace like MxLink, so the kit gallery
   can load it via <script type="text/babel-src"> without a bundle rebuild; ESM-exported too. */
(function () {
  const NS = (window.MemoXDesignSystem_2ffa54 = window.MemoXDesignSystem_2ffa54 || {});

  function MxList({ children, node, gap }) {
    return (
      <div data-mx-node={node} style={{ display: 'flex', flexDirection: 'column', gap: gap || 'var(--memox-space-3)' }}>
        {children}
      </div>
    );
  }

  NS.MxList = MxList;
})();

export const MxList = (window.MemoXDesignSystem_2ffa54 || {}).MxList;
