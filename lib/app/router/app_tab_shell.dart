import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/route_names.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_bottom_nav.dart';

/// One root destination of [AppTabShell], in tab order.
enum _RootDestination {
  today(RouteNames.home, Symbols.today_rounded),
  library(RouteNames.library, Symbols.style_rounded),
  stats(RouteNames.stats, Symbols.insights_rounded),
  profile(RouteNames.profile, Symbols.person_rounded);

  const _RootDestination(this.id, this.icon);

  final String id;
  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    _RootDestination.today => l10n.navTodayLabel,
    _RootDestination.library => l10n.libraryTitle,
    _RootDestination.stats => l10n.navStatsLabel,
    _RootDestination.profile => l10n.navProfileLabel,
  };
}

/// The persistent root-destination shell.
///
/// `MxBottomNav` documents itself as *the persistent bottom tab bar*, so it
/// is owned here — once, above the branch navigators — rather than rebuilt
/// inside each root screen. When only Library carried it, `goStats()` and
/// `goProfile()` replaced the stack with a screen that had no tab bar and
/// nothing to pop back to, stranding the user (no back affordance on Web,
/// system Back exits on Android).
///
/// Only the four root destinations live inside this shell. First-run,
/// deck detail and the Card Editor stay top-level so they cover the
/// tab bar, which is what their kit shots show.
class AppTabShell extends StatelessWidget {
  const AppTabShell({super.key, required this.navigationShell});

  /// Owns one navigator per branch, so each tab keeps its own stack and
  /// scroll state across switches.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: MxBottomNav(
          items: [
            for (final destination in _RootDestination.values)
              MxBottomNavItem(
                id: destination.id,
                label: destination.label(l10n),
                icon: destination.icon,
              ),
          ],
          value: _RootDestination.values[navigationShell.currentIndex].id,
          onChanged: (id) =>
              _goBranch(_RootDestination.values.indexWhere((d) => d.id == id)),
        ),
      ),
    );
  }

  /// Re-tapping the active tab pops that branch back to its root, which is
  /// the platform convention on both Tier-1 targets.
  void _goBranch(int index) {
    assert(index >= 0, 'Tab id does not match any root destination');
    if (index < 0) return;
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
