import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';

const String _tokensDir = 'docs/design/MemoX Design System_v4/tokens';

Map<String, Map<String, String>> _parseBlocks(String path) {
  final blocks = <String, Map<String, String>>{};
  String? context;
  for (final rawLine in File(path).readAsLinesSync()) {
    final line = rawLine.replaceAll(RegExp(r'/\*.*?\*/'), '');
    final selector = RegExp(r'^\s*([^{}/]*\S)\s*\{').firstMatch(line);
    if (selector != null) context = selector.group(1)!.trim();
    final declaration = RegExp(
      r'^\s*(--memox-[a-z0-9-]+)\s*:\s*([^;]+);',
    ).firstMatch(line);
    if (declaration == null || context == null) continue;
    blocks.putIfAbsent(context, () => <String, String>{})[declaration.group(
      1,
    )!] = declaration
        .group(2)!
        .trim();
  }
  return blocks;
}

Map<String, String> _resolveTheme(
  Map<String, Map<String, String>> blocks,
  List<String> selectors,
) {
  final merged = <String, String>{};
  for (final selector in selectors) {
    merged.addAll(blocks[selector] ?? const <String, String>{});
  }
  String resolve(String value, [int depth = 0]) {
    final alias = RegExp(r'^var\((--memox-[a-z0-9-]+)\)$').firstMatch(value);
    if (alias == null) return value;
    if (depth > 5) fail('alias loop at $value');
    return resolve(merged[alias.group(1)!]!, depth + 1);
  }

  return merged.map((name, value) => MapEntry(name, resolve(value)));
}

Color _cssColor(String value) {
  final hex = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value);
  if (hex != null) {
    return Color(int.parse('FF${hex.group(1)!}', radix: 16));
  }
  final rgba = RegExp(
    r'^rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*\)$',
  ).firstMatch(value);
  if (rgba != null) {
    return Color.fromRGBO(
      int.parse(rgba.group(1)!),
      int.parse(rgba.group(2)!),
      int.parse(rgba.group(3)!),
      double.parse(rgba.group(4)!),
    );
  }
  fail('unsupported CSS color value: $value');
}

void main() {
  final colorBlocks = _parseBlocks('$_tokensDir/colors.css');
  final lightCss = _resolveTheme(colorBlocks, [
    "[data-theme='light']",
    ':root',
  ]);
  final darkCss = _resolveTheme(colorBlocks, [
    "[data-theme='light']",
    ':root',
    "[data-theme='dark']",
  ]);
  final paletteNames = colorBlocks[':root']!.keys.toSet();

  test('every themed CSS color token maps exactly in light and dark', () {
    final themedNames = lightCss.keys.where(
      (name) => !paletteNames.contains(name),
    );

    expect(themedNames, isNotEmpty);
    for (final name in themedNames) {
      expect(
        AppColors.light.byToken[name],
        _cssColor(lightCss[name]!),
        reason: '$name (light) drifted from colors.css',
      );
      expect(
        AppColors.dark.byToken[name],
        _cssColor(darkCss[name]!),
        reason: '$name (dark) drifted from colors.css',
      );
    }
    expect(AppColors.light.byToken.length, themedNames.length);
    expect(AppColors.dark.byToken.length, themedNames.length);
  });

  test('palette tokens map exactly and are theme-independent', () {
    expect(AppColors.paletteByToken.keys.toSet(), paletteNames);
    for (final name in paletteNames) {
      expect(
        AppColors.paletteByToken[name],
        _cssColor(lightCss[name]!),
        reason: '$name drifted from colors.css',
      );
    }
  });

  test('every opacity token maps exactly', () {
    final opacityCss = _parseBlocks('$_tokensDir/opacity.css')[':root']!;

    expect(AppOpacities.byToken.keys.toSet(), opacityCss.keys.toSet());
    for (final entry in opacityCss.entries) {
      expect(
        AppOpacities.byToken[entry.key],
        double.parse(entry.value),
        reason: '${entry.key} drifted from opacity.css',
      );
    }
  });
}
