import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_elevations.dart';
import 'package:memox_v6/core/theme/tokens/app_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';

const String _tokensDir = 'docs/design/MemoX Design System_v4/tokens';

/// Raw declarations (name -> value) of one CSS file, comments stripped,
/// wrapped declarations joined.
Map<String, String> _declarations(String fileName) {
  var content = File('$_tokensDir/$fileName').readAsStringSync();
  content = content.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  content = content.replaceAll(RegExp(r'\s*\n\s*'), ' ');
  final declarations = <String, String>{};
  for (final match in RegExp(
    r'(--memox-[a-z0-9-]+)\s*:\s*([^;]+);',
  ).allMatches(content)) {
    // Later duplicates (dark blocks) intentionally overwrite; theme-specific
    // handling below re-parses where needed.
    declarations[match.group(1)!] = match.group(2)!.trim();
  }
  return declarations;
}

/// Numeric px/unitless declarations resolved against [aliases].
Map<String, double> _numeric(
  Map<String, String> declarations, {
  Map<String, String> overrides = const <String, String>{},
}) {
  final merged = <String, String>{...declarations, ...overrides};
  double? parse(String value, [int depth = 0]) {
    final alias = RegExp(r'^var\((--memox-[a-z0-9-]+)\)$').firstMatch(value);
    if (alias != null && depth < 5) {
      return parse(merged[alias.group(1)!] ?? '', depth + 1);
    }
    final number = RegExp(r'^(-?[0-9.]+)(px)?$').firstMatch(value);
    return number == null ? null : double.parse(number.group(1)!);
  }

  return <String, double>{
    for (final entry in merged.entries)
      if (parse(entry.value) != null) entry.key: parse(entry.value)!,
  };
}

void main() {
  test('spacing tokens match the kit exactly', () {
    final css = _declarations('spacing.css');
    final numeric = _numeric(
      css,
      // Safe-area tokens are max(env(...), <min>) expressions; the Dart layer
      // owns the kit-rendered minimums. Pin the expressions, then compare the
      // minimum values.
      overrides: <String, String>{
        '--memox-safe-area-top': '24px',
        '--memox-safe-area-bottom': '4px',
      },
    );

    expect(
      css['--memox-safe-area-top'],
      'max(env(safe-area-inset-top, 0px), 24px)',
    );
    expect(
      css['--memox-safe-area-bottom'],
      'max(env(safe-area-inset-bottom, 0px), var(--memox-comp-nav-safe-pad))',
    );
    expect(AppSpacing.byToken, numeric);
  });

  test('size tokens match the kit exactly', () {
    expect(AppSizes.byToken, _numeric(_declarations('size.css')));
  });

  test('radius tokens match the kit exactly', () {
    expect(AppRadii.byToken, _numeric(_declarations('radius.css')));
  });

  test('stroke tokens match the kit exactly', () {
    expect(AppStrokes.byToken, _numeric(_declarations('stroke.css')));
  });

  test('component dimension tokens match the kit exactly', () {
    expect(
      AppComponentDimensions.byToken,
      _numeric(_declarations('component.css')),
    );
  });

  group('elevation tokens', () {
    // Pinned raw kit strings: any elevation.css change fails here until
    // app_elevations.dart is updated in the same reviewed change.
    const pinnedLight = <String, String>{
      '--memox-shadow-sm':
          '0 2px 3px rgba(120, 112, 158, 0.18), 0 1px 1px rgba(120, 112, 158, 0.3)',
      '--memox-shadow-card':
          '0 9px 16px rgba(120, 112, 158, 0.18), 0 2px 2px rgba(120, 112, 158, 0.28)',
      '--memox-shadow-lg':
          '0 18px 40px rgba(75, 58, 140, 0.18), 0 4px 8px rgba(120, 112, 158, 0.24)',
      '--memox-shadow-fab': '0 8px 18px rgba(75, 58, 140, 0.38)',
      '--memox-shadow-nav': '0 -2px 14px rgba(120, 112, 158, 0.2)',
      '--memox-ring-focus': '0 0 0 3px var(--memox-focus-ring)',
    };
    const pinnedDark = <String, String>{
      '--memox-shadow-sm': '0 0 0 1px rgba(255, 255, 255, 0.09)',
      '--memox-shadow-card':
          '0 2px 8px rgba(0, 0, 0, 0.45), 0 0 0 1px rgba(255, 255, 255, 0.08)',
      '--memox-shadow-lg':
          '0 20px 48px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(255, 255, 255, 0.08)',
      '--memox-shadow-fab': '0 6px 16px rgba(0, 0, 0, 0.5)',
      '--memox-shadow-nav':
          '0 -2px 16px rgba(0, 0, 0, 0.55), 0 -1px 0 rgba(255, 255, 255, 0.06)',
      '--memox-ring-focus': '0 0 0 3px var(--memox-focus-ring)',
    };

    Map<String, String> themeDeclarations(String selector) {
      var content = File(
        '$_tokensDir/elevation.css',
      ).readAsStringSync().replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      final blocks = content.split(RegExp(r'\}'));
      final declarations = <String, String>{};
      for (final block in blocks) {
        if (!block.contains(selector)) continue;
        final body = block
            .substring(block.indexOf('{') + 1)
            .replaceAll(RegExp(r'\s*\n\s*'), ' ');
        for (final match in RegExp(
          r'(--memox-[a-z0-9-]+)\s*:\s*([^;]+);',
        ).allMatches(body)) {
          declarations[match.group(1)!] = match.group(2)!.trim();
        }
      }
      return declarations;
    }

    test('raw kit strings are unchanged (drift tripwire)', () {
      expect(themeDeclarations("[data-theme='light']"), pinnedLight);
      expect(themeDeclarations("[data-theme='dark']"), pinnedDark);
    });

    test('Dart shadow structure matches the pinned kit values', () {
      // Light: layered soft casts.
      expect(AppElevations.light.shadowSm, hasLength(2));
      expect(AppElevations.light.shadowCard, hasLength(2));
      expect(AppElevations.light.shadowLg, hasLength(2));
      expect(AppElevations.light.shadowFab, hasLength(1));
      expect(AppElevations.light.shadowNav, hasLength(1));
      // Dark: hairline ring + ambient.
      expect(AppElevations.dark.shadowSm.single.spreadRadius, 1);
      expect(AppElevations.dark.shadowCard, hasLength(2));
      expect(AppElevations.dark.shadowNav, hasLength(2));
    });

    test('focus ring composes stroke-focus width and the theme ring color', () {
      expect(AppElevations.light.ringFocus.single.spreadRadius, 3);
      expect(
        AppElevations.light.ringFocus.single.color,
        AppColors.light.focusRing,
      );
      expect(
        AppElevations.dark.ringFocus.single.color,
        AppColors.dark.focusRing,
      );
    });
  });
}
