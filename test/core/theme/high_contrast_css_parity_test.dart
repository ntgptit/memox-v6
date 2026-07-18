import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_high_contrast_overrides.dart';

const String _cssPath =
    'docs/design/MemoX Design System_v4/tokens/high-contrast.css';

Map<String, Map<String, String>> _blocks() {
  final content = File(
    _cssPath,
  ).readAsStringSync().replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  final blocks = <String, Map<String, String>>{};
  String? context;
  for (final line in content.split(RegExp(r'\r?\n'))) {
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

Color _cssColor(String value) {
  final hex = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value);
  if (hex != null) return Color(int.parse('FF${hex.group(1)!}', radix: 16));
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
  fail('unsupported color value: $value');
}

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _linear(color.r) +
    0.7152 * _linear(color.g) +
    0.0722 * _linear(color.b);

double _contrast(Color foreground, Color background) {
  final lighter = math.max(_luminance(foreground), _luminance(background));
  final darker = math.min(_luminance(foreground), _luminance(background));
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  final blocks = _blocks();

  test('light overrides match the kit exactly', () {
    final css = blocks["[data-hc='true']"]!;

    expect(
      AppHighContrastOverrides.light.byToken,
      css.map((name, value) => MapEntry(name, _cssColor(value))),
    );
  });

  test('dark overrides match the kit exactly', () {
    final css = blocks["[data-theme='dark'][data-hc='true']"]!;

    expect(
      AppHighContrastOverrides.dark.byToken,
      css.map((name, value) => MapEntry(name, _cssColor(value))),
    );
  });

  test('merge overrides only the six profile roles', () {
    final merged = applyHighContrast(
      AppColors.light,
      AppHighContrastOverrides.light,
    );

    expect(merged.textSecondary, AppHighContrastOverrides.light.textSecondary);
    expect(merged.focusRing, AppHighContrastOverrides.light.focusRing);
    // Everything else is untouched (additive profile).
    expect(merged.bg, AppColors.light.bg);
    expect(merged.primary, AppColors.light.primary);
    expect(merged.snackbarErrorBg, AppColors.light.snackbarErrorBg);
  });

  test('profile actually raises contrast over both bases', () {
    for (final (base, overrides) in [
      (AppColors.light, AppHighContrastOverrides.light),
      (AppColors.dark, AppHighContrastOverrides.dark),
    ]) {
      final merged = applyHighContrast(base, overrides);

      expect(
        _contrast(merged.textSecondary, merged.bg),
        greaterThan(_contrast(base.textSecondary, base.bg)),
      );
      expect(
        _contrast(merged.focusRing, merged.bg),
        greaterThanOrEqualTo(_contrast(base.focusRing, base.bg)),
      );
      expect(_contrast(merged.textSecondary, merged.bg), greaterThan(7.0));
    }
  });
}
