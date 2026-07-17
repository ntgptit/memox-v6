/* MemoX — Import cards. States: source · mapping · preview · dup-warning · done
   Feature-local components: components/{Table,SourceCard}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxCard, MxButton, MxChip, MxList } = NS;
const { Table, SourceCard } = window.MemoXImport;

const SOURCES = [
  { icon: 'description', name: 'CSV file', desc: 'Import from a .csv file' },
  { icon: 'table_chart', name: 'Excel', desc: 'Import from an .xlsx file' },
  { icon: 'content_paste', name: 'Paste text', desc: 'Copy from somewhere else' },
];
const SEPS = ['Tab', 'Comma', 'Semicolon'];
const ROWS = [['Term', 'Meaning'], ['안녕하세요', 'Hello'], ['감사합니다', 'Thank you'], ['사랑', 'love'], ['학교', 'school']];

const SectionLabel = window.SectionLabel;

function Import({ state = 'source' }) {
  const bar = <MxContextualAppBar variant="nested" title="Import cards" node="import/appbar" leading={<MxIconButton icon="arrow_back" node="import/back" />} />;

  if (state === 'importing') {
    return (
      <MxScaffold node="import/screen" appBar={bar}>
        {/* KIT-42-04: import progress is a polite live region (aria-busy while running). */}
        <div role="status" aria-live="polite" aria-busy="true">
        <MxCard node="import/importing">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)' }}>
            <div style={{ fontSize: 'var(--memox-font-size-md)', fontWeight: 'var(--memox-font-weight-bold)' }}>Importing…</div>
            <window.ProgressBar value={62} node="import/importing-bar" />
            <div style={{ fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>77 / 124 cards · don’t close this screen</div>
          </div>
        </MxCard>
        </div>
      </MxScaffold>
    );
  }

  if (state === 'import-error') {
    return (
      <MxScaffold node="import/screen" appBar={bar}>
        <window.EmptyState announce="alert" node="import/error" icon="error" tone="error" title="Import failed"
          text="Couldn’t read the file at row 78. Check the format and try again."
          action={<MxButton variant="primary" icon="refresh" node="import/retry">Try again</MxButton>} />
      </MxScaffold>
    );
  }

  if (state === 'done') {
    return (
      <MxScaffold node="import/screen" appBar={bar}>
        <window.EmptyState announce="status" node="import/done" icon="task_alt" tone="success" title="Imported 124 cards"
          text="The new cards were added to “TOPIK I — Vocabulary”."
          action={<MxButton variant="primary" icon="arrow_forward" node="import/go-deck">Back to deck</MxButton>} />
      </MxScaffold>
    );
  }

  /* parent-target (§17) — importing flat cards while a PARENT deck is the context. Cards can't
     land directly on a parent (§13), so choose/create a nested deck to receive them. Sheet over
     the source picker. */
  if (state === 'parent-target') {
    const { Scrim, Sheet, MenuItem } = window;
    return (
      <React.Fragment>
        <MxScaffold node="import/screen" appBar={bar}>
          <SectionLabel>CHOOSE SOURCE</SectionLabel>
          <MxList node="import/sources">{SOURCES.map((s, i) => <SourceCard key={i} source={s} index={i} />)}</MxList>
        </MxScaffold>
        <Scrim align="end" node="import/parent-scrim">
          <Sheet title="Choose where to import" node="import/parent-sheet">
            <div style={{ marginTop: 'calc(-1 * var(--memox-space-2))', marginBottom: 'var(--memox-space-2)', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-secondary)' }}>Korean TOPIK I is a parent deck — pick a nested deck to receive these cards.</div>
            <MenuItem icon="account_tree" label="Select a nested deck" node="import/parent-select-nested" />
            <MenuItem icon="library_add" label="Create a new nested deck" node="import/parent-create-nested" />
          </Sheet>
        </Scrim>
      </React.Fragment>
    );
  }

  if (state === 'source') {
    return (
      <MxScaffold node="import/screen" appBar={bar}>
        <SectionLabel>CHOOSE SOURCE</SectionLabel>
        <MxList node="import/sources">{SOURCES.map((s, i) => <SourceCard key={i} source={s} index={i} />)}</MxList>
        <div data-mx-node="import/paste" style={{ border: 'var(--memox-stroke-hairline) dashed var(--memox-divider)', borderRadius: 'var(--memox-radius-control)', minHeight: 'var(--memox-size-xl)', padding: 'var(--memox-space-4)', color: 'var(--memox-text-tertiary)', fontSize: 'var(--memox-font-size-base)' }}>Paste your data here (one card per line: term[tab]meaning)…</div>
      </MxScaffold>
    );
  }

  if (state === 'mapping') {
    return (
      <MxScaffold node="import/screen" appBar={bar}>
        <SectionLabel>SEPARATOR</SectionLabel>
        <div style={{ display: 'flex', gap: 'var(--memox-space-2)' }}>
          {SEPS.map((s, i) => <MxChip key={s} label={s} selected={i === 0} node={'import/sep-' + i} />)}
        </div>
        <SectionLabel>COLUMN MAPPING</SectionLabel>
        <MxCard padding="sm">
          <window.ListRow icon="text_fields" title="Column A → Term" sub="안녕하세요, 감사합니다…" node="import/map-term"
            trailing={<MxIconButton icon="expand_more" size="sm" node="import/map-term-pick" />} />
          <window.ListRow icon="translate" title="Column B → Meaning" sub="Hello, Thank you…" last node="import/map-meaning"
            trailing={<MxIconButton icon="expand_more" size="sm" node="import/map-meaning-pick" />} />
        </MxCard>
        <Table rows={ROWS} />
        <MxButton variant="primary" block node="import/to-preview">Continue</MxButton>
      </MxScaffold>
    );
  }

  // preview / dup-warning
  return (
    <MxScaffold node="import/screen" appBar={bar}>
      {state === 'dup-warning' ? (
        <window.ActionCallout node="import/dup-warning" icon="warning" text="8 cards already exist — import anyway?" />
      ) : null}
      <SectionLabel>PREVIEW · 124 CARDS</SectionLabel>
      <Table rows={ROWS} />
      <MxButton variant="primary" icon="download" block node="import/do-import">Import 124 cards</MxButton>
    </MxScaffold>
  );
}

window.Import = Import;
})();
