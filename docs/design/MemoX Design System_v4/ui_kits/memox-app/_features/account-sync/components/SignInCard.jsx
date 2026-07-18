/* MemoX — Account-sync local: SignInCard (signed-out hero).
   Cloud provider is DEFERRED (business account/cloud-service-gate.md, ADR-009 / CF-02):
   until the gate is accepted, no provider may be inferred and cloud CTAs must be absent or
   explicitly labelled unavailable. The sign-in CTA is therefore disabled/"coming soon" — no
   Google/email provider is pre-committed. The app is fully usable offline/local-first. */
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
        <div style={{ fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text-secondary)', marginTop: 'var(--memox-space-1)', maxWidth: 'var(--memox-size-4xl)' }}>{t('account.signin.body', 'Your decks and progress are saved on this device. Cloud backup and sync across devices are coming later.', null, o)}</div>
      </div>
      <MxButton variant="primary" icon="cloud_off" block disabled node="account/signin-cta">{t('account.signin.cta', 'Cloud sync — coming soon', null, o)}</MxButton>
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
