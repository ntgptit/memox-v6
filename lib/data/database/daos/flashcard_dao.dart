import 'package:drift/drift.dart';
import 'package:memox_v6/data/database/app_database.dart';

part 'flashcard_dao.g.dart';

/// Flashcard aggregate DAO (WBS 4.4A): cards plus their owned child
/// content (translations, tags, audio refs) per the business ownership
/// map.
///
/// All SQL lives in `queries/flashcards.drift`; listings exclude
/// soft-deleted cards and lifecycle transitions are explicit UPDATEs
/// guarded by the 4.3 triggers.
@DriftAccessor(include: {'../queries/flashcards.drift'})
class FlashcardDao extends DatabaseAccessor<AppDatabase>
    with _$FlashcardDaoMixin {
  FlashcardDao(super.attachedDatabase);
}
