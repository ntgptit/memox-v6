/* MemoX — Reminders. States: on · off · time-picker
   Feature-local components: components/{TimeCol,TimePickerSheet}.jsx */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxCard, MxSwitch, MxChip, MxButton } = NS;
const { TimePickerSheet } = window.MemoXReminder;
// i18n consumer (KIT-37-06) — fallback returns the exact literal (parity-neutral).
const t = (window.MemoXI18n && window.MemoXI18n.t) || ((k, fb) => fb);

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

function Reminder({ state = 'on' }) {
  const on = state !== 'off';
  const bar = <MxContextualAppBar variant="nested" title="Reminders" node="reminder/appbar" leading={<MxIconButton icon="arrow_back" node="reminder/back" />} />;

  /* permission-denied — the OS notification permission was denied, so reminders
     can't fire regardless of the in-app toggle (KIT-36-05, capability-denied).
     Shows the denied state + a recovery CTA into system settings. The
     `-expansion` variant renders the same with the en-XA +40% corpus (KIT-37-01). */
  if (state === 'permission-denied' || state === 'permission-denied-expansion') {
    // registry-state: permission-denied
    // registry-state: permission-denied-expansion
    const o = state === 'permission-denied-expansion' ? { locale: 'en-XA' } : undefined;
    return (
      <MxScaffold node="reminder/screen" appBar={bar}>
        <window.EmptyState node="reminder/permission-denied" icon="notifications_off" tone="warning"
          title={t('reminder.permission.title', 'Notifications are turned off', null, o)}
          text={t('reminder.permission.body', 'MemoX can’t remind you until notifications are enabled for this app in system settings.', null, o)}
          action={<div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-3)', width: 'var(--memox-size-3xl)' }}>
            <MxButton variant="primary" icon="settings" block node="reminder/permission-settings">{t('reminder.permission.cta', 'Open Settings', null, o)}</MxButton>
            <MxButton variant="ghost" block node="reminder/permission-dismiss">{t('reminder.permission.dismiss', 'Not now', null, o)}</MxButton>
          </div>} />
      </MxScaffold>
    );
  }

  const base = (
    <MxScaffold node="reminder/screen" appBar={bar}>
      <MxCard padding="sm">
        <window.ListRow icon="notifications" tone="warning" title={t('reminder.title', 'Study reminders')} sub={t('reminder.sub', 'Remind you to review every day')} last node="reminder/toggle"
          trailing={<MxSwitch checked={on} onChange={() => {}} node="reminder/toggle-switch" />} />
      </MxCard>

      <MxCard interactive node="reminder/time" style={{ opacity: on ? 1 : 'var(--memox-opacity-half)' }}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <div style={{ flex: 1 }}>
            <window.SectionLabel style={{ margin: 0 }}>{t('reminder.timeLabel', 'REMINDER TIME')}</window.SectionLabel>
            <div style={{ fontSize: 'var(--memox-font-size-3xl)', fontWeight: 'var(--memox-font-weight-extrabold)', letterSpacing: 'var(--memox-letter-spacing-tight)' }}>13:00</div>
          </div>
          <MxIconButton icon="schedule" node="reminder/time-edit" />
        </div>
      </MxCard>

      <div data-mx-node="reminder/days" style={{ opacity: on ? 1 : 'var(--memox-opacity-half)' }}>
        <window.SectionLabel style={{ margin: '0 0 var(--memox-space-2) var(--memox-space-1)' }}>{t('reminder.repeat', 'REPEAT')}</window.SectionLabel>
        <div style={{ display: 'flex', gap: 'var(--memox-space-2)', flexWrap: 'wrap' }}>
          {WEEKDAYS.map((d, i) => <MxChip key={d} label={d} selected={on} node={'reminder/day-' + i} />)}
        </div>
      </div>
    </MxScaffold>
  );

  if (state === 'time-picker') {
    return (
      <React.Fragment>
        {base}
        <TimePickerSheet />
      </React.Fragment>
    );
  }

  return base;
}

window.Reminder = Reminder;
})();
