/* MemoX — Flashcard List. Primary objective: browse, study and manage the flashcards in
   the deepest (final) deck. CARDS ONLY — never a SUBDECKS section, never Create subdeck.
   Nested screen: back + deck title + search + More(→ Deck Settings). Card filters
   (All/New/Due/Mastered). Add-card FAB → opens Flashcard Editor for create/edit.
   Reuses shared StatusCardRow for every card row. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxCard, MxIconButton, MxFab, MxButton, MxLink, MxSearchDock, MxChip } = NS;
const { Scrim, Sheet, MenuItem, SectionLabel, EmptyState, Skeleton, ConfirmDialog, FormDialog } = window;

function FlashcardList({ state = 'loaded' }) {
  const FL = window.MemoXFlashcardList;
  const { CARDS, MIN, DENSE, LONG, FILTERS, TRAIL, summary, AddCardSheet } = FL;
  const Breadcrumb = window.Breadcrumb;
  const MxList = NS.MxList; // the shared 12px-gap card list — same spacing as decks

  const fab = <MxFab icon="add" node="flashcard-list/add" ariaLabel="Add card" />;
  const nestedBar = (
    <MxContextualAppBar variant="nested" node="flashcard-list/appbar" title="Numbers & counting"
      actions={<React.Fragment>
        <MxIconButton icon="search" size="sm" node="flashcard-list/search-open" ariaLabel="Search cards" />
        <MxIconButton icon="more_vert" size="sm" node="flashcard-list/more" ariaLabel="Deck settings" />
      </React.Fragment>} />
  );
  // CARDS section label with the study aggregate as a compact muted annotation.
  const cardHead = (arr) => <SectionLabel>CARDS <span style={{ fontWeight: 'var(--memox-font-weight-medium)', letterSpacing: 'normal', color: 'var(--memox-text-tertiary)' }}>· {summary(arr)}</span></SectionLabel>;
  const filterRow = (sel) => (
    <div data-mx-node="flashcard-list/filters" style={{ display: 'flex', gap: 'var(--memox-space-2)', overflowX: 'auto', paddingBottom: 'var(--memox-space-1)' }}>
      {FILTERS.map((f, i) => <MxChip key={f} label={f} selected={i === sel} node={'flashcard-list/filter-' + i} />)}
    </div>
  );
  const crumbs = <Breadcrumb items={TRAIL} node="flashcard-list/breadcrumb" />;
  const cardRow = (c, i) => <MxCard key={i} padding="sm" interactive node={'flashcard-list/card-' + i}><window.StatusCardRow {...c} tightTerm clampMeaning /></MxCard>;
  const cardList = (arr) => <MxList>{arr.map((c, i) => cardRow(c, i))}</MxList>;

  /* loading */
  if (state === 'loading') {
    return (
      <MxScaffold node="flashcard-list/screen" appBar={nestedBar} fab={fab}>
        <Skeleton h={44} r={999} />
        {[0, 1, 2, 3, 4].map((i) => <MxCard key={i} padding="sm"><div style={{ display: 'flex', gap: 'var(--memox-space-4)', alignItems: 'center' }}><div style={{ flex: 1 }}><Skeleton w="45%" h={16} /><Skeleton w="65%" h={10} style={{ marginTop: 'var(--memox-space-2)' }} /></div><Skeleton w={56} h={22} r={999} /></div></MxCard>)}
      </MxScaffold>
    );
  }

  /* A leaf that lost its last card is an EMPTY deck again (§15) → the unified Empty Deck screen
     (Add card / Create nested deck / Import) — the first content added decides leaf vs parent. */
  if (state === 'empty') return window.EmptyDeck({ state: 'default' });

  /* offline / error */
  if (state === 'offline') {
    return (
      <MxScaffold node="flashcard-list/screen" appBar={nestedBar} fab={fab}>
        {crumbs}
        <div data-mx-node="flashcard-list/offline-banner" style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-3)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-card)', background: 'var(--memox-warning-soft)', color: 'var(--memox-on-warning-soft)' }}>
          <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-md)' }}>cloud_off</span>
          <div style={{ flex: 1, fontSize: 'var(--memox-font-size-sm)' }}>Offline · showing saved cards. Last synced 2 hours ago.</div>
          <MxLink size="sm" trailingIcon={null} node="flashcard-list/offline-retry">Retry</MxLink>
        </div>
        {filterRow(0)}{cardHead(CARDS)}{cardList(CARDS)}
      </MxScaffold>
    );
  }
  if (state === 'error') {
    return (
      <MxScaffold node="flashcard-list/screen" appBar={nestedBar}>
        <EmptyState node="flashcard-list/error" icon="cloud_off" tone="error" title="Couldn't load cards"
          text="Something went wrong. Check your connection and try again."
          action={<MxButton variant="primary" icon="refresh" node="flashcard-list/retry">Retry</MxButton>} />
      </MxScaffold>
    );
  }

  /* not-found — the parent deck was deleted/moved on another device while open
     (KIT-23-02, deleted-entity detail state). Friendly copy + a safe back action;
     the nested app bar drops search/more since the entity is gone. */
  // registry-state: not-found
  if (state === 'not-found') {
    const goneBar = (
      <MxContextualAppBar variant="nested" node="flashcard-list/appbar" title="Numbers & counting"
        actions={<span aria-hidden="true" />} />
    );
    return (
      <MxScaffold node="flashcard-list/screen" appBar={goneBar}>
        <EmptyState node="flashcard-list/not-found" icon="folder_off" tone="warning"
          title="This deck no longer exists"
          text="It may have been deleted or moved on another device. Head back to your library to keep studying."
          action={<MxButton variant="primary" icon="arrow_back" node="flashcard-list/not-found-back">Back to Library</MxButton>} />
      </MxScaffold>
    );
  }

  /* search / no-results — CARDS only, placeholder "Search cards" */
  if (state === 'search' || state === 'no-results') {
    const q = state === 'search' ? '하' : 'zzz';
    const bar = (
      <MxContextualAppBar variant="search" node="flashcard-list/appbar"
        search={{ value: q, placeholder: 'Search cards' }}
        actions={<MxIconButton icon="close" size="sm" node="flashcard-list/search-clear" ariaLabel="Clear search" />} />
    );
    if (state === 'no-results') {
      return <MxScaffold node="flashcard-list/screen" appBar={bar}>{filterRow(0)}<EmptyState node="flashcard-list/no-results" icon="search_off" tone="warning" title="No cards found" text={'Nothing matched “zzz”. Try another term.'} /></MxScaffold>;
    }
    const hits = CARDS.filter((c) => c.term.includes('하') || c.meaning.includes('study'));
    return <MxScaffold node="flashcard-list/screen" appBar={bar}>{filterRow(0)}<SectionLabel>CARDS</SectionLabel>{cardList(hits)}</MxScaffold>;
  }

  /* filter-applied — Due filter active */
  if (state === 'filter-applied') {
    const due = CARDS.filter((c) => c.status === 'due');
    return (
      <MxScaffold node="flashcard-list/screen" appBar={nestedBar} fab={fab}>
        {crumbs}
        {filterRow(2)}
        <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>{due.length} due cards</div>
        <SectionLabel>CARDS</SectionLabel>{cardList(due)}
      </MxScaffold>
    );
  }

  /* SELECTION MODE — contract notes (static kit annotates intent; Flutter wires handlers):
     · Entry trigger (KIT-27-01): long-press any card row, OR "Select" in the card-actions
       sheet, enters selection mode; the app bar swaps to the `selection` variant. Hardware
       BACK exits selection mode first (restores the nested app bar) and only navigates away on
       a second BACK — it never leaves the deck straight from selection.
     · Persistence (KIT-27-05): the selection is keyed by card id, not row index. Changing the
       filter/search/sort re-scopes the visible rows but KEEPS ids already selected; select-all
       and the count reflect only the CURRENT (post-filter) set. Hidden cards are out of scope
       and are never swept in by select-all. */

  // Tri-state select-all affordance (KIT-27-02): reflects scope over the current set —
  // 'none' → empty box (tap = select all), 'some' → indeterminate, 'all' → filled (tap = clear).
  const selAllAction = (scope) => {
    const map = { none: ['check_box_outline_blank', 'Select all'], some: ['indeterminate_check_box', 'Select all'], all: ['check_box', 'Deselect all'] };
    const [icon, label] = map[scope] || map.none;
    return <MxIconButton icon={icon} size="sm" node="flashcard-list/sel-all" ariaLabel={label} />;
  };
  // Selection app bar: count + tri-state select-all + bulk more_vert. more_vert is DISABLED at
  // zero selected (KIT-27-03) — no bulk action can target an empty selection.
  const selBar = (count, scope) => (
    <MxContextualAppBar variant="selection" node="flashcard-list/appbar" count={count}
      actions={<React.Fragment>
        {selAllAction(scope)}
        <MxIconButton icon="more_vert" size="sm" node="flashcard-list/sel-more" ariaLabel="More actions" disabled={count === 0} />
      </React.Fragment>} />
  );
  const selList = (sel) => (
    <MxList>{CARDS.map((c, i) => (
      <MxCard key={i} padding="sm" interactive variant={sel[i] ? 'primary-soft' : undefined} node={'flashcard-list/sel-card-' + i}>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 'var(--memox-space-4)' }}>
          <span className="material-symbols-rounded" style={{ flexShrink: 0, fontSize: 'var(--memox-icon-size-lg)', color: sel[i] ? 'var(--memox-accent)' : 'var(--memox-text-tertiary)' }}>{sel[i] ? 'check_circle' : 'radio_button_unchecked'}</span>
          <div style={{ flex: 1, minWidth: 0 }}><window.StatusCardRow {...c} tightTerm clampMeaning /></div>
        </div>
      </MxCard>
    ))}</MxList>
  );

  /* selection-all — every visible card selected; select-all shows the filled (tri-state 'all') box */
  if (state === 'selection-all') {
    return (
      <MxScaffold node="flashcard-list/screen" appBar={selBar(6, 'all')}>
        <SectionLabel>CARDS</SectionLabel>{selList([true, true, true, true, true, true])}
      </MxScaffold>
    );
  }

  /* selection-empty — zero selected (KIT-27-03): count 0, bulk more_vert disabled, hint shown */
  if (state === 'selection-empty') {
    return (
      <MxScaffold node="flashcard-list/screen" appBar={selBar(0, 'none')}>
        {/* Nothing selected → bulk actions disabled; production may also auto-exit selection mode. */}
        <window.Note icon="info" text="Select cards to move, hide, or delete." tone="accent" />
        <SectionLabel>CARDS</SectionLabel>{selList([false, false, false, false, false, false])}
      </MxScaffold>
    );
  }

  /* bulk-delete-confirm — destructive bulk action confirm that NAMES the count (KIT-27-04) */
  if (state === 'bulk-delete-confirm') {
    const sel = [true, false, true, false, false, false]; // 2 selected
    const screen = (
      <MxScaffold node="flashcard-list/screen" appBar={selBar(2, 'some')}>
        <SectionLabel>CARDS</SectionLabel>{selList(sel)}
      </MxScaffold>
    );
    return (
      <React.Fragment>{screen}
        <ConfirmDialog align="center" scrimNode="flashcard-list/bulk-delete-scrim"
          icon="delete" tone="error" title="Delete 2 cards?"
          text="The 2 selected cards will be permanently removed from this deck. This can’t be undone."
          dialogNode="flashcard-list/bulk-delete-dialog"
          actions={<React.Fragment>
            <MxButton variant="ghost" block node="flashcard-list/bulk-delete-cancel">Cancel</MxButton>
            <MxButton variant="primary" danger block node="flashcard-list/bulk-delete-ok">Delete 2</MxButton>
          </React.Fragment>} />
      </React.Fragment>
    );
  }

  /* bulk-outcome — bulk op result (KIT-27-06): partial success announced via a live region; the
     failed item stays selected so the user can retry just that one */
  if (state === 'bulk-outcome') {
    const sel = [true, false, true, true, false, true]; // 4 attempted, 1 failed still selected
    return (
      <MxScaffold node="flashcard-list/screen" appBar={selBar(4, 'some')}>
        <div role="status" aria-live="polite" data-mx-node="flashcard-list/bulk-outcome">
          <window.Note icon="info" text="Moved 3 of 4 cards. 1 couldn’t be moved — still selected to retry." tone="warning" />
        </div>
        <SectionLabel>CARDS</SectionLabel>{selList(sel)}
      </MxScaffold>
    );
  }

  /* selection — cards only */
  if (state === 'selection') {
    const bar = (
      <MxContextualAppBar variant="selection" node="flashcard-list/appbar" count={2}
        actions={<React.Fragment>
          <MxIconButton icon="select_all" size="sm" node="flashcard-list/sel-all" ariaLabel="Select all" />
          <MxIconButton icon="more_vert" size="sm" node="flashcard-list/sel-more" ariaLabel="More actions" />
        </React.Fragment>} />
    );
    const sel = [true, false, true, false, false, false];
    return (
      <MxScaffold node="flashcard-list/screen" appBar={bar}>
        <SectionLabel>CARDS</SectionLabel>
        <MxList>{CARDS.map((c, i) => (
          <MxCard key={i} padding="sm" interactive variant={sel[i] ? 'primary-soft' : undefined} node={'flashcard-list/sel-card-' + i}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 'var(--memox-space-4)' }}>
              <span className="material-symbols-rounded" style={{ flexShrink: 0, fontSize: 'var(--memox-icon-size-lg)', color: sel[i] ? 'var(--memox-accent)' : 'var(--memox-text-tertiary)' }}>{sel[i] ? 'check_circle' : 'radio_button_unchecked'}</span>
              <div style={{ flex: 1, minWidth: 0 }}><window.StatusCardRow {...c} tightTerm clampMeaning /></div>
            </div>
          </MxCard>
        ))}</MxList>
      </MxScaffold>
    );
  }

  const cards = state === 'minimum-data' ? MIN : state === 'dense' ? DENSE : state === 'long-text' ? LONG : CARDS;
  const base = (
    <MxScaffold node="flashcard-list/screen" appBar={nestedBar} fab={fab}>
      {crumbs}
      {filterRow(0)}
      {cardHead(cards)}
      {cardList(cards)}
    </MxScaffold>
  );

  /* add-sheet — card-only create */
  if (state === 'add-sheet') return <React.Fragment>{base}<AddCardSheet /></React.Fragment>;

  /* card-actions — a single card's action sheet; Edit opens the Flashcard Editor */
  if (state === 'card-actions') {
    return (
      <React.Fragment>{base}
        <Scrim align="end" node="flashcard-list/actions-scrim">
          <Sheet title="안녕하세요" node="flashcard-list/actions-sheet">
            <MenuItem icon="edit" label="Edit card" node="flashcard-list/action-edit" />
            <MenuItem icon="drive_file_move" label="Move card" node="flashcard-list/action-move" />
            <MenuItem icon="visibility_off" label="Hide card" node="flashcard-list/action-hide" />
            <MenuItem icon="delete" label="Delete card" danger node="flashcard-list/action-delete" />
          </Sheet>
        </Scrim>
      </React.Fragment>
    );
  }

  /* delete-confirm — delete a single card */
  if (state === 'delete-confirm') {
    return (
      <React.Fragment>{base}
        <ConfirmDialog align="center" scrimNode="flashcard-list/delete-scrim"
          icon="delete" tone="error" title="Delete this card?"
          text="The card “안녕하세요” will be removed from this deck. This can't be undone."
          dialogNode="flashcard-list/delete-dialog"
          actions={<React.Fragment>
            <MxButton variant="ghost" block node="flashcard-list/delete-cancel">Cancel</MxButton>
            <MxButton variant="primary" danger block node="flashcard-list/delete-ok">Delete</MxButton>
          </React.Fragment>} />
      </React.Fragment>
    );
  }

  /* convert-* — Leaf → Parent conversion (§14). A leaf that already holds cards can't get a child
     directly; the overflow "Organise into nested decks" opens a dialog that moves the existing
     cards into a first nested deck. On success the deck becomes a Parent (card list gone). The
     dialog carries a name field, so it's a Scrim+Sheet (not the icon/text ConfirmDialog). */
  if (state === 'convert-dialog' || state === 'convert-submitting' || state === 'convert-failure') {
    const submitting = state === 'convert-submitting';
    const failure = state === 'convert-failure';
    // ONE primary CTA: on failure the callout only reports the error and the bottom CTA becomes
    // "Try again"; while submitting the name field is locked.
    const actions = (
      <React.Fragment>
        <MxButton variant="ghost" disabled={submitting} node="flashcard-list/convert-cancel">Cancel</MxButton>
        <MxButton variant="primary" disabled={submitting} node={failure ? 'flashcard-list/convert-retry' : 'flashcard-list/convert-ok'}>{submitting ? 'Organising…' : failure ? 'Try again' : 'Create and organise'}</MxButton>
      </React.Fragment>
    );
    return (
      <React.Fragment>{base}
        <FormDialog title="Organise into nested decks?" node="flashcard-list/convert-dialog"
          scrimNode="flashcard-list/convert-scrim" actions={actions}>
          {failure ? (
            <window.ActionCallout node="flashcard-list/convert-error" tone="error" icon="error"
              text="Couldn’t organise the deck. Your nested deck name is still here." />
          ) : null}
          <p style={{ margin: 0, fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)', lineHeight: 'var(--memox-line-height-normal)' }}>This deck currently contains 42 cards. Create a nested deck to keep those cards together.</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)', ...(submitting ? { opacity: 'var(--memox-opacity-disabled, 0.5)', pointerEvents: 'none' } : {}) }}>
            <div style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-semibold)', color: 'var(--memox-text-secondary)' }}>Nested deck name *</div>
            <div data-mx-node="flashcard-list/convert-name" style={{ display: 'flex', alignItems: 'center', boxSizing: 'border-box', minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-2) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: 'var(--memox-surface-sunken)', border: 'var(--memox-stroke-hairline) solid var(--memox-divider)' }}>
              <span style={{ flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Vocabulary</span>
            </div>
          </div>
        </FormDialog>
      </React.Fragment>
    );
  }

  return base;
}

window.FlashcardList = FlashcardList;
})();

export const FlashcardList = window.FlashcardList;
