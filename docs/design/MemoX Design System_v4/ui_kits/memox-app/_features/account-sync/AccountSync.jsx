/* MemoX — Account & Sync. States: signed-out · signed-in · syncing · conflict · offline
   Feature-local components: components/{SyncBlock,SignInCard}.jsx
   Shared: window.ProfileCard (_shared/ProfileCard.jsx). */
(function () {
const NS = window.MemoXDesignSystem_2ffa54;
const { MxScaffold, MxContextualAppBar, MxIconButton, MxButton, MxBadge, MxCard } = NS;
const { SyncBlock, SignInCard } = window.MemoXAccountSync;
const ProfileCard = () => <window.ProfileCard node="account/profile" badge={<MxBadge tone="warning" soft>ALPHA</MxBadge>} />;
// i18n consumer (KIT-37-06) — fallback returns the exact literal (parity-neutral).
const t = (window.MemoXI18n && window.MemoXI18n.t) || ((k, fb) => fb);

/* Email/password sign-in field (KIT-35-05). Carries autofill/password-manager
   affordances: web `autoComplete` + `name`/`type`, and `data-text-content-type`
   as the React Native `textContentType`/`autoComplete` mapping. Real <input>s so
   the browser/OS password manager can offer to fill — used ONLY by the additive
   sign-in-form states, so no existing shot is affected. */
function AuthField({ label, type, name, autoComplete, textContentType, placeholder, value, node, autoFocus }) {
  return (
    <label data-mx-node={node} style={{ display: 'flex', flexDirection: 'column', gap: 'var(--memox-space-2)' }}>
      <span style={{ fontSize: 'var(--memox-font-size-sm)', fontWeight: 'var(--memox-font-weight-bold)', color: 'var(--memox-text-secondary)' }}>{label}</span>
      <input
        type={type} name={name} autoComplete={autoComplete} data-text-content-type={textContentType}
        placeholder={placeholder} defaultValue={value} autoFocus={autoFocus || undefined}
        inputMode={type === 'email' ? 'email' : undefined} enterKeyHint={type === 'password' ? 'go' : 'next'}
        style={{ minHeight: 'var(--memox-touch-min)', padding: 'var(--memox-space-3) var(--memox-space-4)', borderRadius: 'var(--memox-radius-control)', background: 'var(--memox-surface)', border: 'var(--memox-stroke-hairline) solid var(--memox-divider)', font: 'inherit', fontSize: 'var(--memox-font-size-base)', color: 'var(--memox-text)', outline: 'none' }} />
    </label>
  );
}

/* Email sign-in form — the password-manager path alongside Google sign-in. */
function EmailSignInForm({ emailFocus, passwordFilled }) {
  return (
    <MxCard node="account/signin-form" style={{ gap: 'var(--memox-space-4)', padding: 'var(--memox-space-6)' }}>
      <div style={{ fontSize: 'var(--memox-font-size-lg)', fontWeight: 'var(--memox-font-weight-extrabold)' }}>{t('account.signin.title', 'Sync across devices')}</div>
      <AuthField node="account/signin-email" label={t('account.signin.email.label', 'Email')} type="email" name="email"
        autoComplete="email" textContentType="emailAddress" placeholder={t('account.signin.email.placeholder', 'you@example.com')}
        value="learner@example.com" autoFocus={emailFocus} />
      <AuthField node="account/signin-password" label={t('account.signin.password.label', 'Password')} type="password" name="password"
        autoComplete="current-password" textContentType="password" placeholder={t('account.signin.password.placeholder', 'Your password')}
        value={passwordFilled ? 'secret-passphrase' : ''} />
      <MxButton variant="primary" icon="mail" block node="account/signin-email-cta">{t('account.signin.emailCta', 'Continue with email')}</MxButton>
      <div style={{ textAlign: 'center', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-tertiary)' }}>or</div>
      <MxButton variant="outline" icon="login" block node="account/google">{t('account.signin.google', 'Sign in with Google')}</MxButton>
    </MxCard>
  );
}

function AccountSync({ state = 'signed-out' }) {
  const bar = <MxContextualAppBar variant="nested" title="Account & Sync" node="account/appbar" leading={<MxIconButton icon="arrow_back" node="account/back" />} />;

  if (state === 'signed-out') {
    return (
      <MxScaffold node="account/screen" appBar={bar}>
        <SignInCard />
        <div style={{ textAlign: 'center', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-tertiary)' }}>{t('account.alpha', 'This feature is in alpha.')}</div>
      </MxScaffold>
    );
  }

  /* expansion — localization stress (KIT-37-01): the signed-out hero rendered with
     the en-XA pseudo-locale (+40% length) to verify the heading/body/CTA wrap and
     ellipsize without clipping. Additive state; pulls the long corpus explicitly. */
  // registry-state: expansion
  if (state === 'expansion') {
    return (
      <MxScaffold node="account/screen" appBar={bar}>
        <SignInCard locale="en-XA" />
        <div style={{ textAlign: 'center', fontSize: 'var(--memox-font-size-sm)', color: 'var(--memox-text-tertiary)' }}>{t('account.alpha', 'This feature is in alpha.', null, { locale: 'en-XA' })}</div>
      </MxScaffold>
    );
  }

  /* sign-in-form — email/password sign-in with autofill affordances (KIT-35-05). */
  // registry-state: sign-in-form
  if (state === 'sign-in-form') {
    return (
      <MxScaffold node="account/screen" appBar={bar}>
        <EmailSignInForm passwordFilled />
      </MxScaffold>
    );
  }

  /* sign-in-keyboard — the sign-in FORM with the software keyboard raised
     (KIT-25-04/35-01/36-01, form-feature keyboard-open): the "Continue"/Google
     actions live in the scrolling card, and the keyboard overlays only the body;
     nothing critical is trapped under it. */
  // registry-state: sign-in-keyboard
  if (state === 'sign-in-keyboard') {
    return (
      <MxScaffold node="account/screen" appBar={bar} bottomNav={<window.KeyboardInset node="account/keyboard" />}>
        <EmailSignInForm emailFocus />
      </MxScaffold>
    );
  }

  return (
    <MxScaffold node="account/screen" appBar={bar}>
      <ProfileCard />

      <SyncBlock state={state} />

      <MxButton variant="ghost" danger icon="logout" block node="account/signout">Sign out</MxButton>
    </MxScaffold>
  );
}

window.AccountSync = AccountSync;
})();
