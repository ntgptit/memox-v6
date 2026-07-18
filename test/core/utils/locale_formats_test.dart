import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memox_v6/core/utils/locale_formats.dart';

void main() {
  const english = Locale('en');
  const vietnamese = Locale('vi');

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('vi');
  });

  test('integers group per locale', () {
    expect(formatInteger(1234567, english), '1,234,567');
    expect(formatInteger(1234567, vietnamese), '1.234.567');
  });

  test('decimals use the locale separator', () {
    expect(formatDecimal(1234.5, english), '1,234.5');
    expect(formatDecimal(1234.5, vietnamese), '1.234,5');
  });

  test('percent localizes symbol placement', () {
    expect(formatPercent(0.42, english), '42%');
    expect(formatPercent(0.42, vietnamese), contains('42'));
  });

  test('medium date uses locale month words', () {
    final date = DateTime(2026, 7, 19);

    expect(formatMediumDate(date, english), 'Jul 19, 2026');
    expect(formatMediumDate(date, vietnamese), contains('19'));
    expect(
      formatMediumDate(date, english),
      isNot(equals(formatMediumDate(date, vietnamese))),
    );
  });
}
