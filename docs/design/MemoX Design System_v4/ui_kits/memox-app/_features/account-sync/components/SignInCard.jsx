/* MemoX — Account-sync local: SignInCard (signed-out hero + Google sign-in). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54 || {};
const { MxCard, MxButton, MxIconTile } = NS;
// i18n consumer (KIT-37-06) — safe accessor: fallback returns the exact current
// literal, so the render is byte-identical whether or not i18n/strings.js loads.
// `locale` lets the `expansion` fixture pull the +40% en-XA corpus (KIT-37-01).
const t = (window.MemoXI18n && window.MemoXI18n.t) || ((k, fb) => fb);

function SignInCard({ locale }) {
  const o = locale ? { locale } : undefined;
  return (
    <MxCard node="account/signin" style={{ alignItems: 'center', textAlign: 'center', gap: 'var(--memox-space-4)', padding: 'var(--memox-space-7) var(--memox-space-6)' }}>
      <MxIconTile icon="cloud_sync" tone="accent" size="lg" />
      <div>
        <div style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)' }}>{t('account.signin.title', 'Sync across devices', null, o)}</div>
        <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)', maxWidth: 'var(--memox-size-4xl)' }}>{t('account.signin.body', 'Sign in to back up and sync cards across devices. The app still works offline.', null, o)}</div>
      </div>
      <MxButton variant="primary" icon="login" block node="account/google">{t('account.signin.google', 'Sign in with Google', null, o)}</MxButton>
    </MxCard>
  );
}

window.MemoXAccountSync = window.MemoXAccountSync || {};
window.MemoXAccountSync.SignInCard = SignInCard;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const SignInCard = (window.MemoXAccountSync || {}).SignInCard;
