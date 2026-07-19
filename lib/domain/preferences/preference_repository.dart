import 'package:memox_v6/domain/preferences/preference_entry.dart';

/// Preference repository port (WBS 4.6B).
///
/// Reads follow the schema-v1 invalid-fallback contract: a stored
/// payload that fails to decode reads as null and callers use their
/// defaults — corruption never propagates as a value.
abstract interface class PreferenceRepository {
  Future<void> save(
    String key, {
    required Object? value,
    required int schemaVersion,
    required DateTime updatedAt,
  });

  Future<PreferenceEntry?> read(String key);

  Stream<PreferenceEntry?> watch(String key);

  Future<void> remove(String key);
}
