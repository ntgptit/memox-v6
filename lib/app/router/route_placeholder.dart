import 'package:flutter/material.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

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

/// Skeleton profile screen; replaced when the account scope lands.
class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfileLabel)),
      body: Center(child: Text(l10n.appTitle)),
    );
  }
}

/// Shown for unknown or stale locations (web deep links, old bookmarks).
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(child: Text(l10n.routeNotFoundMessage)),
    );
  }
}
