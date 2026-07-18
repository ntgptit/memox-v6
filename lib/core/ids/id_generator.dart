import 'package:uuid/uuid.dart';

/// Injected ID source; every persisted primary key flows through this port
/// so tests can assert stable identities.
abstract interface class IdGenerator {
  /// A new globally unique, time-ordered identifier.
  String newId();
}

/// Production generator producing UUID v7 strings: time-ordered, so primary
/// keys stay index-friendly in SQLite.
final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  static const Uuid _uuid = Uuid();

  @override
  String newId() => _uuid.v7();
}
