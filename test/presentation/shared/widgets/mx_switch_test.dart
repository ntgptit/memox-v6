import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_switch.dart';

/// WBS 3.x shared widgets — the kit's core `MxSwitch`.
///
/// Three features reference it (`flashcard-editor`, `reminder`, `settings`)
/// and none could be built without it. The kit's contract is small but every
/// part of it carries meaning: the thumb *grows* as it crosses, and the
/// control reports a toggle state rather than a nameless button press.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('reports its name and toggle state to assistive tech', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MxSwitch(
          value: true,
          onChanged: (_) {},
          semanticLabel: 'Hide during study',
        ),
      ),
    );

    // Without `toggled` a screen reader announces a button with no state,
    // which tells the user nothing about the setting they are changing.
    expect(
      tester.getSemantics(find.byType(MxSwitch)),
      matchesSemantics(
        label: 'Hide during study',
        isToggled: true,
        hasToggledState: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('a tap requests the opposite value', (tester) async {
    bool? requested;
    await tester.pumpWidget(
      wrap(
        MxSwitch(
          value: false,
          onChanged: (next) => requested = next,
          semanticLabel: 'Hide during study',
        ),
      ),
    );

    await tester.tap(find.byType(MxSwitch));
    await tester.pumpAndSettle();

    // The switch is controlled: it asks for the new value and never flips
    // itself, so the owner stays the single source of truth.
    expect(requested, isTrue);
  });

  testWidgets('a null onChanged renders an inert control', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MxSwitch(
          value: false,
          onChanged: null,
          semanticLabel: 'Hide during study',
        ),
      ),
    );

    await tester.tap(find.byType(MxSwitch), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(Opacity), findsWidgets);
    expect(
      tester.getSemantics(find.byType(MxSwitch)),
      matchesSemantics(
        label: 'Hide during study',
        hasToggledState: true,
        hasEnabledState: true,
      ),
    );
  });

  // Kit `.switch--on .switch__thumb`: the thumb is 24 at inset 2 when on and
  // 22 at inset 4 when off. It is the one part of the control that is easy to
  // build as a plain slide, which would leave it the wrong size at rest.
  testWidgets('the thumb grows as it crosses', (tester) async {
    Future<Size> thumbSize({required bool value}) async {
      await tester.pumpWidget(
        wrap(
          MxSwitch(
            value: value,
            onChanged: (_) {},
            semanticLabel: 'Hide during study',
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(
        find
            .descendant(
              of: find.byType(MxSwitch),
              matching: find.byType(AnimatedContainer),
            )
            .last,
      );
    }

    expect(
      (await thumbSize(value: false)).width,
      AppComponentDimensions.switchThumb,
    );
    expect(
      (await thumbSize(value: true)).width,
      AppComponentDimensions.switchThumbOn,
    );
  });
}
