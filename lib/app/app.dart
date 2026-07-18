import 'package:flutter/material.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

/// Root application widget composed by the bootstrap entry.
///
/// Owns only cross-cutting `MaterialApp` configuration (localization, theme
/// mode plumbing). The real route table replaces [home] in WBS 1.4; theme
/// tokens replace the default [ThemeData] in WBS 2.x.
class MemoxApp extends StatelessWidget {
  const MemoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(),
      home: const _BootstrapHomePage(),
    );
  }
}

/// Minimal localized landing shown until the router (WBS 1.4) owns `/`.
class _BootstrapHomePage extends StatelessWidget {
  const _BootstrapHomePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Center(child: Text(l10n.appTitle)),
    );
  }
}
