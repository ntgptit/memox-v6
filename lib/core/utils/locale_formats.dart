import 'dart:ui';

import 'package:intl/intl.dart';

/// Locale-aware display formatting.
///
/// Presentation passes the active [Locale] (from `Localizations.localeOf`);
/// nothing here hardcodes a locale tag. Persistence never uses these —
/// stored values stay ISO-8601/UTC (data-layer contract).

/// Grouped integer, e.g. `1,234,567` (en) / `1.234.567` (vi).
String formatInteger(int value, Locale locale) =>
    NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);

/// Decimal with the locale's separator, e.g. `1,234.5` (en) / `1.234,5` (vi).
String formatDecimal(num value, Locale locale) =>
    NumberFormat.decimalPattern(locale.toLanguageTag()).format(value);

/// Fraction as localized percent, e.g. `0.42` → `42%`.
String formatPercent(double fraction, Locale locale) =>
    NumberFormat.percentPattern(locale.toLanguageTag()).format(fraction);

/// Medium date in locale words, e.g. `Jul 19, 2026` / `19 thg 7, 2026`.
///
/// The caller passes an already-localized instant; UTC→local conversion
/// happens at the injected clock/timezone boundary, not here.
String formatMediumDate(DateTime local, Locale locale) =>
    DateFormat.yMMMd(locale.toLanguageTag()).format(local);
