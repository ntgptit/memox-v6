import 'package:flutter/material.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

/// Root application widget composed by the bootstrap entry.
///
/// Owns only cross-cutting `MaterialApp` configuration (localization, theme
/// wiring, router wiring). Theme mode follows the system until the
/// appearance preference (WBS 8.1) persists a user choice.
class MemoxApp extends StatelessWidget {
  const MemoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
