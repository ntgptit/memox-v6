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
