import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/settings/viewmodels/restore_defaults_viewmodel.dart';
import 'package:memox_v6/presentation/features/settings/widgets/appearance_sheet.dart';
import 'package:memox_v6/presentation/features/settings/widgets/mode_preferences_sheet.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_confirm_dialog.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';

/// Skeleton home screen; replaced when the Today feature (WBS 5.7) lands.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      // Entry into the built flows is the shell's tab bar; this stays a
      // bare placeholder until the Today dashboard (WBS 5.7) replaces it.
      body: Center(child: Text(l10n.appTitle)),
    );
  }
}

/// Skeleton stats screen; replaced when the Stats feature lands.
class StatsPlaceholderScreen extends StatelessWidget {
  const StatsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navStatsLabel)),
      body: Center(child: Text(l10n.appTitle)),
    );
  }
}

/// Skeleton profile screen; replaced when the account scope lands. Meanwhile it
/// hosts the settings hub (Appearance WBS 8.1, Study modes WBS 8.3, Restore
/// defaults WBS 8.6).
class ProfilePlaceholderScreen extends ConsumerWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    Future<void> restoreDefaults() async {
      final notifier = ref.read(
        restoreDefaultsCommandViewmodelProvider.notifier,
      );
      final confirmed = await showMxConfirmDialog(
        context,
        icon: Symbols.settings_backup_restore_rounded,
        tone: MxConfirmTone.warning,
        title: l10n.restoreDefaultsTitle,
        text: l10n.restoreDefaultsBody,
        confirmLabel: l10n.restoreDefaultsConfirmLabel,
        cancelLabel: l10n.cancelLabel,
      );
      if (confirmed) await notifier.restoreDefaults();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfileLabel)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Symbols.contrast_rounded),
            title: Text(l10n.appearanceLabel),
            onTap: () => showAppearanceSheet(context),
          ),
          ListTile(
            leading: const Icon(Symbols.tune_rounded),
            title: Text(l10n.studyModesLabel),
            onTap: () => showModePreferencesSheet(context),
          ),
          ListTile(
            leading: const Icon(Symbols.settings_backup_restore_rounded),
            title: Text(l10n.restoreDefaultsLabel),
            onTap: restoreDefaults,
          ),
        ],
      ),
    );
  }
}

/// Shown for unknown or stale locations (web deep links, old bookmarks).
///
/// Rendered by the router's `errorBuilder`, outside the tab shell, so it
/// carries its own recovery: without it a stale URL would strand the user
/// (no in-app Back on Web, system Back exits on Android). The navigation
/// contract requires a typed recovery destination here.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.routeNotFoundMessage),
            const MxGap.s4(),
            FilledButton(
              onPressed: () => context.goHome(),
              child: Text(l10n.routeNotFoundRecoveryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
