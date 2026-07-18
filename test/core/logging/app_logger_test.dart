import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/logging/app_logger.dart';
import 'package:memox_v6/core/logging/redaction.dart';

void main() {
  late List<LogRecord> records;
  late LogSink previousSink;

  setUp(() {
    records = <LogRecord>[];
    previousSink = AppLogger.sink;
    AppLogger.sink = records.add;
  });

  tearDown(() {
    AppLogger.sink = previousSink;
  });

  test('emits records at every level', () {
    AppLogger.debug('d');
    AppLogger.info('i');
    AppLogger.warning('w');
    AppLogger.error('e');
    AppLogger.fatal('f');

    expect(records.map((record) => record.level), <LogLevel>[
      LogLevel.debug,
      LogLevel.info,
      LogLevel.warning,
      LogLevel.error,
      LogLevel.fatal,
    ]);
  });

  test('redacts message and context values', () {
    AppLogger.error(
      'sync failed with token=abc123',
      context: <String, String>{'auth': 'Bearer abc.def'},
    );

    final record = records.single;
    expect(record.message, 'sync failed with token=$redactedPlaceholder');
    expect(record.context['auth'], redactedPlaceholder);
  });

  test('preserves error and stack on the record', () {
    final error = StateError('boom');
    final stackTrace = StackTrace.current;

    AppLogger.fatal('fatal', error: error, stackTrace: stackTrace);

    expect(records.single.error, same(error));
    expect(records.single.stackTrace, same(stackTrace));
  });
}
