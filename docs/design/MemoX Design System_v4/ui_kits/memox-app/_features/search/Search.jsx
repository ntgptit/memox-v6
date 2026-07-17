/* MemoX — Search. States: empty-recent · results · filtered · no-results · loading
   Feature-local components: components/{ResultRow,Chips}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxCard, MxList, MxLink } = NS;
const { ResultRow, Chips } = window.MemoXSearch;

const RESULTS = [
  { term: '공부하다', meaning: 'to study', deck: 'TOPIK I — Vocabulary', status: 'due' },
  { term: '좋아하다', meaning: 'to like', deck: 'Common Verbs', status: 'mastered' },
  { term: '하다', meaning: 'to do (auxiliary)', deck: 'TOPIK I — Vocabulary', status: 'new', hidden: true },
];
const RECENT = [
  { term: '안녕하세요', gloss: 'hello' },
  { term: '학교', gloss: 'school' },
  { term: '감사합니다', gloss: 'thank you' },
];

function Search({ state = 'empty-recent' }) {
  const val = state === 'empty-recent' ? '' : (state === 'no-results' ? 'xyz' : '하');
  const bar = (
    <MxContextualAppBar variant="search" node="search/appbar"
      search={{ value: val, placeholder: 'Search by word or meaning' }}
      actions={val ? <MxIconButton icon="close" size="sm" node="search/clear" ariaLabel="Clear" /> : null} />
  );

  if (state === 'empty-recent') {
    return (
      <MxScaffold node="search/screen" appBar={bar}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <window.SectionLabel style={{ flex: 1, margin: 0 }}>RECENT</window.SectionLabel>
          <MxLink size="sm" trailingIcon={null} node="search/recent-clear">Clear all</MxLink>
        </div>
        <MxCard padding="sm" style={{ background: 'var(--memox-surface-raised)' }}>
          {RECENT.map((r, i) => (
            <window.ListRow key={r.term} icon="history" title={r.term} sub={r.gloss} last={i === RECENT.length - 1} node={'search/recent-' + i}
              trailing={<div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-1)' }}>
                <MxIconButton icon="north_west" size="sm" node={'search/recent-fill-' + i} ariaLabel="Use in search" />
                <MxIconButton icon="close" size="sm" node={'search/recent-remove-' + i} ariaLabel="Remove from history" />
              </div>} />
          ))}
        </MxCard>
      </MxScaffold>
    );
  }

  if (state === 'loading') {
    const S = window.Skeleton;
    return (
      <MxScaffold node="search/screen" appBar={bar}>
        <Chips active={0} />
        <MxList node="search/loading">{[0, 1, 2].map((i) => (
          <MxCard key={i} padding="sm"><S w="40%" h={16} /><S w="62%" h={10} style={{ marginTop: 'var(--memox-space-2)' }} /><S w="50%" h={10} style={{ marginTop: 'var(--memox-space-2)' }} /></MxCard>
        ))}</MxList>
      </MxScaffold>
    );
  }

  if (state === 'no-results') {
    return (
      <MxScaffold node="search/screen" appBar={bar}>
        <Chips active={0} />
        <window.EmptyState node="search/no-results" icon="search_off" tone="warning" title="No matches"
          text={'Nothing matched “xyz”. Try another term or check the spelling.'} />
      </MxScaffold>
    );
  }

  const filtered = state === 'filtered';
  const rows = filtered ? RESULTS.filter((r) => r.status === 'due') : RESULTS;
  return (
    <MxScaffold node="search/screen" appBar={bar}>
      <Chips active={filtered ? 2 : 0} />
      <MxList node="search/results">{rows.map((r, i) => (
        <MxCard key={i} padding="sm" interactive node={'search/result-' + i}><ResultRow {...r} /></MxCard>
      ))}</MxList>
    </MxScaffold>
  );
}

window.Search = Search;
})();
