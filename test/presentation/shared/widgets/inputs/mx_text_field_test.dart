import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    body: Padding(padding: EdgeInsets.zero, child: child),
  ),
);

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  testWidgets('bare field renders with body style and placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const MxTextField(placeholder: 'Enter a term')),
    );

    expect(find.text('Enter a term'), findsOneWidget);
    final field = _field(tester);
    expect(field.style?.color, AppColors.light.text);
    expect(field.cursorColor, AppColors.light.primary);
    expect(field.decoration?.hintStyle?.color, AppColors.light.textTertiary);
    expect(find.byType(Column), findsNothing);
  });

  testWidgets('typing forwards through onChanged', (tester) async {
    final values = <String>[];
    await tester.pumpWidget(_host(MxTextField(onChanged: values.add)));

    await tester.enterText(find.byType(TextField), 'kanji');
    expect(values, ['kanji']);
  });

  testWidgets('labelled group shows label, required star and helper', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const MxTextField(
          label: 'Email',
          requiredField: true,
          helper: 'We never share it.',
        ),
      ),
    );

    expect(find.textContaining('Email'), findsOneWidget);
    expect(find.textContaining('*'), findsOneWidget);
    expect(find.text('We never share it.'), findsOneWidget);
  });

  testWidgets('error hides helper, recolors text/caret and announces', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const MxTextField(
          label: 'Email',
          helper: 'We never share it.',
          errorText: 'Enter a valid email.',
        ),
      ),
    );

    expect(find.text('We never share it.'), findsNothing);
    expect(find.text('Enter a valid email.'), findsOneWidget);
    final field = _field(tester);
    expect(field.cursorColor, AppColors.light.error);
    expect(field.style?.color, AppColors.light.error);

    final errorSemantics = tester.getSemantics(
      find.text('Enter a valid email.'),
    );
    expect(
      errorSemantics.getSemanticsData().flagsCollection.isLiveRegion,
      isTrue,
    );
  });

  testWidgets('disabled dims the group and blocks editing', (tester) async {
    await tester.pumpWidget(
      _host(const MxTextField(label: 'Deck name', enabled: false)),
    );

    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.byType(TextField), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, AppOpacities.opacityDisabled);
    expect(_field(tester).enabled, isFalse);
    expect(_field(tester).style?.color, AppColors.light.textTertiary);
  });

  testWidgets('read-only keeps value visible without a caret', (tester) async {
    final controller = TextEditingController(text: 'locked');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(MxTextField(controller: controller, readOnly: true)),
    );

    expect(find.text('locked'), findsOneWidget);
    expect(_field(tester).readOnly, isTrue);
    expect(_field(tester).showCursor, isFalse);
    expect(_field(tester).style?.color, AppColors.light.textSecondary);
  });

  testWidgets('multiline expands lines and uses the multiline keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const MxTextField(multiline: true)));

    final field = _field(tester);
    expect(field.minLines, 2);
    expect(field.maxLines, 6);
    expect(field.keyboardType, TextInputType.multiline);
  });

  testWidgets('keyboard type passes through for bare fields', (tester) async {
    await tester.pumpWidget(
      _host(const MxTextField(keyboardType: TextInputType.emailAddress)),
    );

    expect(_field(tester).keyboardType, TextInputType.emailAddress);
  });

  testWidgets('focus shows the branded ring without layout shift', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const MxTextField(label: 'Term')));

    final before = tester.getSize(find.byType(TextField));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    DecoratedBox ringBox() => tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byType(TextField),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final border = (ringBox().decoration as BoxDecoration).border!;
    expect(border.top.color, AppColors.light.focusRing);
    expect(tester.getSize(find.byType(TextField)), before);
  });

  testWidgets('boxed field focuses with one ring on its own surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const MxTextField(label: 'Term', boxed: true)),
    );

    Container box() => tester.widget<Container>(
      find
          .ancestor(
            of: find.byType(TextField),
            matching: find.byType(Container),
          )
          .first,
    );

    // At rest: no visible ring over the surface.
    final resting = (box().foregroundDecoration! as BoxDecoration).border!;
    expect(resting.top.color.a, 0);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Focused: the ring paints on the box edge itself...
    final focused = (box().foregroundDecoration! as BoxDecoration).border!;
    expect(focused.top.color, AppColors.light.focusRing);

    // ...and exactly one focus-colored ring exists (no nested second
    // outline around the bare input).
    final rings = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          switch (widget.decoration) {
            final BoxDecoration decoration =>
              decoration.border?.top.color == AppColors.light.focusRing,
            _ => false,
          },
    );
    expect(rings, findsOneWidget);
  });
}
