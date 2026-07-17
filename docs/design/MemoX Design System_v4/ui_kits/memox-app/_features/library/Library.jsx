/* MemoX — Library = the ONE deck-list screen, at every level. Domain: Library › Deck (→ nested
   Deck…) › Card — one Deck model (parentId), no separate Subdeck.
   Root mode (parentId null): top-level decks, bottom-nav tab. Nested mode (`nested-*` states,
   parent = a deck): a deck's child decks, pushed (back + breadcrumb + Deck Settings) — delegates
   to the SubdeckList render module. Opening a deck pushes THIS screen with a parent; a final
   deck's cards go to the Flashcard List.
   Orchestrates shared chrome (MxContextualAppBar,
   MxBottomNav, MxFab, Scrim/Sheet, EmptyState) + shared DeckCard + MxList (standard
   spacing) + library-local components (DeckRowCard, FilterRow, LibraryCreateSheet,
   fixtures) from _features/library/components/. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxBottomNav, MxCard, MxIconButton, MxFab, MxButton, MxLink, MxAvatar } = NS;
const { Scrim, Sheet, MenuItem, SectionLabel, EmptyState, Skeleton, Ring } = window;

const NAV = [
  { id: 'home', label: 'Today', icon: 'today' },
  { id: 'library', label: 'Library', icon: 'style' },
  { id: 'stats', label: 'Stats', icon: 'insights' },
  { id: 'me', label: 'Profile', icon: 'person' },
];
const AV = <MxAvatar name="Linh Tran" size="sm" />;
const study = (node, name) => <MxIconButton icon="bolt" size="sm" node={node} ariaLabel={'Study ' + name} />;

function Library({ state = 'loaded' }) {
  // ONE deck-list screen for every level. Nested mode (parent = a deck) lists a deck's child
  // decks one level down — same deck-list, pushed chrome (back + breadcrumb + Deck Settings).
  // Reuses the SubdeckList render module (retired as a standalone screen, kept as this screen's
  // nested renderer; its subdeck-list/* node ids stay frozen — app-mapping contract).
  // state 'nested-<x>' -> SubdeckList state '<x>'. Pass the SAME bottom nav so the nested
  // deck list is chrome-identical to the root (library body + bottom-nav) — it differs only
  // by the back button + breadcrumb the nested renderer adds.
  if (state.indexOf('nested-') === 0) {
    return window.SubdeckList({ state: state.slice(7), nav: <MxBottomNav items={NAV} value="library" node="shell/bottom-nav" /> });
  }
  const LIB = window.MemoXLibrary;
  const { DECKS, DENSE, SUBDECKS, deckMeta, Status, DeckRowCard, FilterRow } = LIB;
  const DeckCard = window.DeckCard, MxList = NS.MxList;

  const nav = <MxBottomNav items={NAV} value="library" node="shell/bottom-nav" />;
  const fab = <MxFab icon="add" node="library/create" ariaLabel="Create" />;
  const rootBar = (
    <MxContextualAppBar variant="root" node="library/appbar"
      title="Library"
      actions={<MxIconButton icon="search" size="sm" node="library/search-open" ariaLabel="Search" />}
      avatar={AV} />
  );
  const deckCard = (d, i, sel) => <DeckCard key={i} icon={d.icon} tone={d.tone} title={d.name} meta={deckMeta(d)} selected={sel} trailing={study('library/study-' + i, d.name)} node={'library/deck-' + i} />;

  /* LIB-12 loading */
  if (state === 'loading') {
    return (
      <MxScaffold node="library/screen" appBar={rootBar} bottomNav={nav}>
        <Skeleton h={40} r={999} />
        <MxList>{[0, 1, 2, 3, 4].map((i) => <MxCard key={i} padding="sm"><div style={{ display: 'flex', gap: 'var(--memox-space-4)', alignItems: 'center' }}><Skeleton w={48} h={48} r={16} /><div style={{ flex: 1 }}><Skeleton w="60%" h={14} /><Skeleton w="40%" h={10} style={{ marginTop: 'var(--memox-space-2)' }} /></div></div></MxCard>)}</MxList>
      </MxScaffold>
    );
  }

  /* LIB-04 empty library */
  if (state === 'empty') {
    return (
      <MxScaffold node="library/screen" appBar={rootBar} bottomNav={nav}>
        <EmptyState node="library/empty" icon="style" title="Build your learning library"
          text="Create a deck or import cards to get started."
          action={<div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', width: 'var(--memox-size-3xl)' }}>
            <MxButton variant="primary" icon="stacks" block node="library/empty-create">Create deck</MxButton>
            <MxButton variant="secondary" icon="upload_file" block node="library/empty-import">Import cards</MxButton>
          </div>} />
      </MxScaffold>
    );
  }

  /* LIB-13 offline / partial error — local data still usable */
  if (state === 'offline') {
    return (
      <MxScaffold node="library/screen" appBar={rootBar} bottomNav={nav} fab={fab}>
        <div data-mx-node="library/offline-banner" style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-card)', background: 'var(--memox-warning-soft)', color: 'var(--memox-on-warning-soft)' }}>
          <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-md)' }}>cloud_off</span>
          <div style={{ flex: 1, fontSize: 'var(--memox-font-size-sm)' }}>Offline · showing saved data. Last synced 2 hours ago.</div>
          <MxLink size="sm" trailingIcon={null} node="library/offline-retry">Retry</MxLink>
        </div>
        <FilterRow />
        <MxList>{DECKS.map((d, i) => deckCard(d, i))}</MxList>
      </MxScaffold>
    );
  }

  /* LIB-06/07/08 search */
  if (state === 'search-active' || state === 'search-results' || state === 'search-no-results') {
    const q = state === 'search-active' ? 'korea' : state === 'search-results' ? 'korean' : 'business Korean';
    const bar = (
      <MxContextualAppBar variant="search" node="library/appbar"
        search={{ value: q, placeholder: 'Search decks' }}
        actions={<MxIconButton icon="close" size="sm" node="library/search-clear" ariaLabel="Clear search" />} />
    );
    let body;
    if (state === 'search-active') {
      body = <React.Fragment><SectionLabel>RECENT</SectionLabel><MxList>{['korean topik', 'grammar', 'hanja'].map((r, i) => <MxCard key={i} padding="sm" interactive node={'library/recent-' + i}><div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)' }}><span className="material-symbols-rounded" style={{ color: 'var(--memox-text-secondary)' }}>history</span><span>{r}</span></div></MxCard>)}</MxList></React.Fragment>;
    } else if (state === 'search-no-results') {
      body = <EmptyState node="library/no-results" icon="search_off" tone="warning" title={'No results for “business Korean”'} text="Try another keyword or clear your filters." action={<MxButton variant="secondary" icon="close" node="library/clear-search">Clear search</MxButton>} />;
    } else {
      body = (
        <React.Fragment>
          <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>4 results for “korean”</div>
          <SectionLabel>DECKS</SectionLabel>
          <MxList>{deckCard(DECKS[0], 0)}</MxList>
          <SectionLabel>NESTED DECKS</SectionLabel>
          {/* nested-deck results show their PARENT deck instead of the status line */}
          <MxList>{[SUBDECKS[0], SUBDECKS[2]].map((s, i) => <DeckRowCard key={i} s={s} index={'sr-' + i} meta={<span>in Korean TOPIK I · {s.cards} cards</span>} />)}</MxList>
        </React.Fragment>
      );
    }
    return <MxScaffold node="library/screen" appBar={bar}>{body}</MxScaffold>;
  }

  /* LIB-11 selection (root: decks only) */
  if (state === 'selection') {
    const bar = (
      <MxContextualAppBar variant="selection" node="library/appbar" count={3}
        actions={<React.Fragment>
          <MxIconButton icon="select_all" size="sm" node="library/sel-all" ariaLabel="Select all" />
          <MxIconButton icon="more_vert" size="sm" node="library/sel-more" ariaLabel="More actions" />
        </React.Fragment>} />
    );
    const sel = [true, false, true, true, false, false];
    return <MxScaffold node="library/screen" appBar={bar} bottomNav={nav}><MxList>{DECKS.map((d, i) => deckCard(d, i, sel[i]))}</MxList></MxScaffold>;
  }

  /* LIB-03 create → Create Deck DIALOG directly (§10: the Library FAB is "New deck"; no Library
     create sheet). LibraryCreateSheet.jsx is kept as a component + node map for the app's current
     build, but is out of the canonical flow. */
  if (state === 'create-sheet') return window.CreateDeckDialog({ state: 'root-default' });

  /* post-create SUCCESS outcomes (§10). The just-created deck is EMPTY (0 cards, no due/new/
     progress) and lands highlighted at the TOP via the shared DeckCard + light `newBadge` "New"
     pill — never an existing populated deck. first-deck-created: it is the ONLY deck, with a
     celebratory callout whose "Open deck" is the single primary (the FAB is hidden so there are
     not two competing primaries). deck-created: the new deck sits above the existing library with
     a "Deck created · Open" snackbar (the FAB stays — the snackbar action is a text link). */
  if (state === 'deck-created') {
    const NEW = LIB.NEW_DECK_ROOT;
    const newCard = <DeckCard key="new" icon={NEW.icon} tone={NEW.tone} title={NEW.name} meta={deckMeta(NEW)} newBadge node="library/deck-new" />;
    return (
      <MxScaffold node="library/screen" appBar={rootBar} bottomNav={nav} fab={fab}>
        <FilterRow />
        <MxList>{[newCard, ...DECKS.map((d, i) => deckCard(d, i))]}</MxList>
        <window.Snackbar tone="success" text="Deck created" action={<MxLink size="sm" trailingIcon={null} className="snackbar-action" node="library/created-open">Open</MxLink>} node="library/created-snackbar" />
      </MxScaffold>
    );
  }

  /* first-deck success is STATEFUL so the dismiss (×) actually works (like FlashcardEditor's local
     toggles): `first-deck-created` mounts with the celebratory callout up + FAB hidden (single
     primary = "Open deck"); ActionCallout onDismiss flips local `dismissed` → the callout + "New"
     badge disappear and the FAB RETURNS. `first-deck-created-dismissed` is the same component mounted
     already-dismissed (the canonical "after" shot). The just-created deck stays either way (0 cards). */
  if (state === 'first-deck-created' || state === 'first-deck-created-dismissed') {
    return <FirstDeckSuccess NEW={LIB.NEW_DECK} rootBar={rootBar} nav={nav} fab={fab} filter={<FilterRow />} deckMeta={deckMeta} initialDismissed={state === 'first-deck-created-dismissed'} />;
  }

  /* LIB-09 filter applied */
  if (state === 'filter-applied') {
    const matched = DECKS.filter((d) => d.due > 0);
    return (
      <MxScaffold node="library/screen" appBar={rootBar} bottomNav={nav} fab={fab}>
        <FilterRow active />
        <div data-mx-node="library/filter-summary" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>{matched.length} decks match · Due only</span>
          <MxLink size="sm" trailingIcon={null} node="library/clear-filters">Clear all</MxLink>
        </div>
        <MxList>{matched.map((d, i) => deckCard(d, i))}</MxList>
      </MxScaffold>
    );
  }

  /* LIB-10 filter/sort sheet */
  if (state === 'filter-sheet') {
    const item = (icon, label, s, n) => <MenuItem icon={icon} label={label} selected={s} node={'library/fs-' + n} />;
    return (
      <React.Fragment>
        <MxScaffold node="library/screen" appBar={rootBar} bottomNav={nav} fab={fab}><FilterRow /><MxList>{DECKS.slice(0, 3).map((d, i) => deckCard(d, i))}</MxList></MxScaffold>
        <Scrim align="end" node="library/fs-scrim">
          <Sheet title="Sort & filter" node="library/filter-sheet">
            <SectionLabel style={{ margin: '0 0 var(--memox-space-1) var(--memox-space-2)' }}>SORT</SectionLabel>
            {item('history', 'Recently studied', true, 'sort-recent')}
            {item('sort_by_alpha', 'Name A–Z', false, 'sort-name')}
            {item('priority_high', 'Most due', false, 'sort-due')}
            <div style={{ height: 'var(--memox-stroke-hairline)', background: 'var(--memox-divider)', margin: 'var(--memox-space-2)' }} />
            <SectionLabel style={{ margin: '0 0 var(--memox-space-1) var(--memox-space-2)' }}>FILTER</SectionLabel>
            {item('schedule', 'Due cards', true, 'f-due')}
            {item('fiber_new', 'New cards', false, 'f-new')}
            {item('account_tree', 'Has nested decks', false, 'f-sub')}
            <div style={{ display: 'flex', gap: 'var(--memox-space-3)', marginTop: 'var(--memox-space-4)' }}>
              <MxButton variant="ghost" block node="library/fs-reset">Reset</MxButton>
              <MxButton variant="primary" block node="library/fs-apply">Apply</MxButton>
            </div>
          </Sheet>
        </Scrim>
      </React.Fragment>
    );
  }

  /* LIB-01 loaded / LIB-02 dense */
  const decks = state === 'dense' ? DENSE : DECKS;
  return (
    <MxScaffold node="library/screen" appBar={rootBar} bottomNav={nav} fab={fab}>
      <FilterRow />
      <MxList>{decks.map((d, i) => deckCard(d, i))}</MxList>
    </MxScaffold>
  );
}

