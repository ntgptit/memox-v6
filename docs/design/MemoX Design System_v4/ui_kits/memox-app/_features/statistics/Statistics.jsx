/* MemoX — Statistics (Stats). States: loading · loaded · insufficient · scope-switch
   Feature-local components: components/{Bars,Heatmap,Donut}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxBottomNav, MxCard, MxSectionHeader, MxSegmentedControl, MxButton } = NS;
const { Bars, Heatmap, Donut } = window.MemoXStatistics;

const NAV = [
  { id: 'home', label: 'Today', icon: 'today' },
  { id: 'library', label: 'Library', icon: 'style' },
  { id: 'add', label: 'Add', icon: 'add_circle' },
  { id: 'stats', label: 'Stats', icon: 'insights' },
  { id: 'me', label: 'Profile', icon: 'person' },
];

function Statistics({ state = 'loaded' }) {
  const bar = <MxContextualAppBar variant="root" title="Stats" node="statistics/appbar" />;
  const nav = <MxBottomNav items={NAV} value="stats" node="shell/bottom-nav" />;
  const scope = (
    <MxSegmentedControl value={state === 'scope-switch' ? 'all' : 'pair'} onChange={() => {}} block node="statistics/scope"
      segments={[{ value: 'pair', label: 'This pair' }, { value: 'all', label: 'All' }]} />
  );

  if (state === 'loading') {
    const S = window.Skeleton;
    return (
      <MxScaffold node="statistics/screen" appBar={bar} bottomNav={nav}>
        <S h={40} r={999} />
        {[0, 1, 2].map((i) => <MxCard key={i}><S w="45%" h={14} /><S h={110} r={12} style={{ marginTop: 'var(--memox-space-3)' }} /></MxCard>)}
      </MxScaffold>
    );
  }

  if (state === 'insufficient') {
    return (
      <MxScaffold node="statistics/screen" appBar={bar} bottomNav={nav}>
        {scope}
        <window.EmptyState node="statistics/insufficient" icon="bar_chart" title="Not enough data"
          text="Study a few more sessions and MemoX will chart your progress, streaks and due forecast." />
      </MxScaffold>
    );
  }

  if (state === 'error') {
    return (
      <MxScaffold node="statistics/screen" appBar={bar} bottomNav={nav}>
        {scope}
        <window.EmptyState node="statistics/error" icon="bar_chart" tone="error" title="Couldn't load stats"
          text="Something went wrong loading your statistics. Check your connection and try again."
          action={<MxButton variant="primary" icon="refresh" node="statistics/retry">Try again</MxButton>} />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="statistics/screen" appBar={bar} bottomNav={nav}>
      {scope}

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--memox-space-3)' }}>
        <MxCard variant="primary-soft" padding="sm" node="statistics/streak-current" style={{ alignItems: 'center' }}><window.Stat n="12" l="current streak" /></MxCard>
        <MxCard variant="muted" padding="sm" node="statistics/streak-longest" style={{ alignItems: 'center' }}><window.Stat n="28" l="longest" /></MxCard>
      </div>

      <div data-mx-node="statistics/heatmap">
        <MxSectionHeader title="Study calendar" caption="last 14 weeks" node="statistics/heatmap-head" />
        <MxCard><Heatmap /></MxCard>
      </div>

      <div data-mx-node="statistics/weekly">
        <MxSectionHeader title="Time per week" caption="min / day" node="statistics/weekly-head" />
        <MxCard><Bars data={[12, 18, 9, 24, 15, 30, 20]} labels={['M', 'T', 'W', 'T', 'F', 'S', 'S']} /></MxCard>
      </div>

      <div data-mx-node="statistics/leitner">
        <MxSectionHeader title="Leitner box distribution" caption="cards in boxes 1–8" node="statistics/leitner-head" />
        <MxCard><Bars data={[40, 28, 22, 18, 12, 9, 6, 4]} labels={['1', '2', '3', '4', '5', '6', '7', '8']} tone="var(--memox-accent, var(--memox-primary))" /></MxCard>
      </div>

      <div data-mx-node="statistics/accuracy">
        <MxSectionHeader title="Accuracy" caption="30 days" node="statistics/accuracy-head" />
        <MxCard><Donut pct={88} /></MxCard>
      </div>

      <div data-mx-node="statistics/overview">
        <MxSectionHeader title="Library overview" node="statistics/overview-head" />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 'var(--memox-space-3)' }}>
          {[['1240', 'total'], ['680', 'mastered'], ['96', 'due']].map(([n, l], i) => (
            <MxCard key={i} variant="muted" padding="sm" node={'statistics/ov-' + i} style={{ alignItems: 'center' }}><window.Stat n={n} l={l} /></MxCard>
          ))}
        </div>
      </div>
    </MxScaffold>
  );
}

window.Statistics = Statistics;
})();
