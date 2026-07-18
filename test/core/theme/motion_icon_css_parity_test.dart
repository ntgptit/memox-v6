import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_motion.dart';

const String _tokensDir = 'docs/design/MemoX Design System_v4/tokens';

Map<String, String> _declarations(String fileName) {
  var content = File('$_tokensDir/$fileName').readAsStringSync();
  content = content.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  final declarations = <String, String>{};
  for (final match in RegExp(
    r'(--memox-[a-z0-9-]+)\s*:\s*([^;]+);',
  ).allMatches(content)) {
    declarations[match.group(1)!] = match.group(2)!.trim();
  }
  return declarations;
}

void main() {
  final motionCss = _declarations('motion.css');

  test('duration tokens match the kit exactly (ms)', () {
    final cssDurations = <String, double>{
      for (final entry in motionCss.entries)
        if (entry.key.startsWith('--memox-duration-'))
          entry.key: double.parse(entry.value.replaceAll('ms', '')),
    };

    expect(AppMotion.durationMsByToken, cssDurations);
  });

  test('Duration constants agree with the token map', () {
    Duration toDuration(double ms) =>
        Duration(microseconds: (ms * 1000).round());

    expect(
      AppMotion.durationInstant,
      toDuration(AppMotion.durationMsByToken['--memox-duration-instant']!),
    );
    expect(
      AppMotion.durationFast,
      toDuration(AppMotion.durationMsByToken['--memox-duration-fast']!),
    );
    expect(
      AppMotion.durationBase,
      toDuration(AppMotion.durationMsByToken['--memox-duration-base']!),
    );
    expect(
      AppMotion.durationSlow,
      toDuration(AppMotion.durationMsByToken['--memox-duration-slow']!),
    );
    expect(
      AppMotion.durationNone,
      toDuration(AppMotion.durationMsByToken['--memox-duration-none']!),
    );
    expect(
      AppMotion.durationFlash,
      toDuration(AppMotion.durationMsByToken['--memox-duration-flash']!),
    );
    expect(
      AppMotion.durationPulse,
      toDuration(AppMotion.durationMsByToken['--memox-duration-pulse']!),
    );
    expect(AppMotion.durationNone, greaterThan(Duration.zero));
  });

  test('easing tokens match the kit cubic-beziers exactly', () {
    final cssEasings = <String, List<double>>{
      for (final entry in motionCss.entries)
        if (entry.key.startsWith('--memox-ease-'))
          entry.key: RegExp(r'-?[0-9.]+')
              .allMatches(entry.value)
              .map((match) => double.parse(match.group(0)!))
              .toList(),
    };

    expect(cssEasings.keys.toSet(), AppMotion.easingByToken.keys.toSet());
    for (final entry in AppMotion.easingByToken.entries) {
      final expected = cssEasings[entry.key]!;
      expect(
        <double>[entry.value.a, entry.value.b, entry.value.c, entry.value.d],
        expected,
        reason: '${entry.key} drifted from motion.css',
      );
    }
  });

  test('icon size tokens match the kit exactly', () {
    final iconCss = _declarations('icon-size.css');
    final cssSizes = <String, double>{
      for (final entry in iconCss.entries)
        entry.key: double.parse(entry.value.replaceAll('px', '')),
    };

    expect(AppIconSizes.byToken, cssSizes);
  });

  test('Material Symbols contract is the Rounded style', () {
    expect(AppIconSizes.iconFontFamily, 'Material Symbols Rounded');
  });
}
