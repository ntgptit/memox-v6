import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// WBS 16.3 — localization completeness: every user-facing key defined in the
/// English template must have a Vietnamese value and vice-versa, so no locale
/// ships a missing translation.
void main() {
  Set<String> messageKeys(String path) {
    final decoded = jsonDecode(File(path).readAsStringSync()) as Map;
    return decoded.keys
        .cast<String>()
        // Drop ARB tooling keys: the @@locale header and every @-metadata entry.
        .where((key) => !key.startsWith('@'))
        .toSet();
  }

  test('app_en.arb and app_vi.arb define the same message keys', () {
    final en = messageKeys('lib/l10n/app_en.arb');
    final vi = messageKeys('lib/l10n/app_vi.arb');

    final missingInVi = en.difference(vi).toList()..sort();
    final missingInEn = vi.difference(en).toList()..sort();

    expect(
      missingInVi,
      isEmpty,
      reason: 'Vietnamese is missing translations for: $missingInVi',
    );
    expect(
      missingInEn,
      isEmpty,
      reason: 'English is missing keys present in Vietnamese: $missingInEn',
    );
  });
}
