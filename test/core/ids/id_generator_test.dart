import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/ids/id_generator.dart';

final RegExp _uuidV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  test('produces UUID v7 formatted identifiers', () {
    expect(const UuidIdGenerator().newId(), matches(_uuidV7));
  });

  test('produces unique identifiers', () {
    const generator = UuidIdGenerator();

    final ids = <String>{for (var i = 0; i < 1000; i++) generator.newId()};

    expect(ids, hasLength(1000));
  });
}
