/* MemoX — Dashboard (Today). States: loaded · not-studied · goal-met · streak-reset · caught-up · empty · loading
   Action architecture: bottom nav = destinations only (Today/Library/Stats/Profile);
   "Add" is the FAB; the primary CTA "Start review" is attached to the Continue-studying
   section (not a floating button). `caught-up` = no cards due → the review CTA is
   replaced by an all-caught-up message. `empty` = first-run (no decks). Surfaces are
   kept to ~2 levels: Today is a flat inline strip (not a card); only Daily goal and the
   deck rows are cards. Recent decks use the shared _shared/DeckCard + MxList (standard
   spacing). Feature-local components: components/{GreetingHeader,GoalCard,OnboardingHero,
   OnboardingStep}.jsx (TodaySummary/StreakCard/ContinueCard retired). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxBottomNav, MxCard, MxSectionHeader, MxButton, MxIconButton, MxAvatar, MxLink, MxBadge, MxList } = NS;

// Bottom nav holds DESTINATIONS only — "Add" is an action, so it lives in the FAB,
// not as a fake tab (correct nav semantics; keeps 4 comfortable tap targets).
const NAV = [
  { id: 'home', label: 'Today', icon: 'today' },
  { id: 'library', label: 'Library', icon: 'style' },
  { id: 'stats', label: 'Stats', icon: 'insights' },
  { id: 'me', label: 'Profile', icon: 'person' },
];

const DECKS = [
  { icon: 'translate', tone: 'accent', name: 'TOPIK I — Vocabulary', meta: '320 cards · 48 due', due: 48, progress: 72 },
  { icon: 'menu_book', tone: 'warning', name: 'Basic Grammar', meta: '180 cards · 23 due', due: 23, progress: 54 },
  { icon: 'record_voice_over', tone: 'success', name: 'Daily Conversation', meta: '150 cards · 6 due', due: 6, progress: 88 },
];

// Separate fixture for the caught-up state — 0 due everywhere, so the deck rows can
// never contradict the "no cards due" hero (each row shows an up-to-date ✓, not a count).
const CAUGHT_DECKS = [
  { icon: 'translate', tone: 'accent', name: 'TOPIK I — Vocabulary', meta: '320 cards · up to date', due: 0, progress: 100 },
  { icon: 'menu_book', tone: 'warning', name: 'Basic Grammar', meta: '180 cards · up to date', due: 0, progress: 100 },
  { icon: 'record_voice_over', tone: 'success', name: 'Daily Conversation', meta: '150 cards · up to date', due: 0, progress: 100 },
];

const Note = window.Note;

function Dashboard({ state = 'loaded' }) {
  const { GoalCard, GreetingHeader } = window.MemoXDashboard;
  const nav = <MxBottomNav items={NAV} value="home" node="shell/bottom-nav" />;
  // Shared contextual app bar (root-contextual): shows the date as the context label at
  // the top and collapses to the "Today" destination title on scroll. The date lives ONLY
  // here — the greeting below drops its eyebrow so nothing is duplicated (contract §6).
  const bar = (
    <MxContextualAppBar variant="root" node="dashboard/appbar"
      title="Today"
      actions={<MxIconButton icon="search" size="sm" node="dashboard/search-open" ariaLabel="Search words" />}
      notification={{ dot: true }}
      avatar={<MxAvatar name="Linh Tran" size="sm" />} />
  );
  const greeting = <GreetingHeader title="Good evening, Linh" node="dashboard/greeting" />;

  if (state === 'loading') {
    const S = window.Skeleton;
    return (
      <MxScaffold node="dashboard/screen" appBar={bar} bottomNav={nav}>
        {greeting}
        <S w="55%" h={16} />
        <S h={48} r={14} />
        <MxCard><S w="35%" h={14} /><S h={10} r={999} style={{ marginTop: 'var(--memox-space-3)' }} /><S w="60%" h={10} style={{ marginTop: 'var(--memox-space-2)' }} /></MxCard>
        <S w="30%" h={16} />
        {[0, 1].map((i) => <MxCard key={i} padding="sm"><div style={{ display: 'flex', gap: 'var(--memox-space-4)', alignItems: 'center' }}><S w={48} h={48} r={16} /><div style={{ flex: 1 }}><S w="60%" h={14} /><S w="40%" h={10} style={{ marginTop: 'var(--memox-space-2)' }} /></div></div></MxCard>)}
      </MxScaffold>
    );
  }

  /* Neutral post-skip Today (§4 "Not now"): the user declined onboarding, so it must NOT run
     again. A normal Today shell — greeting + bottom nav + Add FAB — with a quiet "nothing due"
     note (no onboarding hero, no "How MemoX works", no step cards). The user creates a deck from
     the FAB or the Library tab whenever they’re ready. */
  if (state === 'empty-after-onboarding-skip') {
    return (
      <MxScaffold node="dashboard/screen" appBar={bar} bottomNav={nav} fab={<MxFabAdd />}>
        {greeting}
        <div data-mx-node="dashboard/nothing-due" style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 'var(--memox-space-3)', padding: 'var(--memox-space-8) var(--memox-space-4)' }}>
          <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-icon-size-xl)', color: 'var(--memox-text-tertiary)' }}>inbox</span>
          <div style={{ fontSize: 'var(--memox-font-size-md)', fontWeight: 'var(--memox-font-weight-bold)' }}>Nothing due yet</div>
          <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)', maxWidth: 'var(--memox-size-3xl)' }}>Add a deck to start studying — new cards you add will show up here.</div>
        </div>
      </MxScaffold>
    );
  }

  if (state === 'empty') {
    const { OnboardingHero, OnboardingStep } = window.MemoXDashboard;
    return (
      <MxScaffold node="dashboard/screen" appBar={bar} bottomNav={nav}>
        {greeting}
        <OnboardingHero icon="school" title="Start your first deck"
          text="Add the words you want to remember — MemoX schedules the reviews for you.">
          <MxButton variant="contrast" icon="add" block node="dashboard/create-deck">Create a deck</MxButton>
          <MxButton variant="secondary" icon="upload_file" block node="dashboard/import-file">Import from a file</MxButton>
        </OnboardingHero>
        <MxSectionHeader title="How MemoX works" node="dashboard/how-it-works" />
        <OnboardingStep icon="library_add" title="Add your words"
          text="Create decks or import from CSV" node="dashboard/step-add" />
        <OnboardingStep icon="bolt" tone="accent" title="Study with smart review"
          text="Spaced repetition picks what's due" node="dashboard/step-review" />
        <OnboardingStep icon="local_fire_department" tone="warning" title="Build a daily streak"
          text="Hit your daily goal to keep the flame" node="dashboard/step-streak" />
      </MxScaffold>
    );
  }

  const met = state === 'goal-met';
  const reset = state === 'streak-reset';
  const idle = state === 'not-studied';
  const caught = state === 'caught-up';
  const goalPct = met ? 100 : idle ? 0 : 70;
  const streak = met ? 13 : reset ? 0 : 12;
  const dueCards = 24;
  const dueDecks = DECKS.length;

  // A flat stat with a small tinted icon chip — adds colour/scannability to the Today
  // strip without turning each metric back into a full card (chips, not surfaces).
  // Fixed anatomy for all four metrics (VIS-022 consistency): 48px container, 24px icon,
  // 16px icon->content, 4px value->label. Only `icon`, `soft`, `on` differ per metric.
  const Stat = ({ icon, soft, on, n, l }) => (
    <div style={{ display: 'flex', gap: 'var(--memox-space-4)', alignItems: 'center', minWidth: 0 }}>
      <span style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, width: 'var(--memox-comp-icon-tile-md)', height: 'var(--memox-comp-icon-tile-md)', borderRadius: 'var(--memox-radius-control)', background: soft }}>
        <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-font-size-xl)', color: on }}>{icon}</span>
      </span>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)', minWidth: 0 }}>
        <div style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)' }}>{n}</div>
        <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>{l}</div>
      </div>
    </div>
  );

  const screen = (
    <MxScaffold node="dashboard/screen" appBar={bar} bottomNav={nav}
      fab={<MxFabAdd />}>
      {greeting}
      {met ? <Note icon="celebration" tone="success" text="Daily goal reached! Streak +1." /> : null}
      {reset ? <Note icon="local_fire_department" tone="warning" text="Streak reset — study today to start again." /> : null}
      {idle ? <Note icon="bolt" tone="accent" text="You haven't studied today — study to keep your streak." /> : null}

      {/* PRIMARY: continue studying — the CTA is attached to the section, not floating.
          When nothing is due, the Review CTA is replaced by an all-caught-up message. */}
      {caught ? (
        <div data-mx-node="dashboard/continue" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-1)' }}>
            <div style={{ fontSize: 'var(--memox-font-size-md)', fontWeight: 'var(--memox-font-weight-bold)' }}>You're all caught up</div>
            <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>No cards due right now.</div>
          </div>
          <MxButton variant="secondary" icon="explore" block node="dashboard/explore">Explore decks</MxButton>
        </div>
      ) : (
        <div data-mx-node="dashboard/continue" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
          <MxSectionHeader title="Continue studying" caption={`${dueCards} cards due across ${dueDecks} decks`} node="dashboard/continue-head" />
          <MxButton variant="primary" icon="bolt" block node="dashboard/start-review">Start review</MxButton>
        </div>
      )}

      <GoalCard pct={goalPct} met={met} minutes={idle ? 0 : 14} />

      {/* Today strip — flat inline stats, no card. Merges time/words/streak/mastery
          into one low-surface summary instead of four separate cards. */}
      <div data-mx-node="dashboard/today" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
        <div style={{ fontSize: 'var(--memox-font-size-md)', fontWeight: 'var(--memox-font-weight-bold)' }}>Today</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) minmax(0, 1fr)', gap: 'var(--memox-space-6) var(--memox-space-6)' }}>
          <Stat icon="schedule" soft="var(--memox-primary-soft)" on="var(--memox-on-primary-soft)" n={idle ? '0m' : '12m'} l="studied" />
          <Stat icon="menu_book" soft="var(--memox-accent-soft)" on="var(--memox-accent)" n={idle ? '0' : '24'} l="words learned" />
          <Stat icon="local_fire_department" soft="var(--memox-warning-soft)" on="var(--memox-on-warning-soft)" n={streak} l="day streak" />
          <Stat icon="verified" soft="var(--memox-success-soft)" on="var(--memox-on-success-soft)" n="55%" l="library mastered" />
        </div>
      </div>

      {/* Deck rows are LIST ITEMS — group them with an item gap (12), not the body's
          section gap (24), so the list is tighter and the first deck surfaces sooner. */}
      <div data-mx-node="dashboard/decks" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
        {/* No right-aligned "See all" action here: the FAB floats over the bottom-right
            and must never sit on top of another interactive control. Full library is one
            tap away on the Library tab; a "See all decks" row can live at the list end. */}
        <MxSectionHeader title="Recent decks" node="dashboard/decks-head" />
        {/* Shared DeckCard + MxList (standard 12px gap) so Library and Dashboard never
            drift. Dashboard shows progress + a due badge; other screens vary the trailing. */}
        <MxList>
          {(caught ? CAUGHT_DECKS : DECKS).map((d, i) => (
            <window.DeckCard key={i} icon={d.icon} tone={d.tone} title={d.name} meta={d.meta} progress={d.progress}
              trailing={<MxBadge tone={d.due > 0 ? undefined : 'success'} soft>{d.due > 0 ? d.due : <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-font-size-xs)' }}>check</span>}</MxBadge>}
              node={'dashboard/deck-' + i} />
          ))}
        </MxList>
        <div style={{ display: 'flex', justifyContent: 'center' }}>
          <MxLink node="dashboard/see-all-decks">See all decks</MxLink>
        </div>
      </div>
    </MxScaffold>
  );

  if (state === 'create-sheet') return <React.Fragment>{screen}<CreateSheet /></React.Fragment>;
  return screen;
}

// Round FAB (covers less of the list than an extended one). Its meaning is made explicit
// by the create sheet it opens — see the `create-sheet` state (Add card / Create deck /
// Import cards) — rather than by a label.
function MxFabAdd() {
  const { MxFab } = NS;
  return <MxFab icon="add" node="dashboard/add" />;
}

function CreateSheet() {
  const { Scrim, Sheet, MenuItem } = window;
  return (
    <Scrim align="end" node="dashboard/create-scrim">
      <Sheet title="Create" node="dashboard/create-sheet">
        <MenuItem icon="note_add" label="Add card" node="dashboard/create-card" />
        <MenuItem icon="stacks" label="Create deck" node="dashboard/create-deck" />
        <div style={{ height: 'var(--memox-stroke-hairline)', background: 'var(--memox-divider)', margin: 'var(--memox-space-2) var(--memox-space-2)' }} />
        <MenuItem icon="upload_file" label="Import cards" node="dashboard/create-import" />
      </Sheet>
    </Scrim>
  );
}

window.Dashboard = Dashboard;
})();
