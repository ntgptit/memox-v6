import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/flashcard/card_text.dart';
import 'package:memox_v6/domain/preferences/preference_repository.dart';

/// Records and reads recent search queries (WBS 10.2;
/// `manage-recent-searches.md`).
///
/// Only a committed non-blank query is stored; the list is deduped by the
/// normalized query (keeping the most recent display text), ordered
/// newest-first and capped. No result content is ever stored — only the query.
class RecentSearchesUseCase {
  const RecentSearchesUseCase({
    required PreferenceRepository preferences,
    required AppClock clock,
  }) : _preferences = preferences,
       _clock = clock;

  final PreferenceRepository _preferences;
  final AppClock _clock;

  static const String preferenceKey = 'recentSearches';
  static const int _limit = 8;
  static const int _schemaVersion = 1;

  Future<List<String>> current() async {
    final entry = await _preferences.read(preferenceKey);
    final value = entry?.value;
    if (value is! List) return const <String>[];
    return value.whereType<String>().toList();
  }

  Future<void> record(String query) async {
    final display = StringUtils.trimmed(query);
    if (display.isEmpty) return;
    final normalized = normalizeCardTerm(display);
    final existing = await current();
    final deduped = existing
        .where((entry) => normalizeCardTerm(entry) != normalized)
        .toList();
    final next = <String>[display, ...deduped].take(_limit).toList();
    await _preferences.save(
      preferenceKey,
      value: next,
      schemaVersion: _schemaVersion,
      updatedAt: _clock.nowUtc(),
    );
  }

  Future<void> clear() => _preferences.remove(preferenceKey);
}
