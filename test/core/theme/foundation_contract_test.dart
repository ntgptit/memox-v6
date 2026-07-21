import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/extensions/app_colors_extension.dart';
import 'package:memox_v6/core/theme/extensions/app_elevations_extension.dart';
import 'package:memox_v6/core/theme/extensions/app_text_styles.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_motion.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';
import 'package:memox_v6/core/theme/tokens/app_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';

void main() {
  test('token coverage matches the 208-token manifest exactly', () {
    // 65 themed colors ×2 themes share names; palette 6; opacity 5;
    // typography 27; spacing 31; size 11; radius 13; stroke 5;
    // component 25; motion 10; icon 4; elevation 6 (structural, held as
    // BoxShadow lists). 65+6+5+27+31+11+13+5+25+10+4+6 = 208.
    expect(AppColors.light.byToken, hasLength(65));
    expect(AppColors.dark.byToken, hasLength(65));
    expect(AppColors.paletteByToken, hasLength(6));
    expect(AppOpacities.byToken, hasLength(5));
    expect(
      AppTypography.sizeByToken.length +
          AppTypography.weightByToken.length +
          AppTypography.lineHeightByToken.length +
          AppTypography.letterSpacingEmByToken.length +
          4, // family tokens: sans, mono, vietnamese, cjk
      27,
    );
    expect(AppSpacing.byToken, hasLength(31));
    expect(AppSizes.byToken, hasLength(11));
    expect(AppRadii.byToken, hasLength(13));
    expect(AppStrokes.byToken, hasLength(5));
    expect(AppComponentDimensions.byToken, hasLength(25));
    expect(
      AppMotion.durationMsByToken.length + AppMotion.easingByToken.length,
      10,
    );
    expect(AppIconSizes.byToken, hasLength(4));
  });

  test('both themes carry every foundation extension', () {
    for (final theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
      expect(theme.extension<AppColorsExtension>(), isNotNull);
      expect(theme.extension<AppElevationsExtension>(), isNotNull);
      expect(theme.extension<AppTextStyles>(), isNotNull);
      expect(theme.useMaterial3, isTrue);
    }
    expect(
      AppTheme.light().extension<AppColorsExtension>()!.tokens.bg,
      isNot(equals(AppTheme.dark().extension<AppColorsExtension>()!.tokens.bg)),
    );
  });

  test('no raw color values outside the token layer (source scan)', () {
    // Defense-in-depth double of the guard rule flutter.no_hardcoded_color:
    // fails inside `flutter test` too, not only at the repository gate.
    final offenders = <String>[];
    final rawColor = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)|\bColors\.[a-z]');
    final libDir = Directory('lib');
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll(r'\', '/');
      if (normalized.startsWith('lib/core/theme/')) continue;
      if (normalized.startsWith('lib/l10n/generated/')) continue;
      if (rawColor.hasMatch(entity.readAsStringSync())) {
        offenders.add(normalized);
      }
    }

    expect(offenders, isEmpty, reason: 'raw colors outside token layer');
  });

  test('no raw duration literals outside the token layer (source scan)', () {
    final offenders = <String>[];
    final rawDuration = RegExp(r'Duration\(\s*(milli|micro)?seconds:\s*\d');
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll(r'\', '/');
      if (normalized.startsWith('lib/core/theme/')) continue;
      if (normalized.startsWith('lib/l10n/generated/')) continue;
      if (rawDuration.hasMatch(entity.readAsStringSync())) {
        offenders.add(normalized);
      }
    }

    expect(offenders, isEmpty, reason: 'raw durations outside token layer');
  });
}
