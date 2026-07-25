import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_motion.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_skeleton.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  ),
);

BoxDecoration _decorationOf(WidgetTester tester) {
  return tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(MxSkeleton),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration
      as BoxDecoration;
}

double _opacityOf(WidgetTester tester) {
  return tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byType(MxSkeleton),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;
}

void main() {
  group('MxSkeleton', () {
    testWidgets('paints the kit surface-sunken fill on a pill', (tester) async {
      await tester.pumpWidget(
        _host(const SizedBox(width: 200, child: MxSkeleton())),
      );

      final decoration = _decorationOf(tester);
      expect(decoration.color, AppColors.light.surfaceSunken);
      expect(decoration.borderRadius, AppBorderRadii.pill);

      // Kit default `h = 16`; `w = '100%'` takes the parent's width.
      final size = tester.getSize(find.byType(MxSkeleton));
      expect(size.height, 16);
      expect(size.width, 200);
    });

    testWidgets('circle is square and fully rounded (kit r={999})', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MxSkeleton.circle(size: 40)));

      expect(_decorationOf(tester).borderRadius, AppBorderRadii.full);
      expect(tester.getSize(find.byType(MxSkeleton)), const Size(40, 40));
    });

    testWidgets('pulses between the kit .5 and 1 opacity bounds', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MxSkeleton()));

      // The trough of `@keyframes mxg-pulse`.
      expect(_opacityOf(tester), 0.5);

      // Half a pulse period later the animation is at its peak; the kit
      // keyframe puts opacity 1 at 50% of `--memox-duration-pulse`.
      await tester.pump(AppMotion.durationPulse ~/ 2);
      expect(_opacityOf(tester), 1);

      // ...and it reverses rather than restarting from the trough.
      await tester.pump(AppMotion.durationPulse ~/ 2);
      expect(_opacityOf(tester), 0.5);
    });

    testWidgets('reduced motion settles on the keyframe trough, not opaque', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const MxSkeleton(), disableAnimations: true),
      );

      // No FadeTransition at all: nothing is left ticking (KIT-04-05).
      expect(
        find.descendant(
          of: find.byType(MxSkeleton),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(_decorationOf(tester).color, AppColors.light.surfaceSunken);

      // The kit caps iterations rather than removing the animation, so the
      // box rests on the `mxg-pulse` 0%/100% keyframe. The parity harness
      // captures under reduced motion, and the kit's own loading shots show
      // the skeleton at this alpha — resting opaque would miss every shot.
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(MxSkeleton),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.5,
      );

      // A pending frame would fail this: the widget must be fully settled.
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('is invisible to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const MxSkeleton()));

      expect(
        find.descendant(
          of: find.byType(MxSkeleton),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
