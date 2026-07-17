/* MemoX — Languages: manage learning↔native language pairs. States: list · one · empty · add · remove
   Feature-local components: components/{LangCard,RemoveLanguageDialog}.jsx
   Rehomed from the retired Drawer; reached from Settings › Study settings › Language pairs. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxCard, MxButton } = NS;
const { LangCard, RemoveLanguageDialog } = window.MemoXLanguages;

const PAIRS = [
  { title: '한국어 → English', sub: '1240 cards' },
  { title: '日本語 → English', sub: '430 cards' },
];

// Per-script rendering specimen (KIT-37-02 / KIT-09-04): a polyglot user's pairs spanning
// Latin-with-diacritics (Vietnamese) and CJK (Korean / Japanese / Chinese), rendered through the
// declared --memox-font-cjk fallback stack so every glyph resolves — proving Vietnamese diacritics,
// CJK glyphs and mixed-script (native script + "→ English") baselines render without tofu or clipping.
const SCRIPT_SPECIMEN = [
  { title: 'Tiếng Việt → English', sub: 'Diacritics: ầ ế ộ ữ đ · 210 cards' },
  { title: '한국어 → English', sub: 'Hangul · CJK · 1240 cards' },
  { title: '日本語 → English', sub: 'かな・漢字 · CJK · 430 cards' },
  { title: '中文 → English', sub: '汉字（简体）· CJK · 512 cards' },
];

function pairsFor(state) {
  if (state === 'empty') return [];
  if (state === 'one') return PAIRS.slice(0, 1);
  return PAIRS;
}

function Languages({ state = 'list' }) {
  const bar = (
    <MxContextualAppBar variant="nested" title="Language pairs" node="languages/appbar"
      leading={<MxIconButton icon="arrow_back" node="languages/back" />} />
  );

  if (state === 'add') {
    return (
      <MxScaffold node="languages/screen" appBar={<MxContextualAppBar variant="nested" title="Add language pair" node="languages/add-appbar" leading={<MxIconButton icon="arrow_back" node="languages/add-back" />} />}>
        <window.SectionLabel>LEARNING</window.SectionLabel>
        <LangCard icon="language" name="한국어" sub="Korean" node="languages/learn-lang" />
        <div style={{ display: 'flex', justifyContent: 'center', color: 'var(--memox-text-tertiary)' }}><span className="material-symbols-rounded">arrow_downward</span></div>
        <window.SectionLabel style={{ margin: '0 0 0 var(--memox-space-1)' }}>NATIVE</window.SectionLabel>
        <LangCard icon="translate" name="English" sub="Meaning language" node="languages/native-lang" />
        <MxButton variant="primary" icon="add" block node="languages/add-confirm">Add language pair</MxButton>
      </MxScaffold>
    );
  }

  // registry-state: scripts
  if (state === 'scripts') {
    return (
      <MxScaffold node="languages/screen" appBar={bar}>
        <window.SectionLabel>SCRIPT RENDERING · Vietnamese diacritics + CJK</window.SectionLabel>
        <MxCard padding="sm">
          <div style={{ fontFamily: 'var(--memox-font-cjk)' }}>
            {SCRIPT_SPECIMEN.map((p, i) => (
              <window.ListRow key={i} icon="translate" title={p.title} sub={p.sub} last={i === SCRIPT_SPECIMEN.length - 1} node={'languages/script-' + i} />
            ))}
          </div>
        </MxCard>
      </MxScaffold>
    );
  }

  const pairs = pairsFor(state);

  if (!pairs.length) {
    return (
      <MxScaffold node="languages/screen" appBar={bar}>
        <window.EmptyState node="languages/empty" icon="translate" title="No language pairs yet"
          text="Add a learning language and the language you want its meanings in."
          action={<MxButton variant="primary" icon="add" node="languages/empty-add">Add language pair</MxButton>} />
      </MxScaffold>
    );
  }

  const list = (
    <MxScaffold node="languages/screen" appBar={bar}>
      <MxCard padding="sm">
        {pairs.map((p, i) => (
          <window.ListRow key={i} icon="translate" title={p.title} sub={p.sub} last={i === pairs.length - 1} node={'languages/pair-' + i}
            trailing={<MxIconButton icon="delete" node={'languages/pair-' + i + '-del'} />} />
        ))}
      </MxCard>
      <MxButton variant="secondary" icon="add" block node="languages/add">Add language pair</MxButton>
    </MxScaffold>
  );

  if (state === 'remove') {
    return <React.Fragment>{list}<RemoveLanguageDialog /></React.Fragment>;
  }
  return list;
}

window.Languages = Languages;
})();

/* ESM export so the design-system compiler indexes this kit screen. */
export const Languages = window.Languages;
