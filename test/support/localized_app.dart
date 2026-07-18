import 'package:flutter/material.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

/// Standard wrapper for localized widget tests.
///
/// Every widget test that renders user-facing copy pumps through this so
/// delegates/locales always match the real app configuration.
Widget localizedApp(Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
