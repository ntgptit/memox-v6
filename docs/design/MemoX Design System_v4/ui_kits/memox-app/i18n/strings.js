/* MemoX UI-kit — i18n string catalog (KIT-37-06, KIT-37-01).
   ------------------------------------------------------------------
   Externalized copy for the kit. Every value here is SEEDED FROM the real
   feature strings and MUST stay byte-identical to what the JSX renders today —
   this file is a *lookup table*, not a rewrite. Externalizing the copy is
   parity-neutral because:
     • the default locale is `en` and its values equal the current literals, and
     • every consumer calls `t(key, <the exact literal>)`, so even when this
       module is not loaded the rendered text is unchanged (the literal fallback
       wins). See i18n/README.md for the migration path.

   `en-XA` is a PSEUDO-LOCALE (KIT-37-01 expansion corpus): each string is
   grown 30–50% longer to stress-test truncation/wrapping. It is never the
   default; a screen opts into it explicitly (the `expansion` fixture states).

   Placeholders use ICU-style `{name}` tokens, resolved by `t(key, fb, vars)`.
   Self-registers on `window.MemoXI18n`; also ESM-exported for the compiler. */
(function () {
  const CATALOG = {
    en: {
      // account-sync
      'account.signin.title': 'Sync across devices',
      'account.signin.body': 'Sign in to back up and sync cards across devices. The app still works offline.',
      'account.signin.google': 'Sign in with Google',
      'account.signin.email.label': 'Email',
      'account.signin.email.placeholder': 'you@example.com',
      'account.signin.password.label': 'Password',
      'account.signin.password.placeholder': 'Your password',
      'account.signin.emailCta': 'Continue with email',
      'account.alpha': 'This feature is in alpha.',
      'account.sync.syncingTitle': 'Syncing…',
      'account.sync.syncingSub': 'Uploading changes',
      // reminder
      'reminder.title': 'Study reminders',
      'reminder.sub': 'Remind you to review every day',
      'reminder.timeLabel': 'REMINDER TIME',
      'reminder.repeat': 'REPEAT',
      'reminder.permission.title': 'Notifications are turned off',
      'reminder.permission.body': 'MemoX can’t remind you until notifications are enabled for this app in system settings.',
      'reminder.permission.cta': 'Open Settings',
      'reminder.permission.dismiss': 'Not now',
      // subdeck-list / shared
      'subdeck.offline': 'Offline · showing saved decks. Last synced {rel}.',
      'subdeck.notFound.title': 'This deck no longer exists',
      'subdeck.notFound.body': 'It may have been deleted or moved on another device. Head back to your library to keep studying.',
      'subdeck.notFound.cta': 'Back to Library',
      'common.retry': 'Retry',
      // count+noun composition (KIT-20-06) — resolved through format.plural()
      'cards.count': '{n, plural, one {# card} other {# cards}}',
      'due.count': '{n, plural, one {# due} other {# due}}',
    },
    // Pseudo-locale: +30–50% length, same meaning — expansion stress corpus.
    'en-XA': {
      'account.signin.title': 'Synchronise everything across all of your devices',
      'account.signin.body': 'Sign in to securely back up and continuously synchronise every one of your flashcards across all of your devices. The application still works completely offline.',
      'account.signin.google': 'Continue by signing in with your Google account',
      'account.signin.email.label': 'Email address',
      'account.signin.email.placeholder': 'you@example.com',
      'account.signin.password.label': 'Account password',
      'account.signin.password.placeholder': 'Enter your account password',
      'account.signin.emailCta': 'Continue using your email address',
      'account.alpha': 'Please note — this particular feature is currently in an early alpha.',
      'reminder.permission.title': 'Notifications are currently turned completely off',
      'reminder.permission.body': 'MemoX will be unable to remind you to study until notifications have been fully enabled for this application inside your system settings.',
      'reminder.permission.cta': 'Open the system settings',
      'reminder.permission.dismiss': 'Not right now',
      'subdeck.notFound.title': 'Unfortunately, this deck no longer exists',
      'subdeck.notFound.body': 'It may have been deleted or moved on one of your other devices. Please head back to your library so you can carry on studying.',
      'subdeck.notFound.cta': 'Return back to the Library',
    },
  };

  // Fill any en-XA gaps from en so an expansion lookup never misses.
  Object.keys(CATALOG.en).forEach((k) => {
    if (!(k in CATALOG['en-XA'])) CATALOG['en-XA'][k] = CATALOG.en[k];
  });

  function interpolate(str, vars) {
    if (!vars) return str;
    return str.replace(/\{(\w+)\}/g, (m, name) => (name in vars ? String(vars[name]) : m));
  }

  /* t(key, fallback, vars, opts?)
       key      — catalog key
       fallback — the exact literal the JSX would otherwise hard-code (REQUIRED
                  for parity: it is what renders when this module isn't loaded)
       vars     — {name: value} for `{name}` placeholders
       opts     — { locale } to force a locale (e.g. 'en-XA' for expansion) */
  function t(key, fallback, vars, opts) {
    const locale = (opts && opts.locale) || I18N.locale || 'en';
    const table = CATALOG[locale] || CATALOG.en;
    const raw = (key in table) ? table[key] : (key in CATALOG.en ? CATALOG.en[key] : (fallback != null ? fallback : key));
    return interpolate(raw, vars);
  }

  const I18N = {
    locale: 'en',
    locales: Object.keys(CATALOG),
    catalog: CATALOG,
    t,
    setLocale(l) { if (CATALOG[l]) I18N.locale = l; return I18N.locale; },
  };

  window.MemoXI18n = Object.assign(window.MemoXI18n || {}, I18N);
})();

export const MemoXI18n = window.MemoXI18n;
