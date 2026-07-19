import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'language_pair_dao.g.dart';

/// Language Pair aggregate DAO (WBS 4.4A).
///
/// All SQL lives in `queries/language_pairs.drift`; this shell only
/// exposes the typed methods drift generates from it.
@DriftAccessor(include: {'../queries/language_pairs.drift'})
class LanguagePairDao extends DatabaseAccessor<AppDatabase>
    with _$LanguagePairDaoMixin {
  LanguagePairDao(super.attachedDatabase);
}
