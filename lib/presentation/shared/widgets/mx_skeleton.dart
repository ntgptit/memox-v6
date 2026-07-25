import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_motion.dart';

/// The one loading placeholder (kit `Skeleton`, `.mxg-skel`).
///
/// Purpose:
/// Holds the shape of content that has not arrived yet, so a list or a
/// card keeps its layout instead of collapsing and reflowing when the
/// data lands.
///
/// Use when:
/// A surface is loading its first data and the final layout is known —
/// list rows, avatars, a filter row. For work with a known duration or a
/// determinate fraction use `MxProgress`; for a surface that loaded and
/// has nothing to show use `MxEmptyState`.
///
/// Category:
/// feedback
///
/// Public API:
/// - width / height: the placeholder box; width defaults to the full
///   available width, matching the kit's `w = '100%'`.
/// - borderRadius: defaults to the pill (see below).
/// - `MxSkeleton.circle(size)`: the kit's `r={999}` avatar placeholder.
///
/// States:
/// pulsing, static (reduced motion).
///
/// Kit fidelity:
/// The kit animates `opacity .5 ↔ 1` over `--memox-duration-pulse`
/// (1300ms) on `--memox-surface-sunken`, looping forever.
///
/// The kit's `Skeleton` defaults to a raw `r = 8`, which is not one of
/// the `--memox-radius-*` tokens, so it is not reproduced literally —
/// inventing a token to hold it would break the frozen token contract.
/// Every kit usage of that default renders at `h ≤ 16`, where `8 ≥ h/2`
/// makes the box fully rounded anyway, so the pill token is pixel-identical
/// wherever the kit actually relies on it. A caller that needs a squarer
/// corner passes [borderRadius] explicitly.
class MxSkeleton extends StatefulWidget {
  const MxSkeleton({
    super.key,
    this.width,
    this.height = _defaultHeight,
    this.borderRadius = AppBorderRadii.pill,
  });

  /// The kit's `<Skeleton w={n} h={n} r={999} />` avatar placeholder.
  const MxSkeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = AppBorderRadii.full;

  /// `null` fills the available width — the kit's `w = '100%'`.
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  /// Kit `Skeleton` default `h = 16`.
  static const double _defaultHeight = 16;

  @override
  State<MxSkeleton> createState() => _MxSkeletonState();
}

class _MxSkeletonState extends State<MxSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // The kit keyframe runs .5 → 1 → .5 across one `duration-pulse`
    // period, so a reversing controller covers half of it per pass.
    duration: AppMotion.durationPulse ~/ 2,
  );

  late final Animation<double> _opacity = Tween<double>(
    begin: _restingOpacity,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  /// Kit `@keyframes mxg-pulse` trough.
  static const double _restingOpacity = 0.5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the loop in step with the current motion preference, which can
  /// change while the placeholder is on screen.
  void _syncPulse({required bool reduceMotion}) {
    if (reduceMotion) {
      _controller.stop();
      return;
    }
    if (_controller.isAnimating) return;
    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    // KIT-04-05 / KIT-38-06: reduced motion neutralizes every looping
    // animation. The kit caps the iteration count rather than dropping the
    // animation, so the box settles on the `mxg-pulse` 0%/100% keyframe —
    // the trough, not full opacity. Measured off the kit's own loading
    // shots, whose skeletons sit at `surface-sunken` over the card at
    // ~0.5 alpha: `subdeck-list--loading--light` reads (244, 242, 249) on
    // white, which is exactly that blend.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncPulse(reduceMotion: reduceMotion);

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceSunken,
        borderRadius: widget.borderRadius,
      ),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
      ),
    );

    // A placeholder carries no information: announcing it would read an
    // empty box to a screen reader. The loading surface announces itself.
    return ExcludeSemantics(
      child: reduceMotion
          ? Opacity(opacity: _restingOpacity, child: box)
          : FadeTransition(opacity: _opacity, child: box),
    );
  }
}
