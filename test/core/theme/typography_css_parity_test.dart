import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';

const String _cssPath =
    'docs/design/MemoX Design System_v4/tokens/typography.css';

Map<String, String> _declarations() {
  final content = File(_cssPath).readAsStringSync();
  // Join wrapped declarations, then extract name/value pairs.
  final flattened = content.replaceAll(RegExp(r'\s*\n\s*'), ' ');
  final declarations = <String, String>{};
  for (final match in RegExp(
    r'(--memox-[a-z0-9-]+)\s*:\s*([^;]+);',
  ).allMatches(flattened)) {
    declarations[match.group(1)!] = match.group(2)!.trim();
  }
  return declarations;
}

void main() {
  final css = _declarations();

  test('font sizes match the kit exactly', () {
    final cssSizes = <String, double>{
      for (final entry in css.entries)
        if (entry.key.startsWith('--memox-font-size-'))
          entry.key: double.parse(
            RegExp(r'^(\d+)px$').firstMatch(entry.value)!.group(1)!,
          ),
    };

    expect(AppTypography.sizeByToken, cssSizes);
  });

  test('font weights match the kit exactly', () {
    final cssWeights = <String, int>{
      for (final entry in css.entries)
        if (entry.key.startsWith('--memox-font-weight-'))
          entry.key: int.parse(entry.value),
    };

    expect(
      AppTypography.weightByToken.map(
        (name, weight) => MapEntry(name, weight.value),
      ),
      cssWeights,
    );
  });

  test('line heights match the kit exactly', () {
    final cssLineHeights = <String, double>{
      for (final entry in css.entries)
        if (entry.key.startsWith('--memox-line-height-'))
          entry.key: double.parse(entry.value),
    };

    expect(AppTypography.lineHeightByToken, cssLineHeights);
  });

  test('letter spacings match the kit exactly (em)', () {
    final cssSpacings = <String, double>{
      for (final entry in css.entries)
        if (entry.key.startsWith('--memox-letter-spacing-'))
          entry.key: double.parse(entry.value.replaceAll('em', '')),
    };

    expect(AppTypography.letterSpacingEmByToken, cssSpacings);
  });

  test('family stacks preserve the kit contract', () {
    expect(css['--memox-font-sans'], contains("'Plus Jakarta Sans'"));
    expect(AppTypography.fontFamily, 'Plus Jakarta Sans');

    // Vietnamese stack is the primary itself (explicit coverage contract).
    expect(css['--memox-font-vietnamese'], 'var(--memox-font-sans)');
    expect(AppTypography.vietnameseFamily, AppTypography.fontFamily);

    // Every named CJK fallback family in CSS appears in the Flutter fallback
    // list, in the same order.
    final cssCjkFamilies = RegExp(r"'([^']+)'")
        .allMatches(css['--memox-font-cjk']!)
        .map((match) => match.group(1)!)
        .where((family) => family != 'Plus Jakarta Sans')
        .toList();
    expect(
      AppTypography.cjkFamilyFallback.where((family) => family != 'sans-serif'),
      cssCjkFamilies,
    );
  });

  test('letterSpacingFor converts em to logical pixels', () {
    expect(
      AppTypography.letterSpacingFor(
        AppTypography.letterSpacingTightEm,
        AppTypography.fontSizeLg,
      ),
      closeTo(-0.4, 1e-9),
    );
  });
}
