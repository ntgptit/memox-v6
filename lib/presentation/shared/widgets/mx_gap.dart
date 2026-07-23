import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';

/// Fixed spacing helpers on the kit's 4px rhythm.
///
/// Purpose:
/// Puts token-true gaps between siblings so layout code never writes raw
/// `SizedBox` dimensions.
///
/// Use when:
/// Separating widgets inside rows/columns with a spacing-scale step.
///
/// Category:
/// utility
///
/// Public API:
/// - constructors: `s05` through `s12`, each a const square [SizedBox]
///   of the matching `AppSpacing` step.
class MxGap extends StatelessWidget {
  const MxGap._(this._size);

  const MxGap.s05() : this._(AppSpacing.space05);
  const MxGap.s1() : this._(AppSpacing.space1);
  const MxGap.s2() : this._(AppSpacing.space2);
  const MxGap.s3() : this._(AppSpacing.space3);
  const MxGap.s4() : this._(AppSpacing.space4);
  const MxGap.s5() : this._(AppSpacing.space5);
  const MxGap.s6() : this._(AppSpacing.space6);
  const MxGap.s7() : this._(AppSpacing.space7);
  const MxGap.s8() : this._(AppSpacing.space8);
  const MxGap.s9() : this._(AppSpacing.space9);
  const MxGap.s10() : this._(AppSpacing.space10);
  const MxGap.s11() : this._(AppSpacing.space11);
  const MxGap.s12() : this._(AppSpacing.space12);

  /// Raw spacing values for the rare layout that needs a token as a number
  /// (e.g. `Wrap.spacing`) rather than a gap widget — so features stay off
  /// the raw spacing tokens.
  static const double s2Value = AppSpacing.space2;

  final double _size;

  @override
  Widget build(BuildContext context) => SizedBox(width: _size, height: _size);
}
