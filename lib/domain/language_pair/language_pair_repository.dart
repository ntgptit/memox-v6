import 'package:memox_v6/domain/language_pair/language_pair.dart';

/// Language Pair repository port (WBS 4.6A).
///
/// Conflict contract: creating a pair whose normalized key already
/// exists raises a `ConflictFailure(code: 'duplicate')`. Lookups return
/// null for absent ids — flows own their not-found recovery.
abstract interface class LanguagePairRepository {
  Future<void> createPair(LanguagePair pair);

  Future<LanguagePair?> findById(String id);

  Future<LanguagePair?> findByNormalizedKey(String normalizedPairKey);

  Stream<List<LanguagePair>> watchAll();
}
