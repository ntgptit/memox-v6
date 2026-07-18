/// Builds a deterministic idempotency key from stable string parts.
///
/// Retrying an operation with the same parts always yields the same key,
/// while distinct part lists can never collide: each part is length-prefixed,
/// so `['ab', 'c']` and `['a', 'bc']` produce different keys.
String buildIdempotencyKey(List<String> parts) {
  if (parts.isEmpty) {
    throw ArgumentError.value(parts, 'parts', 'must not be empty');
  }
  final buffer = StringBuffer();
  for (final part in parts) {
    if (part.isEmpty) {
      throw ArgumentError.value(parts, 'parts', 'parts must not be empty');
    }
    buffer
      ..write(part.length)
      ..write(':')
      ..write(part)
      ..write('|');
  }
  return buffer.toString();
}
