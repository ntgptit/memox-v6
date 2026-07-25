import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';

import 'package:memox_v6/presentation/features/deck/widgets/deck_failure_states.dart';

/// The deck detail's failure surfaces are the kit's centred compositions,
/// not the default inline banner the async builder falls back to.
Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('a load failure is a centred retry, not a banner', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => DeckLoadErrorState(
            title: AppLocalizations.of(context).deckLoadErrorTitle,
            onRetry: () => retried += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Kit `subdeck-list--error`: cloud_off tile, title, body, Retry.
    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.byType(MxBanner), findsNothing);
    expect(find.text('Couldn’t load decks'), findsOneWidget);
    expect(
      find.text('Something went wrong. Check your connection and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('a missing deck offers only the way out', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) =>
              DeckNotFoundState(l10n: AppLocalizations.of(context)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Kit `subdeck-list--not-found`: folder_off tile with a single safe
    // action — the deck is gone, so nothing else on offer would work.
    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text('This deck no longer exists'), findsOneWidget);
    expect(find.text('Back to Library'), findsOneWidget);
    expect(
      tester
          .widgetList<MxIcon>(find.byType(MxIcon))
          .where((icon) => icon.icon == Symbols.folder_off_rounded)
          .length,
      1,
    );
  });
}
