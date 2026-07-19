import 'package:flutter/material.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';

/// Skeleton home screen; replaced when the Today feature (WBS 5.7) lands.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appTitle),
            const MxGap.s4(),
            // Entry into the built flows until the Today dashboard
            // (WBS 5.7) replaces this placeholder.
            FilledButton(
              onPressed: () => context.goLibrary(),
              child: Text(l10n.libraryTitle),
            ),
          ],
        ),
      ),
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
