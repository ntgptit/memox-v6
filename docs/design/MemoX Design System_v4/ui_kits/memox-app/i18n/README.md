# `i18n/` — string externalization + locale format layer

Closes the i18n root gaps in the kit audit: **KIT-37-06** (copy was English-only
literals hard-coded in JSX), **KIT-37-04 / KIT-20-04** (date/time/number/relative
time hard-coded to English), **KIT-37-01** (no localization *expansion* corpus),
and gives **KIT-20-06** a real count+noun composer.

## Files

| File | Purpose |
|---|---|
| `strings.js` | Keyed copy catalog. `window.MemoXI18n.t(key, fallback, vars, opts)`. Default locale `en` seeded byte-identical to the current JSX literals. Pseudo-locale `en-XA` grows every string 30–50% for the expansion stress fixtures (KIT-37-01). |
| `format.js` | `window.MemoXFormat` — `Intl`-based `date` / `time` / `number` / `relativeTime` / `plural` / `count`. Degrades to a plain fallback if `Intl` is missing. |

## Parity contract (why this is safe to add)

Externalizing copy is **parity-neutral** by construction:

1. **Every consumer passes the exact current literal as the fallback** —
   `t('account.signin.google', 'Sign in with Google')`. If `strings.js` is not
   loaded, `window.MemoXI18n` is `undefined`, the consumer's local
   `t = (window.MemoXI18n && window.MemoXI18n.t) || ((k, fb) => fb)` returns the
   literal, and the pixels are unchanged.
2. **When it *is* loaded**, the `en` catalog value equals that same literal, so
   the render is still byte-identical.
3. The **`en-XA` expansion** locale is only ever selected explicitly by the new
   `expansion` fixture states, which are additive (not part of any existing
   shot), so no existing shot moves.

The same rule governs `format.js`: for an existing shot, the formatted output is
made to equal the current literal (e.g. `time(…,14:02)` → `'14:02'` in `en`);
new fixtures may format freely.

## Migration path (kit → production)

1. **Load the modules.** Add, in `index.html`, before the feature scripts:
   ```html
   <script type="text/babel-src" src="i18n/strings.js"></script>
   <script type="text/babel-src" src="i18n/format.js"></script>
   ```
   (Left to the kit-build/orchestrator step — the `_features` remain correct with
   or without it thanks to the fallback contract above.)
2. **Wire a feature** by grabbing the safe accessors at the top of the screen
   module and replacing literals key-by-key:
   ```js
   const t = (window.MemoXI18n && window.MemoXI18n.t) || ((k, fb) => fb);
   const fmt = window.MemoXFormat || { relativeTime: (v,u)=> Math.abs(v)+' '+u+'s ago' };
   …
   <div>{t('reminder.title', 'Study reminders')}</div>
   ```
   Reference wirings shipped in this round: `account-sync` (SignInCard copy +
   sign-in form), `reminder` (labels + permission-denied copy), and
   `subdeck-list` (offline relative-time + not-found copy).
3. **Add a real locale** by adding a `CATALOG.<bcp47>` block in `strings.js` and
   calling `MemoXI18n.setLocale('<bcp47>')`. `format.js` needs no change — it
   reads `MemoXI18n.locale`.
4. **React Native**: `MemoXI18n` maps to any RN i18n runtime (i18next / LinguiJS);
   `MemoXFormat` maps to RN's `Intl` (Hermes `Intl` or `react-native-localize` +
   `Intl` polyfill). Keys and the `count()` composition rule are the stable
   contract; the backing runtime is swappable.

## Expansion corpus (KIT-37-01)

`en-XA` provides the +30–50% strings. Screens expose them through an additive
fixture state so the truncation/wrapping behaviour can be shot:

- `account-sync` → state **`expansion`** (sign-in hero with the long copy).
- `reminder` → state **`permission-denied-expansion`** (denied banner, long copy).

These verify that buttons, headings and body copy wrap/ellipsize without
clipping or overflow under a worst-case translation.
