/* MemoX — nested deck list: a deck's child decks, one level down. Rendered as the Library
   screen's nested mode (Library delegates its nested-* states here). CHROME-IDENTICAL to the
   Library root — same FilterRow controls, deck cards (DeckRowCard), FAB and bottom nav (passed
   in as `nav`) — differing only by the back button + Breadcrumb this renderer adds for navigating
   up. A deck's child decks are still Decks (parentId != null); this is never a CARDS section.
   The same renderer serves every tree level (Korean › TOPIK I › Grammar › …).
   Frozen per AGENTS.md golden rule: every subdeck-list/* data-mx-node id stays stable. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxCard, MxIconButton, MxFab, MxButton, MxLink } = NS;
const { Scrim, Sheet, MenuItem, MenuList, SectionLabel, EmptyState, Skeleton } = window;
// i18n consumers (KIT-37-06/37-04/20-04) — safe accessors: if the i18n modules
// are not loaded the fallback returns the exact current literal (parity-neutral).
const t = (window.MemoXI18n && window.MemoXI18n.t) || ((k, fb) => fb);
const fmt = window.MemoXFormat || { relativeTime: (v, u) => Math.abs(v) + ' ' + u + (Math.abs(v) === 1 ? '' : 's') + (v < 0 ? ' ago' : '') };

function SubdeckList({ state = 'loaded', nav }) {
  const SL = window.MemoXSubdeckList;
  const { SUBDECKS, DENSE, CreateDeckSheet, TRAIL, TRAIL_DEEP } = SL;
  const LIB = window.MemoXLibrary;
  const DeckRowCard = LIB.DeckRowCard;
  const FilterRow = LIB.FilterRow;
  const MxList = NS.MxList;
  const Breadcrumb = window.Breadcrumb;

  const fab = <MxFab icon="add" node="subdeck-list/create" ariaLabel="Create deck" />;
  // The SAME controls row as the Library root — scoped to this screen's node prefix.
  const filter = <FilterRow prefix="subdeck-list" />;
  const nestedBar = (
    <MxContextualAppBar variant="nested" node="subdeck-list/appbar" title="Korean TOPIK I"
      actions={<React.Fragment>
        <MxIconButton icon="search" size="sm" node="subdeck-list/search-open" ariaLabel="Search decks" />
        <MxIconButton icon="more_vert" size="sm" node="subdeck-list/more" ariaLabel="Deck settings" />
      </React.Fragment>} />
  );
  const crumbs = (trail = TRAIL) => <Breadcrumb items={trail} node="subdeck-list/breadcrumb" />;
  const list = (arr) => <MxList>{arr.map((s, i) => <DeckRowCard key={i} s={s} index={i} nodePrefix="subdeck-list" />)}</MxList>;

  /* loading — filter-row + card skeletons (matches the Library root loading), keeps bottom nav */
  if (state === 'loading') {
    return (
      <MxScaffold node="subdeck-list/screen" appBar={nestedBar} bottomNav={nav} fab={fab}>
        <Skeleton h={40} r={999} />
        <MxList>{[0, 1, 2, 3].map((i) => <MxCard key={i} padding="sm"><div style={{ display: 'flex', gap: 'var(--memox-space-4)', alignItems: 'center' }}><Skeleton w={40} h={40} r={999} /><div style={{ flex: 1 }}><Skeleton w="60%" h={14} /><Skeleton w="40%" h={10} style={{ marginTop: 'var(--memox-space-2)' }} /></div></div></MxCard>)}</MxList>
      </MxScaffold>
    );
  }

  /* empty — deck was organised with nested decks, none created yet (distinct from the
     undecided Deck Content Choice). Mirrors Library empty: bottom nav, no FAB. */
  /* A parent that lost its last child deck is an EMPTY deck again (§15) → the unified Empty Deck
     screen (Add card / Create nested deck / Import), not a nested-only "no decks" message. */
  if (state === 'empty') return window.EmptyDeck({ state: 'default' });

  /* post-create success in a PARENT deck (§10 nested): the just-created EMPTY child deck (0 cards)
     lands highlighted at the TOP — shared DeckCard + light `newBadge` "New" pill — above the parent's
     existing children, with a "Deck created · Open" snackbar; the user stays in the parent.
     (library state nested-deck-created) */
  if (state === 'deck-created') {
    const { NEW_DECK_CHILD, deckMeta } = LIB;
    const newRow = <window.DeckCard key="new" icon={NEW_DECK_CHILD.icon} tone={NEW_DECK_CHILD.tone} title={NEW_DECK_CHILD.name} titleWeight="var(--memox-font-weight-semibold)" meta={deckMeta(NEW_DECK_CHILD)} newBadge node="subdeck-list/subdeck-new" />;
    return (
      <MxScaffold node="subdeck-list/screen" appBar={nestedBar} bottomNav={nav} fab={fab}>
        {crumbs()}{filter}
        <MxList>{[newRow, ...SUBDECKS.map((s, i) => <DeckRowCard key={i} s={s} index={i} nodePrefix="subdeck-list" />)]}</MxList>
        <window.Snackbar tone="success" text="Deck created" action={<MxLink size="sm" trailingIcon={null} className="snackbar-action" node="subdeck-list/created-open">Open</MxLink>} node="subdeck-list/created-snackbar" />
      </MxScaffold>
    );
  }

  /* offline — local decks still browsable (banner above the controls, like Library offline) */
  if (state === 'offline') {
    return (
      <MxScaffold node="subdeck-list/screen" appBar={nestedBar} bottomNav={nav} fab={fab}>
        {crumbs()}
        <div data-mx-node="subdeck-list/offline-banner" style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-card)', background: 'var(--memox-warning-soft)', color: 'var(--memox-on-warning-soft)' }}>
          <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-md)' }}>cloud_off</span>
          <div style={{ flex: 1, fontSize: 'var(--memox-font-size-sm)' }}>{t('subdeck.offline', 'Offline · showing saved decks. Last synced 2 hours ago.', { rel: fmt.relativeTime(-2, 'hour') })}</div>
          <MxLink size="sm" trailingIcon={null} node="subdeck-list/offline-retry">{t('common.retry', 'Retry')}</MxLink>
        </div>
        {filter}
        {list(SUBDECKS)}
      </MxScaffold>
    );
  }

  /* error — the deck failed to load */
  if (state === 'error') {
    return (
      <MxScaffold node="subdeck-list/screen" appBar={nestedBar} bottomNav={nav}>
        <EmptyState node="subdeck-list/error" icon="cloud_off" tone="error" title="Couldn't load decks"
          text="Something went wrong. Check your connection and try again."
          action={<MxButton variant="primary" icon="refresh" node="subdeck-list/retry">Retry</MxButton>} />
      </MxScaffold>
    );
  }

  /* search / no-results — search chrome takes over (no bottom nav, mirrors Library search) */
  if (state === 'search' || state === 'no-results') {
    const q = state === 'search' ? 'gr' : 'zzz';
    const bar = (
      <MxContextualAppBar variant="search" node="subdeck-list/appbar"
        search={{ value: q, placeholder: 'Search decks' }}
        actions={<MxIconButton icon="close" size="sm" node="subdeck-list/search-clear" ariaLabel="Clear search" />} />
    );
    if (state === 'no-results') {
      return <MxScaffold node="subdeck-list/screen" appBar={bar}><EmptyState node="subdeck-list/no-results" icon="search_off" tone="warning" title={'No decks for “zzz”'} text="Try another keyword." action={<MxButton variant="secondary" icon="close" node="subdeck-list/clear">Clear search</MxButton>} /></MxScaffold>;
    }
    const hits = SUBDECKS.filter((s) => /gr|fa/i.test(s.name));
    return (
      <MxScaffold node="subdeck-list/screen" appBar={bar}>
        <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>{hits.length} decks match</div>
        <SectionLabel>DECKS</SectionLabel>
        {list(hits)}
      </MxScaffold>
    );
  }

  /* selection — decks only; selection bar + bottom nav (mirrors Library selection) */
  if (state === 'selection') {
    const bar = (
      <MxContextualAppBar variant="selection" node="subdeck-list/appbar" count={2}
        actions={<React.Fragment>
          <MxIconButton icon="select_all" size="sm" node="subdeck-list/sel-all" ariaLabel="Select all" />
          <MxIconButton icon="more_vert" size="sm" node="subdeck-list/sel-more" ariaLabel="More actions" />
        </React.Fragment>} />
    );
    const sel = [true, false, true, false, false];
    return (
      <MxScaffold node="subdeck-list/screen" appBar={bar} bottomNav={nav}>
        <MxList>{SUBDECKS.map((s, i) => <DeckRowCard key={i} s={s} index={i} selected={sel[i]} nodePrefix="subdeck-list" />)}</MxList>
      </MxScaffold>
    );
  }

  /* create → Create Deck DIALOG with this parent as context (§13); no nested create sheet.
     CreateDeckSheet.jsx is kept as a component/node map for the app's current build. */
  if (state === 'create-sheet') return window.CreateDeckDialog({ state: 'nested' });

  /* subdeck-actions — a single deck's action sheet (deck-level, over the browse list) */
  if (state === 'subdeck-actions') {
    return (
      <React.Fragment>
        <MxScaffold node="subdeck-list/screen" appBar={nestedBar} bottomNav={nav} fab={fab}>{crumbs()}{filter}{list(SUBDECKS)}</MxScaffold>
        <Scrim align="end" node="subdeck-list/actions-scrim">
          <Sheet title="Greetings & introductions" node="subdeck-list/actions-sheet">
            <MenuItem icon="bolt" label="Study deck" node="subdeck-list/action-study" />
            <MenuItem icon="edit" label="Rename deck" node="subdeck-list/action-rename" />
            <MenuItem icon="drive_file_move" label="Move deck" node="subdeck-list/action-move" />
            <MenuItem icon="delete" label="Delete deck" danger node="subdeck-list/action-delete" />
          </Sheet>
        </Scrim>
      </React.Fragment>
    );
  }

  /* play — the Study chooser (session vs single mode), opened from a deck's Study (bolt)
     action or the "Study deck" row; "Single mode" is the entry into Mode Picker */
  if (state === 'play') {
    return (
      <React.Fragment>
        <MxScaffold node="subdeck-list/screen" appBar={nestedBar} bottomNav={nav} fab={fab}>{crumbs()}{filter}{list(SUBDECKS)}</MxScaffold>
        <window.DeckPlaySheet title="Greetings & introductions" />
      </React.Fragment>
    );
  }

  /* deep — a deck several levels down; the breadcrumb collapses its middle */
  if (state === 'deep') {
    const deepBar = (
      <MxContextualAppBar variant="nested" node="subdeck-list/appbar" title="Irregular verbs"
        actions={<React.Fragment>
          <MxIconButton icon="search" size="sm" node="subdeck-list/search-open" ariaLabel="Search decks" />
          <MxIconButton icon="more_vert" size="sm" node="subdeck-list/more" ariaLabel="Deck settings" />
        </React.Fragment>} />
    );
    return (
      <MxScaffold node="subdeck-list/screen" appBar={deepBar} bottomNav={nav} fab={fab}>
        {crumbs(TRAIL_DEEP)}
        {filter}
        {list(SUBDECKS)}
      </MxScaffold>
    );
  }

  /* not-found — the deck was deleted/moved on another device while it was open
     (KIT-23-02, deleted-entity detail state). Friendly copy + a SAFE back action
     to the Library (never a dead nested app bar with actions on a gone entity).
     App bar drops search/more (there is nothing here to search or configure);
     the bottom nav stays so the user can jump back into any tab. */
  if (state === 'not-found') {
    const goneBar = (
      <MxContextualAppBar variant="nested" node="subdeck-list/appbar" title="Korean TOPIK I"
        actions={<span aria-hidden="true" />} />
    );
    return (
      <MxScaffold node="subdeck-list/screen" appBar={goneBar} bottomNav={nav}>
        <EmptyState node="subdeck-list/not-found" icon="folder_off" tone="warning"
          title={t('subdeck.notFound.title', 'This deck no longer exists')}
          text={t('subdeck.notFound.body', 'It may have been deleted or moved on another device. Head back to your library to keep studying.')}
          action={<MxButton variant="primary" icon="arrow_back" node="subdeck-list/not-found-back">{t('subdeck.notFound.cta', 'Back to Library')}</MxButton>} />
      </MxScaffold>
    );
  }

  /* long-menu — a deck action sheet grown past the frame (KIT-29-03): the Sheet caps at
     85% height and its body scrolls; one action ("Move deck") is DISABLED (unavailable —
     this deck can't be moved out of a locked parent) to render the MenuItem disabled state.
     MenuList adds its own cap so the same overflow rule holds outside a Sheet too. */
  if (state === 'long-menu') {
    return (
      <React.Fragment>
        <MxScaffold node="subdeck-list/screen" appBar={nestedBar} bottomNav={nav} fab={fab}>{crumbs()}{filter}{list(SUBDECKS)}</MxScaffold>
        <Scrim align="end" node="subdeck-list/long-menu-scrim">
          <Sheet title="Greetings & introductions" node="subdeck-list/long-menu-sheet">
            <MenuList node="subdeck-list/long-menu-list">
              <MenuItem icon="bolt" label="Study deck" node="subdeck-list/lm-study" />
              <MenuItem icon="edit" label="Rename deck" node="subdeck-list/lm-rename" />
              <MenuItem icon="drive_file_move" label="Move deck" disabled node="subdeck-list/lm-move" />
              <MenuItem icon="content_copy" label="Duplicate deck" node="subdeck-list/lm-duplicate" />
              <MenuItem icon="push_pin" label="Pin to top" node="subdeck-list/lm-pin" />
              <MenuItem icon="label" label="Manage tags" node="subdeck-list/lm-tags" />
              <MenuItem icon="ios_share" label="Share deck" node="subdeck-list/lm-share" />
              <MenuItem icon="download" label="Export deck" node="subdeck-list/lm-export" />
              <MenuItem icon="archive" label="Archive deck" node="subdeck-list/lm-archive" />
              <MenuItem icon="delete" label="Delete deck" danger node="subdeck-list/lm-delete" />
            </MenuList>
          </Sheet>
        </Scrim>
      </React.Fragment>
    );
  }

  /* loaded / dense — Library body (controls + deck cards) + bottom nav, plus breadcrumb */
  const arr = state === 'dense' ? DENSE : SUBDECKS;
  return (
    <MxScaffold node="subdeck-list/screen" appBar={nestedBar} bottomNav={nav} fab={fab}>
      {crumbs()}
      {filter}
      {list(arr)}
    </MxScaffold>
  );
}

window.SubdeckList = SubdeckList;
})();

export const SubdeckList = window.SubdeckList;
