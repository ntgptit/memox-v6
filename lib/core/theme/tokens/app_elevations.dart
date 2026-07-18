// Elevation / shadow tokens (WBS 2.4) mapped from the design kit.
//
// Source: docs/design/MemoX Design System_v4/tokens/elevation.css —
// theme-dependent: soft violet-grey casts in light, crisp hairline ring +
// deep ambient in dark. `--memox-ring-focus` composes the theme's
// `--memox-focus-ring` color at stroke-focus width.
// Parity gate: test/core/theme/dimension_css_parity_test.dart pins the raw
// CSS shadow strings, so any kit change fails until this file is updated.

import 'package:flutter/painting.dart';

/// Shadow lists for one theme.
final class AppElevationTokens {
  const AppElevationTokens({
    required this.shadowSm,
    required this.shadowCard,
    required this.shadowLg,
    required this.shadowFab,
    required this.shadowNav,
    required this.ringFocus,
  });

  /// `--memox-shadow-sm`
  final List<BoxShadow> shadowSm;

  /// `--memox-shadow-card`
  final List<BoxShadow> shadowCard;

  /// `--memox-shadow-lg`
  final List<BoxShadow> shadowLg;

  /// `--memox-shadow-fab`
  final List<BoxShadow> shadowFab;

  /// `--memox-shadow-nav`
  final List<BoxShadow> shadowNav;

  /// `--memox-ring-focus` (focus-ring color at 3px spread)
  final List<BoxShadow> ringFocus;
}

/// Theme-dependent elevation tokens.
abstract final class AppElevations {
  static const AppElevationTokens light = AppElevationTokens(
    shadowSm: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 2),
        blurRadius: 3,
        color: Color.fromRGBO(120, 112, 158, 0.18),
      ),
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 1,
        color: Color.fromRGBO(120, 112, 158, 0.3),
      ),
    ],
    shadowCard: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 9),
        blurRadius: 16,
        color: Color.fromRGBO(120, 112, 158, 0.18),
      ),
      BoxShadow(
        offset: Offset(0, 2),
        blurRadius: 2,
        color: Color.fromRGBO(120, 112, 158, 0.28),
      ),
    ],
    shadowLg: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 18),
        blurRadius: 40,
        color: Color.fromRGBO(75, 58, 140, 0.18),
      ),
      BoxShadow(
        offset: Offset(0, 4),
        blurRadius: 8,
        color: Color.fromRGBO(120, 112, 158, 0.24),
      ),
    ],
    shadowFab: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 8),
        blurRadius: 18,
        color: Color.fromRGBO(75, 58, 140, 0.38),
      ),
    ],
    shadowNav: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, -2),
        blurRadius: 14,
        color: Color.fromRGBO(120, 112, 158, 0.2),
      ),
    ],
    ringFocus: <BoxShadow>[
      BoxShadow(spreadRadius: 3, color: Color(0xFF4B3A8C)),
    ],
  );

  static const AppElevationTokens dark = AppElevationTokens(
    shadowSm: <BoxShadow>[
      BoxShadow(spreadRadius: 1, color: Color.fromRGBO(255, 255, 255, 0.09)),
    ],
    shadowCard: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 2),
        blurRadius: 8,
        color: Color.fromRGBO(0, 0, 0, 0.45),
      ),
      BoxShadow(spreadRadius: 1, color: Color.fromRGBO(255, 255, 255, 0.08)),
    ],
    shadowLg: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 20),
        blurRadius: 48,
        color: Color.fromRGBO(0, 0, 0, 0.6),
      ),
      BoxShadow(spreadRadius: 1, color: Color.fromRGBO(255, 255, 255, 0.08)),
    ],
    shadowFab: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 6),
        blurRadius: 16,
        color: Color.fromRGBO(0, 0, 0, 0.5),
      ),
    ],
    shadowNav: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, -2),
        blurRadius: 16,
        color: Color.fromRGBO(0, 0, 0, 0.55),
      ),
      BoxShadow(
        offset: Offset(0, -1),
        color: Color.fromRGBO(255, 255, 255, 0.06),
      ),
    ],
    ringFocus: <BoxShadow>[
      BoxShadow(spreadRadius: 3, color: Color(0xFFB4AADD)),
    ],
  );
}
