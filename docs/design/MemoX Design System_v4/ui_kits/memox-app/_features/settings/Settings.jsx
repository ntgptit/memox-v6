/* MemoX — Settings. Hierarchical IA: a flat root + a Study-settings hub whose rows each open a
   child screen. States: loaded (root) · study-hub · study-worddisplay · study-srs · study-mode
   · study-voice · value-picker. (No Premium in v1.)
   Feature-local components: components/{ValuePickerSheet}.jsx
   Shared: window.ProfileCard (_shared/ProfileCard.jsx).
   Language pairs (Study › Language pairs) and Export (App › Export cards) live in their own
   features — reached from here, built after the Drawer was retired. */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxBottomNav, MxIconButton, MxCard, MxSwitch } = NS;
const { ValuePickerSheet } = window.MemoXSettings;
const Profile = () => <window.ProfileCard node="settings/profile" />;
const Label = window.SectionLabel;
const Row = window.ListRow;

const NAV = [
  { id: 'home', label: 'Today', icon: 'today' },
  { id: 'library', label: 'Library', icon: 'style' },
  { id: 'add', label: 'Add', icon: 'add_circle' },
  { id: 'stats', label: 'Stats', icon: 'insights' },
  { id: 'me', label: 'Profile', icon: 'person' },
];

function Val({ v }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--memox-space-1)', color: 'var(--memox-text-tertiary)' }}>
      {v ? <span style={{ fontWeight: 'var(--memox-font-weight-semibold)', fontSize: 'var(--memox-font-size-sm)' }}>{v}</span> : null}
      <span className="material-symbols-rounded" style={{ fontSize: 'var(--memox-font-size-lg)' }}>chevron_right</span>
    </div>
  );
}

// A nested child settings screen: back-titled bar + a single grouped card of rows.
function Child({ title, node, children }) {
  const bar = <MxContextualAppBar variant="nested" title={title} node={node + '-appbar'} leading={<MxIconButton icon="arrow_back" node={node + '-back'} />} />;
  return (
    <MxScaffold node="settings/screen" appBar={bar}>
      <MxCard padding="sm">{children}</MxCard>
    </MxScaffold>
  );
}

