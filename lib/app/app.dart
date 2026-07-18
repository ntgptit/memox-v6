import 'package:flutter/material.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

/// Root application widget composed by the bootstrap entry.
///
/// Owns only cross-cutting `MaterialApp` configuration (localization, theme
/// mode plumbing, router wiring). Theme tokens replace the default
/// [ThemeData] in WBS 2.x.
class MemoxApp extends StatelessWidget {
  const MemoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(),
      routerConfig: appRouter,
    );
  }
}
