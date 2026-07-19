import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'preference_dao.g.dart';

/// Preference store DAO (WBS 4.4B).
///
/// All SQL lives in `queries/preferences.drift`. Values are versioned
/// JSON; invalid-payload fallback is mapper-layer read behavior.
@DriftAccessor(include: {'../queries/preferences.drift'})
class PreferenceDao extends DatabaseAccessor<AppDatabase>
    with _$PreferenceDaoMixin {
  PreferenceDao(super.attachedDatabase);
}
