import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'deck_dao.g.dart';

/// Deck aggregate DAO (WBS 4.4A).
///
/// All SQL lives in `queries/decks.drift`. Rename/move/delete run
/// through explicit statements there, so the 4.3 exclusivity and cycle
/// triggers guard every mutation this DAO can make.
@DriftAccessor(include: {'../queries/decks.drift'})
class DeckDao extends DatabaseAccessor<AppDatabase> with _$DeckDaoMixin {
  DeckDao(super.attachedDatabase);
}
