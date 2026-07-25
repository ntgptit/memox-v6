import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_motion.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// The one on/off toggle (kit `MxSwitch`).
///
/// Purpose:
/// A binary setting that applies immediately — a sunken track that fills with
/// primary when on, and a thumb that slides and grows as it crosses.
///
/// Use when:
/// A setting whose two states are both valid and reversible: hide during
/// study, reminders on/off, a preference in Settings.
///
/// Do not use when:
/// A choice needing confirmation or a destructive consequence (`MxButton` +
/// `MxConfirmDialog`), a filter (`MxChip`), or 2–3 mutually exclusive views
/// (`MxSegmentedControl`).
///
/// Category:
/// input
///
/// Public API:
/// - value: on/off.
/// - onChanged: receives the requested value; null renders the disabled track.
/// - semanticLabel: names the setting for assistive tech.
///
/// States:
/// off (sunken track, mid border, tertiary thumb), on (primary track, no
/// border, larger on-primary thumb), disabled (dimmed, inert), plus the
/// pressed and focus ring [MxTappable] draws.
class MxSwitch extends StatelessWidget {
  const MxSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;

  /// Null disables the control, matching the kit's `disabled` switch: dimmed
  /// and inert rather than removed, so the setting stays legible while a save
  /// is in flight.
  final ValueChanged<bool>? onChanged;

  /// Required rather than optional: a bare track has no visible text, so a
  /// switch without a name is unusable with a screen reader. The kit's
  /// `ariaLabel` is likewise not optional in practice.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onChanged = this.onChanged;
    final enabled = onChanged != null;

    // Kit `.switch`: the track is a sunken pill carrying an inset mid-stroke
    // border; `.switch--on` swaps in primary and drops the border entirely.
    final track = AnimatedContainer(
      duration: AppMotion.durationFast,
      curve: AppMotion.easeStandard,
      width: AppComponentDimensions.switchWidth,
      height: AppComponentDimensions.switchHeight,
      decoration: BoxDecoration(
        color: value ? colors.primary : colors.surfaceSunken,
        borderRadius: AppBorderRadii.full,
        border: value
            ? null
            : Border.all(color: colors.border, width: AppStrokes.mid),
      ),
      child: Stack(
        children: <Widget>[
          // The thumb both slides and resizes: the kit animates `width`,
          // `height` and `inset-inline-start` alongside the translate, so the
          // on-thumb is 24 at inset 2 where the off-thumb is 22 at inset 4.
          // Animating position through `AnimatedPositioned` rather than a
          // transform keeps the two in step under one curve.
          AnimatedPositioned(
            duration: AppMotion.durationFast,
            curve: AppMotion.easeStandard,
            top: value
                ? AppComponentDimensions.switchThumbInsetOn
                : AppComponentDimensions.switchThumbInset,
            left: value
                ? AppComponentDimensions.switchThumbInsetOn +
                      AppComponentDimensions.switchThumbTravel
                : AppComponentDimensions.switchThumbInset,
            child: AnimatedContainer(
              duration: AppMotion.durationFast,
              curve: AppMotion.easeStandard,
              width: value
                  ? AppComponentDimensions.switchThumbOn
                  : AppComponentDimensions.switchThumb,
              height: value
                  ? AppComponentDimensions.switchThumbOn
                  : AppComponentDimensions.switchThumb,
              decoration: BoxDecoration(
                color: value ? colors.onPrimary : colors.textTertiary,
                borderRadius: AppBorderRadii.full,
              ),
            ),
          ),
        ],
      ),
    );

    final control = MxTappable(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: AppBorderRadii.full,
      child: track,
    );

    return Semantics(
      // `toggled` is what makes a screen reader announce "on"/"off" instead of
      // reading a nameless button. `MxTappable`'s own label would give the
      // name without the state, which is half the control.
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      container: true,
      // Kit `.switch--disabled` dims the whole control. Only the disabled
      // branch is wrapped: an `Opacity` at full strength is a composited layer
      // that buys nothing.
      child: enabled
          ? control
          : Opacity(opacity: AppOpacities.opacityDisabled, child: control),
    );
  }
}
