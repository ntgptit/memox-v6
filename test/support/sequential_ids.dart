import 'package:memox_v6/core/ids/id_generator.dart';

/// Deterministic [IdGenerator] for tests: `id-1`, `id-2`, … (WBS 1.10).
final class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator({String prefix = 'id'}) : _prefix = prefix;

  final String _prefix;
  int _next = 0;

  @override
  String newId() {
    _next += 1;
    return '$_prefix-$_next';
  }
}
