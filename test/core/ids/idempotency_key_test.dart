import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/idempotency_key.dart';

void main() {
  test('same parts always build the same key', () {
    expect(
      buildIdempotencyKey(<String>['session', 'card-1', 'round-2']),
      buildIdempotencyKey(<String>['session', 'card-1', 'round-2']),
    );
  });

  test('distinct part lists never collide on naive joins', () {
    expect(
      buildIdempotencyKey(<String>['ab', 'c']),
      isNot(equals(buildIdempotencyKey(<String>['a', 'bc']))),
    );
    expect(
      buildIdempotencyKey(<String>['a|b']),
      isNot(equals(buildIdempotencyKey(<String>['a', 'b']))),
    );
  });

  test('rejects empty input', () {
    expect(() => buildIdempotencyKey(<String>[]), throwsArgumentError);
    expect(() => buildIdempotencyKey(<String>['ok', '']), throwsArgumentError);
  });
}
