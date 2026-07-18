import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_search_field.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';

import '../../../../support/l10n_fixtures.dart';

/// Form-state stress coverage (WBS 3.3 child C): long text, CJK/IME
/// content, autofill wiring and 200% text scale.
void main() {
  Widget host(Widget child, {double textScale = 1.0}) => MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('single-line field survives expansion-length input at 320px', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 780);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const MxTextField(label: 'Term')));
    await tester.enterText(find.byType(TextField), expansionFixtureText);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(expansionFixtureText), findsOneWidget);
  });

  testWidgets('multiline field holds long CJK content', (tester) async {
    await tester.pumpWidget(host(const MxTextField(multiline: true)));
    await tester.enterText(
      find.byType(TextField),
      '$cjkFixtureText\n$vietnameseFixtureText',
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('日本語'), findsOneWidget);
  });

  testWidgets('autofill hints reach the platform text input', (tester) async {
    await tester.pumpWidget(
      host(
        const MxTextField(
          label: 'Email',
          autofillHints: [AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofillHints, const [AutofillHints.email]);
    expect(field.keyboardType, TextInputType.emailAddress);
  });

  testWidgets('labelled field and search field render at 200% text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 780);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxTextField(
              label: 'Email',
              helper: 'We never share it.',
              requiredField: true,
            ),
            MxSearchField(placeholder: 'Search decks', clearLabel: 'Clear'),
          ],
        ),
        textScale: 2.0,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Email'), findsOneWidget);
    expect(find.text('Search decks'), findsOneWidget);
  });
}
