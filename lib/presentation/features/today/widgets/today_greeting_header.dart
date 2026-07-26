import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The dashboard's date eyebrow + greeting headline (kit
/// `dashboard/greeting`).
///
/// It lives in the scroll body rather than the app bar, deliberately: the kit
/// splits it out so the greeting scrolls away with the content while the slim
/// bar stays. Every dashboard state carries it, so it is the first thing any
/// of them needs.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MxText(
          l10n.todayGreetingDate(now),
          role: MxTextRole.captionStrong,
          color: context.colors.textSecondary,
        ),
        const MxGap.s1(),
        // Kit: 2xl/extrabold with tight tracking — the same ramp the large app
        // bar used before the greeting was split out of it.
        MxText(_greeting(l10n), role: MxTextRole.display),
      ],
    );
  }
}