// first-deck success as a small STATEFUL component so the callout's × performs a real transition
// (local `dismissed`): callout up + FAB hidden → dismiss → callout/badge gone + FAB restored. The
// just-created empty deck (0 cards) stays in the Library throughout.
function FirstDeckSuccess({ NEW, rootBar, nav, fab, filter, deckMeta, initialDismissed }) {
  const { MxScaffold, MxButton, MxList } = NS;
  const DeckCard = window.DeckCard;
  const [dismissed, setDismissed] = React.useState(!!initialDismissed);
  return (
    <MxScaffold node="library/screen" appBar={rootBar} bottomNav={nav} fab={dismissed ? fab : undefined}>
      {filter}
      <MxList>{[<DeckCard key="new" icon={NEW.icon} tone={NEW.tone} title={NEW.name} meta={deckMeta(NEW)} newBadge={!dismissed} node="library/deck-new" />]}</MxList>
      {dismissed ? null : (
        <window.ActionCallout node="library/first-deck-callout" tone="accent" icon="celebration"
          title="Your first deck is ready"
          text="Add cards or organise it into smaller decks whenever you’re ready."
          action={<MxButton variant="primary" size="sm" node="library/first-deck-open">Open deck</MxButton>}
          dismissNode="library/first-deck-dismiss" onDismiss={() => setDismissed(true)} />
      )}
    </MxScaffold>
  );
}

window.Library = Library;
})();

export const Library = window.Library;
