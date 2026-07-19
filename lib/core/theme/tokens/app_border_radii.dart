// BorderRadius constants over the radius tokens (WBS 2.4/3.1).
//
// The token layer is the only place `BorderRadius`/`Radius` literals may be
// constructed (guard `flutter.no_hardcoded_radius`); widgets consume these
// named shapes.

import 'package:flutter/painting.dart';
import 'package:memox_v6/core/theme/tokens/app_radii.dart';

/// Named corner shapes for the radius role aliases and scale.
abstract final class AppBorderRadii {
  static const BorderRadius xs = BorderRadius.all(
    Radius.circular(AppRadii.radiusXs),
  );
  static const BorderRadius sm = BorderRadius.all(
    Radius.circular(AppRadii.radiusSm),
  );
  static const BorderRadius md = BorderRadius.all(
    Radius.circular(AppRadii.radiusMd),
  );
  static const BorderRadius lg = BorderRadius.all(
    Radius.circular(AppRadii.radiusLg),
  );
  static const BorderRadius xl = BorderRadius.all(
    Radius.circular(AppRadii.radiusXl),
  );
  static const BorderRadius xxl = BorderRadius.all(
    Radius.circular(AppRadii.radius2xl),
  );

  static const BorderRadius card = BorderRadius.all(
    Radius.circular(AppRadii.radiusCard),
  );
  static const BorderRadius tile = BorderRadius.all(
    Radius.circular(AppRadii.radiusTile),
  );
  static const BorderRadius control = BorderRadius.all(
    Radius.circular(AppRadii.radiusControl),
  );
  static const BorderRadius field = BorderRadius.all(
    Radius.circular(AppRadii.radiusField),
  );
  static const BorderRadius pill = BorderRadius.all(
    Radius.circular(AppRadii.radiusPill),
  );
  static const BorderRadius full = BorderRadius.all(
    Radius.circular(AppRadii.radiusFull),
  );

  /// Sheet top corners (kit `.sheet` top radius = 2xl).
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(AppRadii.radius2xl),
  );
}
