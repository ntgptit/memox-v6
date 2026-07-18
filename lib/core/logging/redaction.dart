/// Replacement marker for redacted values.
const String redactedPlaceholder = '[REDACTED]';

final RegExp _sensitiveAssignment = RegExp(
  r'''(token|password|secret|cookie|session|credential|api[_-]?key)(["']?\s*[:=]\s*)([^\s,;}"']+)''',
  caseSensitive: false,
);

final RegExp _bearerToken = RegExp(r'[Bb]earer\s+[A-Za-z0-9\-._~+/=]+');

/// Masks secret-keyed `key: value` / `key=value` pairs and bearer tokens.
///
/// Applied to every log message and context value before a record reaches
/// any sink, so sensitive material never lands in local logs.
String redactSensitive(String input) {
  final withoutAssignments = input.replaceAllMapped(
    _sensitiveAssignment,
    (match) => '${match[1]}${match[2]}$redactedPlaceholder',
  );
  return withoutAssignments.replaceAll(_bearerToken, redactedPlaceholder);
}