function Settings({ state = 'loaded' }) {
  const [notif, setNotif] = React.useState(true);
  const [gender, setGender] = React.useState(true);
  const [romaja, setRomaja] = React.useState(false);
  const [shuffle, setShuffle] = React.useState(true);
  const [autoplay, setAutoplay] = React.useState(false);
  const [tts, setTts] = React.useState(true);
  const [stt, setStt] = React.useState(false);

  // ---- Study-settings hub: one row per child screen ----
  if (state === 'study-hub') {
    const bar = <MxContextualAppBar variant="nested" title="Study settings" node="settings/study-appbar" leading={<MxIconButton icon="arrow_back" node="settings/study-back" />} />;
    return (
      <MxScaffold node="settings/screen" appBar={bar}>
        <MxCard padding="sm">
          <Row icon="translate" title="Language pairs" sub="한국어 → English · +1 more" node="settings/study-language" trailing={<Val v="" />} />
          <Row icon="format_shapes" title="Word display" sub="Native meaning · color by gender" node="settings/study-worddisplay" trailing={<Val v="" />} />
          <Row icon="schedule" title="Spaced repetition" sub="Boxes: 8 · Notifications on" node="settings/study-srs" trailing={<Val v="" />} />
          <Row icon="tune" title="Mode settings" sub="5 words/round · shuffle" node="settings/study-mode" trailing={<Val v="" />} />
          <Row icon="record_voice_over" title="Voice" sub="TTS on · STT off" last node="settings/study-voice" trailing={<Val v="" />} />
        </MxCard>
      </MxScaffold>
    );
  }

  if (state === 'study-worddisplay') {
    return (
      <Child title="Word display" node="settings/wd">
        <Row icon="translate" title="Meaning language" sub="Native · English" node="settings/wd-meaning" trailing={<Val v="" />} />
        <Row icon="palette" title="Color by gender" sub="Tint terms by grammatical gender" node="settings/wd-gender"
          trailing={<MxSwitch checked={gender} onChange={setGender} node="settings/wd-gender-switch" />} />
        <Row icon="spellcheck" title="Show romanization" sub="Reading under each term" last node="settings/wd-romaja"
          trailing={<MxSwitch checked={romaja} onChange={setRomaja} node="settings/wd-romaja-switch" />} />
      </Child>
    );
  }

  if (state === 'study-srs') {
    return (
      <Child title="Spaced repetition" node="settings/srs">
        <Row icon="grid_view" title="Leitner boxes" sub="Number of review boxes" node="settings/srs-boxes" trailing={<Val v="8" />} />
        <Row icon="timeline" title="Intervals (days)" sub="1 · 3 · 7 · 14 · 30 · 60 · 120" node="settings/srs-intervals" trailing={<Val v="" />} />
        <Row icon="notifications_active" title="Due notifications" last node="settings/srs-notif"
          trailing={<MxSwitch checked={notif} onChange={setNotif} node="settings/srs-notif-switch" />} />
      </Child>
    );
  }

  if (state === 'study-mode') {
    return (
      <Child title="Mode settings" node="settings/mode">
        <Row icon="filter_5" title="Words per round" sub="Cards shown each round" node="settings/mode-count" trailing={<Val v="5" />} />
        <Row icon="shuffle" title="Shuffle cards" sub="Randomize order each round" node="settings/mode-shuffle"
          trailing={<MxSwitch checked={shuffle} onChange={setShuffle} node="settings/mode-shuffle-switch" />} />
        <Row icon="volume_up" title="Autoplay audio" sub="Play term audio on reveal" last node="settings/mode-autoplay"
          trailing={<MxSwitch checked={autoplay} onChange={setAutoplay} node="settings/mode-autoplay-switch" />} />
      </Child>
    );
  }

  if (state === 'study-voice') {
    return (
      <Child title="Voice" node="settings/voice">
        <Row icon="record_voice_over" title="Text-to-speech" sub="Speak terms aloud" node="settings/voice-tts"
          trailing={<MxSwitch checked={tts} onChange={setTts} node="settings/voice-tts-switch" />} />
        <Row icon="speed" title="Speech rate" sub="Normal" node="settings/voice-rate" trailing={<Val v="" />} />
        <Row icon="mic" title="Speech-to-text" sub="Answer by speaking" last node="settings/voice-stt"
          trailing={<MxSwitch checked={stt} onChange={setStt} node="settings/voice-stt-switch" />} />
      </Child>
    );
  }

  // ---- Root (tab destination): a single Study-settings entry + app-level rows ----
  const bar = <MxContextualAppBar variant="root" title="Settings" node="settings/appbar" />;
  const nav = <MxBottomNav items={NAV} value="me" node="shell/bottom-nav" />;
  const loaded = (
    <MxScaffold node="settings/screen" appBar={bar} bottomNav={nav}>
      <Profile />
      <Label>STUDY</Label>
      <MxCard padding="sm">
        <Row icon="school" title="Study settings" sub="Languages · display · SRS · modes · voice" last node="settings/study" trailing={<Val v="" />} />
      </MxCard>
      <Label>APP</Label>
      <MxCard padding="sm">
        <Row icon="palette" title="Theme" sub="Light · default accent" node="settings/theme" trailing={<Val v="" />} />
        <Row icon="notifications" title="Reminders" sub="13:00 · Mon–Sun" node="settings/reminders" trailing={<Val v="" />} />
        <Row icon="backup" title="Backup / Restore" sub="Local file · on device" node="settings/backup" trailing={<Val v="" />} />
        <Row icon="download" title="Export cards" sub="CSV · Anki · JSON" last node="settings/export" trailing={<Val v="" />} />
      </MxCard>
    </MxScaffold>
  );

  if (state === 'value-picker') {
    return (
      <React.Fragment>
        {loaded}
        <ValuePickerSheet />
      </React.Fragment>
    );
  }

  return loaded;
}

window.Settings = Settings;
})();
