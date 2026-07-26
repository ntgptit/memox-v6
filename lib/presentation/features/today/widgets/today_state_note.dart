import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/study_goal/daily_progress_status.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_note.dart';

/// The dashboard's three streak notes (kit `dashboard--goal-met`,
/// `dashboard--streak-reset`, `dashboard--not-studied`).
enum TodayNoteKind { goalMet, streakReset, notStudied }

/// Which note today's standing calls for, or null when it calls for none.
///
/// A function rather than three conditions spread through the tree, so the one
/// thing that matters about them — that at most one can ever apply — is stated
/// where it can be read and tested.
///
/// They are exclusive by construction, not by the order below:
/// - a met goal means a qualifying session finalized today, so today is a
///   qualified day: the streak is at least 1 and cannot read as reset, and
///   `studiedToday` is true so the nudge cannot apply;
/// - a reset streak is zero and the nudge needs a streak to keep.
///
/// The kit's own states are exclusive too, which is why it renders them as
/// three separate screens rather than a stack.
TodayNoteKind? todayNoteFor(DailyProgressStatus status) {
  if (status.isMet) return TodayNoteKind.goalMet;
  if (status.hasStreakHistory && status.streakDays == 0) {
    return TodayNoteKind.streakReset;
  }
  if (status.streakDays > 0 && !status.studiedToday) {
    return TodayNoteKind.notStudied;
  }
  return null;
}

/// Renders a [TodayNoteKind] as the kit's tinted note.
class TodayStateNote extends StatelessWidget {
  const TodayStateNote({super.key, required this.kind});

  final TodayNoteKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The kit's met copy ends "Streak +1" — not written here, because in this
    // model the goal does not grant the streak day: one qualified card records
    // it (`record-streak-day.md` §6), long before the target is reached. The
    // increment would credit the goal for something the day's first card
    // already did.
    final (tone, icon, text) = switch (kind) {
      TodayNoteKind.goalMet => (
        MxNoteTone.success,
        Symbols.celebration_rounded,
        l10n.todayNoteGoalMet,
      ),
      TodayNoteKind.streakReset => (
        MxNoteTone.warning,
        Symbols.local_fire_department_rounded,
        l10n.todayNoteStreakReset,
      ),
      TodayNoteKind.notStudied => (
        MxNoteTone.primary,
        Symbols.bolt_rounded,
        l10n.todayNoteNotStudied,
      ),
    };
    return MxNote(tone: tone, icon: icon, text: text);
  }
}
