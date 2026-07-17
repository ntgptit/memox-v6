/* MemoX — Theme. States: light · dark · accent-size
   Feature-local components: components/{PreviewCard,AccentPicker}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxSegmentedControl, MxSectionHeader } = NS;
const { PreviewCard, AccentPicker } = window.MemoXTheme;

// Presentational palette samples for the accent picker.
const SWATCHES = ['var(--memox-palette-indigo)', 'var(--memox-palette-violet)', 'var(--memox-palette-green)', 'var(--memox-palette-coral)', 'var(--memox-palette-amber)', 'var(--memox-palette-cyan)'];

function Theme({ state = 'light' }) {
  const mode = state === 'dark' ? 'dark' : 'light';
  const size = state === 'accent-size' ? 'lg' : 'md';
  const accent = state === 'accent-size' ? 1 : 0;
  const accentColor = SWATCHES[accent];
  const termSize = size === 'lg' ? 'var(--memox-font-size-3xl)' : size === 'sm' ? 'var(--memox-font-size-xl)' : 'var(--memox-font-size-2xl)';

  const bar = <MxContextualAppBar variant="nested" title="Theme" node="theme/appbar" leading={<MxIconButton icon="arrow_back" node="theme/back" />} />;

  return (
    <MxScaffold node="theme/screen" appBar={bar}>
      <PreviewCard termSize={termSize} accentColor={accentColor} />

      <div data-mx-node="theme/mode">
        <MxSectionHeader title="Color mode" node="theme/mode-head" />
        <MxSegmentedControl value={mode} onChange={() => {}} block node="theme/mode-control"
          segments={[{ value: 'light', label: 'Light' }, { value: 'dark', label: 'Dark' }, { value: 'system', label: 'System' }]} />
      </div>

      <div data-mx-node="theme/accent">
        <MxSectionHeader title="Accent color" node="theme/accent-head" />
        <AccentPicker swatches={SWATCHES} accent={accent} />
      </div>

      <div data-mx-node="theme/size">
        <MxSectionHeader title="Text size" node="theme/size-head" />
        <MxSegmentedControl value={size} onChange={() => {}} block node="theme/size-control"
          segments={[{ value: 'sm', label: 'Small' }, { value: 'md', label: 'Medium' }, { value: 'lg', label: 'Large' }]} />
      </div>
    </MxScaffold>
  );
}

window.Theme = Theme;
})();
