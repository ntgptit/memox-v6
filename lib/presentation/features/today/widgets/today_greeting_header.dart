import 'package:flutter/widgets.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The dashboard's greeting headline (kit `dashboard/greeting`).
///
/// It lives in the scroll body rather than the app bar, deliberately: the kit
/// splits it out so the greeting scrolls away with the content while the slim
/// bar stays. Every dashboard state carries it, so it is the first thing any
/// of them needs.
///
/// **No date line.** This carried a date eyebrow until 2026-07-26, which the
/// kit does not draw anywhere on this screen: `MxContextualAppBar`'s `root`
/// variant is "title + trailing actions" and takes no context slot, and
/// `dashboard--loaded` shows no date either. `Dashboard.jsx` still carries a
/// comment about the date living in the bar, but it passes no such prop — the
/// comment is stale against the component it calls, and the eyebrow was built
/// from the comment rather than from either.
///
/// The kit writes "Good evening, Linh". There is no account in this build —
/// sign-in is WBS 14.x — so the name is dropped rather than invented, and the
/// greeting is the time-of-day half alone. Inventing a placeholder name would
/// put a fake identity on the first screen the learner sees.
class TodayGreetingHeader extends StatelessWidget {
  const TodayGreetingHeader({super.key, required this.now});

  /// Injected rather than read from the clock here, so the greeting a test or
  /// a parity capture sees is the one it asked for.
  final DateTime now;

  /// Morning until noon, afternoon until 18:00, evening after — the ordinary
  /// reading of the kit's three greetings.
  String _greeting(AppLocalizations l10n) {
    if (now.hour < 12) return l10n.todayGreetingMorning;
    if (now.hour < 18) return l10n.todayGreetingAfternoon;
    return l10n.todayGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Kit: 2xl/extrabold with tight tracking — the same ramp the large app
    // bar used before the greeting was split out of it.
    return Align(
      alignment: Alignment.centerLeft,
      child: MxText(_greeting(l10n), role: MxTextRole.display),
    );
  }
}
