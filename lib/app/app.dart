import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox_v6/app/router/router_providers.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/domain/preferences/appearance_mode.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/settings/viewmodels/appearance_viewmodel.dart';

/// Root application widget composed by the bootstrap entry.
///
/// Owns only cross-cutting `MaterialApp` configuration (localization, theme
/// wiring, router wiring). Theme mode follows the system until the
/// appearance preference (WBS 8.1) persists a user choice.
class MemoxApp extends ConsumerWidget {
  const MemoxApp({super.key, this.builder});

  /// Optional wrapper inserted between `MaterialApp` and the routed
  /// content. Production passes nothing; the visual-parity harness
  /// (`lib/app/dev/parity_main.dart`) uses it to inject the device
  /// safe-area inset the browser does not report, so a Flutter Web
  /// capture lines up with the Design Kit shot.
  final TransitionBuilder? builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The appearance preference (WBS 8.1) themes the whole app; an unresolved
    // or invalid value follows the system theme (set-appearance-preference.md).
    final appearance =
        ref.watch(appearanceModeProvider).value ?? AppearanceMode.system;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (appearance) {
        AppearanceMode.system => ThemeMode.system,
        AppearanceMode.light => ThemeMode.light,
        AppearanceMode.dark => ThemeMode.dark,
      },
      routerConfig: ref.watch(appRouterInstanceProvider),
      builder: builder,
    );
  }
}
