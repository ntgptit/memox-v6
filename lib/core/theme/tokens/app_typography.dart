// Typography tokens (WBS 2.3) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/typography.css
// Parity gate: test/core/theme/typography_css_parity_test.dart re-parses the
// CSS on every verifier run. Token NAMES are frozen (additive-only).

import 'dart:ui';

/// Primitive typography tokens: families, sizes, weights, line heights and
/// letter spacing. Semantic text roles compose these in WBS 2.6/2.7.
abstract final class AppTypography {
  /// `--memox-font-sans` primary family (bundled variable font).
  static const String fontFamily = 'Plus Jakarta Sans';

  /// Flutter-side fallback for [fontFamily] (platform sans stacks).
  static const List<String> fontFamilyFallback = <String>[
    'Segoe UI',
    'Roboto',
    'Helvetica',
    'Arial',
    'sans-serif',
  ];

  /// `--memox-font-mono` platform monospace stack (no bundled mono font).
  static const List<String> monoFamilyFallback = <String>[
    'Menlo',
    'Consolas',
    'monospace',
  ];

  /// `--memox-font-vietnamese`: the primary family fully covers Vietnamese
  /// diacritics, so the stack is the primary itself (kit contract).
  static const String vietnameseFamily = fontFamily;

  /// `--memox-font-cjk`: CJK is not covered by the primary family and must
  /// fall through to platform CJK families — explicit, never an undefined
  /// default (kit contract KIT-09-04/KIT-37-02).
  static const List<String> cjkFamilyFallback = <String>[
    'Noto Sans CJK KR',
    'Noto Sans KR',
    'Noto Sans CJK JP',
    'Noto Sans JP',
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'Malgun Gothic',
    'Yu Gothic',
    'Hiragino Sans',
    'Microsoft YaHei',
    'Apple SD Gothic Neo',
    'PingFang SC',
    'sans-serif',
  ];

  // --- font sizes (logical px) ---
  static const double fontSizeXs = 12;
  static const double fontSizeSm = 13;
  static const double fontSizeBase = 15;
  static const double fontSizeMd = 17;
  static const double fontSizeLg = 20;
  static const double fontSizeXl = 24;
  static const double fontSize2xl = 30;
  static const double fontSize3xl = 38;
  static const double fontSize4xl = 48;

  /// Sizes keyed by frozen CSS name (parity + tooling).
  static const Map<String, double> sizeByToken = <String, double>{
    '--memox-font-size-xs': fontSizeXs,
    '--memox-font-size-sm': fontSizeSm,
    '--memox-font-size-base': fontSizeBase,
    '--memox-font-size-md': fontSizeMd,
    '--memox-font-size-lg': fontSizeLg,
    '--memox-font-size-xl': fontSizeXl,
    '--memox-font-size-2xl': fontSize2xl,
    '--memox-font-size-3xl': fontSize3xl,
    '--memox-font-size-4xl': fontSize4xl,
  };

  // --- weights (variable wght axis 200-800 is bundled) ---
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtrabold = FontWeight.w800;

  /// Weights keyed by frozen CSS name.
  static const Map<String, FontWeight> weightByToken = <String, FontWeight>{
    '--memox-font-weight-regular': fontWeightRegular,
    '--memox-font-weight-medium': fontWeightMedium,
    '--memox-font-weight-semibold': fontWeightSemibold,
    '--memox-font-weight-bold': fontWeightBold,
    '--memox-font-weight-extrabold': fontWeightExtrabold,
  };

  // --- line heights (multipliers; map to TextStyle.height) ---
  static const double lineHeightNone = 1;
  static const double lineHeightTight = 1.15;
  static const double lineHeightSnug = 1.32;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.7;

  /// Line heights keyed by frozen CSS name.
  static const Map<String, double> lineHeightByToken = <String, double>{
    '--memox-line-height-none': lineHeightNone,
    '--memox-line-height-tight': lineHeightTight,
    '--memox-line-height-snug': lineHeightSnug,
    '--memox-line-height-normal': lineHeightNormal,
    '--memox-line-height-relaxed': lineHeightRelaxed,
  };

  // --- letter spacing (em; CSS is font-size-relative) ---
  static const double letterSpacingTightEm = -0.02;
  static const double letterSpacingNormalEm = 0;
  static const double letterSpacingWideEm = 0.04;
  static const double letterSpacingCapsEm = 0.08;

  /// Letter spacings (em) keyed by frozen CSS name.
  static const Map<String, double> letterSpacingEmByToken = <String, double>{
    '--memox-letter-spacing-tight': letterSpacingTightEm,
    '--memox-letter-spacing-normal': letterSpacingNormalEm,
    '--memox-letter-spacing-wide': letterSpacingWideEm,
    '--memox-letter-spacing-caps': letterSpacingCapsEm,
  };

  /// Converts an em-relative token to the logical-pixel `letterSpacing`
  /// Flutter expects for the given font size.
  static double letterSpacingFor(double em, double fontSize) => em * fontSize;
}
