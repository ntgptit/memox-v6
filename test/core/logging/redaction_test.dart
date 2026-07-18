import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/logging/redaction.dart';

void main() {
  test('masks secret-keyed assignments', () {
    expect(
      redactSensitive('password=hunter2 retry=3'),
      'password=$redactedPlaceholder retry=3',
    );
    expect(
      redactSensitive('token: abc.def.ghi'),
      'token: $redactedPlaceholder',
    );
    expect(
      redactSensitive('api_key=XYZ123, mode=fast'),
      'api_key=$redactedPlaceholder, mode=fast',
    );
    expect(redactSensitive('Session=deadbeef'), 'Session=$redactedPlaceholder');
  });

  test('masks bearer tokens', () {
    expect(
      redactSensitive('header Authorization: Bearer abc.DEF-123'),
      'header Authorization: $redactedPlaceholder',
    );
  });

  test('leaves ordinary text untouched', () {
    const input = 'Deck saved with 12 cards in 380ms';
    expect(redactSensitive(input), input);
  });
}
