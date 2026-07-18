import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

import '../support/l10n_fixtures.dart';
import '../support/localized_app.dart';

void main() {
  test('delegate loads English with plural resolution', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(l10n.cardCountLabel(0), 'No cards');
    expect(l10n.cardCountLabel(1), '1 card');
    expect(l10n.cardCountLabel(5), '5 cards');
  });

  test('delegate loads Vietnamese with plural resolution', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('vi'));

    expect(l10n.cardCountLabel(0), '0 thẻ');
    expect(l10n.cardCountLabel(1), '1 thẻ');
    expect(l10n.cardCountLabel(5), '5 thẻ');
  });

  testWidgets('localized tree renders under RTL direction (RTL-ready)', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: Center(child: Text(expansionFixtureText))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(expansionFixtureText), findsOneWidget);
  });

  testWidgets('CJK and Vietnamese fixture content renders', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        const Scaffold(
          body: Column(
            children: <Widget>[
              Text(cjkFixtureText),
              Text(vietnameseFixtureText),
            ],
          ),
        ),
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(cjkFixtureText), findsOneWidget);
    expect(find.text(vietnameseFixtureText), findsOneWidget);
  });
}
