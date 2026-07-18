import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _linear(color.r) +
    0.7152 * _linear(color.g) +
    0.0722 * _linear(color.b);

/// WCAG 2.x contrast ratio between two opaque colors.
double contrastRatio(Color foreground, Color background) {
  final lighter = math.max(_luminance(foreground), _luminance(background));
  final darker = math.min(_luminance(foreground), _luminance(background));
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  for (final (themeName, tokens) in <(String, AppColorTokens)>[
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$themeName theme contrast evidence (KIT-08)', () {
      void expectAa(Color fg, Color bg, String pair) {
        expect(
          contrastRatio(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$pair must meet normal-text AA (>=4.5:1) in $themeName',
        );
      }

      void expectUi(Color fg, Color bg, String pair) {
        expect(
          contrastRatio(fg, bg),
          greaterThanOrEqualTo(3.0),
          reason:
              '$pair must meet UI/large-text contrast (>=3:1) in $themeName',
        );
      }

      test('body and secondary text on canvas and surfaces', () {
        expectAa(tokens.text, tokens.bg, 'text/bg');
        expectAa(tokens.text, tokens.surface, 'text/surface');
        expectAa(tokens.textSecondary, tokens.bg, 'text-secondary/bg');
        // The kit gates tertiary as normal-text AA (colors.css comment).
        expectAa(tokens.textTertiary, tokens.bg, 'text-tertiary/bg');
      });

      test('on-color foregrounds on their fills', () {
        expectAa(tokens.onPrimary, tokens.primary, 'on-primary/primary');
        expectAa(tokens.onAccent, tokens.accent, 'on-accent/accent');
        expectAa(tokens.onSuccess, tokens.success, 'on-success/success');
        expectAa(tokens.onWarning, tokens.warning, 'on-warning/warning');
        expectAa(tokens.onError, tokens.error, 'on-error/error');
        expectAa(tokens.onInfo, tokens.info, 'on-info/info');
      });

      test('snackbar text meets AA and accents meet 3:1 on opaque grounds', () {
        expectAa(
          tokens.snackbarSuccessText,
          tokens.snackbarSuccessBg,
          'snackbar-success text/bg',
        );
        expectAa(
          tokens.snackbarErrorText,
          tokens.snackbarErrorBg,
          'snackbar-error text/bg',
        );
        expectAa(
          tokens.snackbarInfoText,
          tokens.snackbarInfoBg,
          'snackbar-info text/bg',
        );
        expectAa(
          tokens.snackbarNeutralText,
          tokens.snackbarNeutralBg,
          'snackbar-neutral text/bg',
        );
        expectUi(
          tokens.snackbarSuccessAccent,
          tokens.snackbarSuccessBg,
          'snackbar-success accent/bg',
        );
        expectUi(
          tokens.snackbarErrorAccent,
          tokens.snackbarErrorBg,
          'snackbar-error accent/bg',
        );
        expectUi(
          tokens.snackbarInfoAccent,
          tokens.snackbarInfoBg,
          'snackbar-info accent/bg',
        );
      });

      test('focus ring is visible against the canvas', () {
        expectUi(tokens.focusRing, tokens.bg, 'focus-ring/bg');
      });
    });
  }
}
