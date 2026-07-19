/// Versioned preference read model (WBS 4.5). The decoded value is the
/// parsed JSON payload; invalid payloads never construct an entry —
/// readers fall back to their defaults instead.
class PreferenceEntry {
  const PreferenceEntry({
    required this.key,
    required this.value,
    required this.schemaVersion,
    required this.updatedAt,
  });

  final String key;
  final Object? value;
  final int schemaVersion;
  final DateTime updatedAt;
}
