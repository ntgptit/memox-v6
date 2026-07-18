/* MemoX — Export cards. States: config · exporting · done
   Feature-local components: components/{ExportingCard,FormatList}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxCard, MxButton, MxChip, MxSegmentedControl } = NS;
const { ExportingCard, FormatList } = window.MemoXExport;

const SEPS = ['Tab', 'Comma', 'Semicolon'];

const SectionLabel = window.SectionLabel;

function Export({ state = 'config' }) {
  const bar = <MxContextualAppBar variant="nested" title="Export cards" node="export/appbar" leading={<MxIconButton icon="arrow_back" node="export/back" />} />;

  if (state === 'exporting') {
    return (
      <MxScaffold node="export/screen" appBar={bar}>
        <ExportingCard />
      </MxScaffold>
    );
  }

  if (state === 'export-error') {
    return (
      <MxScaffold node="export/screen" appBar={bar}>
        {/* KIT-42-04: failure is announced assertively so it interrupts the reader. */}
        <window.EmptyState announce="alert" node="export/error" icon="error" tone="error" title="Export failed"
          text="Something went wrong creating the file. Check available storage and try again."
          action={<MxButton variant="primary" icon="refresh" block node="export/retry">Try again</MxButton>} />
      </MxScaffold>
    );
  }

  if (state === 'done') {
    return (
      <MxScaffold node="export/screen" appBar={bar}>
        {/* KIT-42-04: success announced politely. */}
        <window.EmptyState announce="status" node="export/done" icon="ios_share" tone="success" title="Exported 320 cards"
          text="Your file is ready to share or save."
          action={<div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', width: 'var(--memox-size-3xl)' }}>
            <MxButton variant="primary" icon="share" block node="export/share">Share file</MxButton>
            <MxButton variant="ghost" icon="save_alt" block node="export/save">Save to device</MxButton>
          </div>} />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="export/screen" appBar={bar}>
      {/* Deck scope identity + Change affordance (business export-deck.md §4). */}
      <MxCard padding="sm">
        <window.ListRow icon="folder" title="Korean TOPIK I" sub="This deck" last node="export/deck-scope"
          trailing={<MxButton variant="ghost" size="sm" node="export/deck-change">Change</MxButton>} />
      </MxCard>

      <SectionLabel>SCOPE</SectionLabel>
      <MxSegmentedControl value="deck" onChange={() => {}} block node="export/scope"
        segments={[{ value: 'deck', label: 'This deck' }, { value: 'subtree', label: 'Incl. sub-decks' }]} />

      <SectionLabel>FORMAT</SectionLabel>
      <FormatList />

      {/* Separator applies to memox-csv-v1 only (CSV selected by default). */}
      <SectionLabel>SEPARATOR</SectionLabel>
      <div style={{ display: 'flex', gap: 'var(--memox-space-2)' }}>
        {SEPS.map((s, i) => <MxChip key={s} label={s} selected={i === 0} node={'export/sep-' + i} />)}
      </div>

      {/* Pre-export Summary of affected decks/cards (business export-deck.md §4). Content
          export never carries Learning Progress (formats-v1.md); the removed "Include review
          state" toggle would have leaked SRS box/due date — see ADR-009 / CF-10. */}
      <MxCard padding="sm">
        <window.ListRow icon="summarize" tone="accent" title="Summary" sub="1 deck · 320 cards" last node="export/summary" />
      </MxCard>

      <MxButton variant="primary" icon="download" block node="export/do-export">Export</MxButton>
    </MxScaffold>
  );
}

window.Export = Export;
})();
