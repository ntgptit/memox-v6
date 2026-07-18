import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';

import '../../support/l10n_fixtures.dart';
import '../../support/localized_app.dart';

TextStyle _baseStyle() => const TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontFamilyFallback: AppTypography.fontFamilyFallback,
  fontSize: AppTypography.fontSizeBase,
  fontWeight: AppTypography.fontWeightRegular,
  height: AppTypography.lineHeightNormal,
);

TextStyle _cjkStyle() =>
    _baseStyle().copyWith(fontFamilyFallback: AppTypography.cjkFamilyFallback);

void main() {
  testWidgets('Vietnamese content renders with the primary family', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        Scaffold(body: Text(vietnameseFixtureText, style: _baseStyle())),
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.fontFamily, AppTypography.fontFamily);
  });

  testWidgets('CJK content renders through the explicit fallback stack', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(Scaffold(body: Text(cjkFixtureText, style: _cjkStyle()))),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.fontFamilyFallback, AppTypography.cjkFamilyFallback);
  });

  testWidgets('weight range of the bundled variable font renders', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: Column(
            children: <Widget>[
              for (final weight in AppTypography.weightByToken.values)
                Text('MemoX', style: _baseStyle().copyWith(fontWeight: weight)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MemoX'), findsNWidgets(5));
  });
}
