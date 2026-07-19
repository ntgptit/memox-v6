import 'dart:convert';

import 'package:memox_v6/core/errors/app_failure.dart';

/// Shared primitive conversions for row → domain mappers (WBS 4.5).
/// Every helper either converts cleanly or raises a typed
/// [DataCorruptionFailure]; nothing guesses silently.

/// Stored UTC epoch milliseconds → UTC [DateTime].
DateTime utcDateTime(int epochMilliseconds) =>
    DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: true);

/// Nullable variant of [utcDateTime].
DateTime? utcDateTimeOrNull(int? epochMilliseconds) =>
    epochMilliseconds == null ? null : utcDateTime(epochMilliseconds);

/// Stored 0/1 flag → bool. The schema CHECKs the range, but a mapper
/// never trusts silently: anything else is corruption.
bool storedBool(int value, {required String entity, required String field}) {
  if (value == 0) return false;
  if (value == 1) return true;
  throw DataCorruptionFailure(entity: entity, field: field, value: value);
}

/// Stored JSON array of strings → `List<String>`.
List<String> storedStringList(
  String json, {
  required String entity,
  required String field,
}) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw DataCorruptionFailure(entity: entity, field: field, value: json);
    }
    return decoded.map((element) => element as String).toList();
  } on DataCorruptionFailure {
    rethrow;
  } on Object catch (error, stackTrace) {
    throw DataCorruptionFailure(
      entity: entity,
      field: field,
      value: json,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

/// Stored JSON payload → decoded object, or null when the payload is
/// invalid (the preference read-fallback contract).
Object? tryDecodeJson(String json) {
  try {
    return jsonDecode(json);
  } on FormatException {
    return null;
  }
}
