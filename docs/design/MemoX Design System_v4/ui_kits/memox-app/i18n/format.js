/* MemoX UI-kit — locale format layer (KIT-37-04, KIT-20-04, KIT-20-06).
   ------------------------------------------------------------------
   Intl-based helpers for date / time / number / relative-time / plural so copy
   is NEVER hard-coded to English grammar or US formatting. Each helper takes a
   `locale` (defaults to `window.MemoXI18n.locale` or 'en') and degrades safely:
   if `Intl` (or a sub-API) is unavailable it returns a plain fallback, so the
   kit renders identically whether or not this module is loaded — parity-neutral.

   IMPORTANT for parity: when wiring an EXISTING shot, pass the current literal
   through as the natural output (e.g. `time(new Date(2000,0,1,14,2)) === '14:02'`
   in `en`), or guard the call so the rendered value is byte-identical. New
   fixture states may format freely. Self-registers on `window.MemoXFormat`. */
(function () {
  function loc(locale) {
    return locale || (window.MemoXI18n && window.MemoXI18n.locale) || 'en';
  }
  function safe(fn, fallback) {
    try { return fn(); } catch (e) { return fallback; }
  }

  /* Date — e.g. 'Jul 16, 2026' (en, 'medium'). */
  function date(value, opts, locale) {
    const d = value instanceof Date ? value : new Date(value);
    const o = opts || { year: 'numeric', month: 'short', day: 'numeric' };
    return safe(() => new Intl.DateTimeFormat(loc(locale), o).format(d), String(d));
  }

  /* Time — 24h 'HH:mm' by default (e.g. '14:02'), matching the kit's clock copy. */
  function time(value, opts, locale) {
    const d = value instanceof Date ? value : new Date(value);
    const o = opts || { hour: '2-digit', minute: '2-digit', hourCycle: 'h23' };
    return safe(() => new Intl.DateTimeFormat(loc(locale), o).format(d), String(d));
  }

  /* Number — grouped by locale (e.g. '1,280'). */
  function number(value, opts, locale) {
    return safe(() => new Intl.NumberFormat(loc(locale), opts).format(value), String(value));
  }

  /* Relative time — e.g. relativeTime(-2, 'hour') → '2 hours ago' (en). */
  function relativeTime(value, unit, opts, locale) {
    const o = opts || { numeric: 'auto' };
    return safe(() => new Intl.RelativeTimeFormat(loc(locale), o).format(value, unit),
      Math.abs(value) + ' ' + unit + (Math.abs(value) === 1 ? '' : 's') + (value < 0 ? ' ago' : ''));
  }

  /* Plural category — 'one' | 'other' | … per CLDR rules for the locale. */
  function plural(n, locale) {
    return safe(() => new Intl.PluralRules(loc(locale)).select(n), n === 1 ? 'one' : 'other');
  }

  /* count(n, one, other) — the ONE count+noun composer (KIT-20-06). Picks the
     right grammatical form instead of concatenating a fragment. `one`/`other`
     are templates with a `#` placeholder, e.g. count(3, '# card', '# cards'). */
  function count(n, one, other, locale) {
    const cat = plural(n, locale);
    const tpl = cat === 'one' ? one : other;
    return tpl.replace('#', number(n, undefined, locale));
  }

  window.MemoXFormat = Object.assign(window.MemoXFormat || {}, {
    date, time, number, relativeTime, plural, count,
  });
})();

export const MemoXFormat = window.MemoXFormat;
