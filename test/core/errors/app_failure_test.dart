import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/errors/app_failure.dart';

void main() {
  test('from returns the same instance for an existing AppFailure', () {
    final failure = UnexpectedFailure(
      cause: StateError('original'),
      stackTrace: StackTrace.current,
    );

    expect(AppFailure.from(failure, StackTrace.current), same(failure));
  });

  test('from wraps unknown errors preserving cause and stack', () {
    final cause = FormatException('bad input');
    final stackTrace = StackTrace.current;

    final failure = AppFailure.from(cause, stackTrace);

    expect(failure, isA<UnexpectedFailure>());
    expect(failure.cause, same(cause));
    expect(failure.stackTrace, same(stackTrace));
    expect(failure.toString(), contains('UnexpectedFailure'));
  });
}
