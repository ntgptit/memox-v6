import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('MxProgress', () {
    testWidgets('determinate bar fills primary on the muted track', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const MxProgress(value: 0.64, semanticLabel: 'Importing deck')),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.64);
      expect(bar.color, AppColors.light.primary);
      expect(bar.backgroundColor, AppColors.light.surfaceMuted);
      expect(bar.minHeight, AppSpacing.space1);
      expect(find.bySemanticsLabel('Importing deck'), findsOneWidget);
    });

    testWidgets('indeterminate bar animates without a value', (tester) async {
      await tester.pumpWidget(
        _host(const MxProgress(semanticLabel: 'Loading')),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);
    });

    testWidgets('spinner renders the rotating ring', (tester) async {
      await tester.pumpWidget(
        _host(const MxProgress.spinner(semanticLabel: 'Saving')),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Saving'), findsOneWidget);
    });
  });

  group('MxBanner', () {
    testWidgets('warning tone pairs the soft ground with its foreground', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MxBanner(
            tone: MxBannerTone.warning,
            title: 'Offline',
            body: 'Changes will sync when you reconnect.',
            action: MxButton(
              onPressed: () {},
              label: 'Retry',
              variant: MxButtonVariant.ghost,
              size: MxButtonSize.sm,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MxBanner),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (container.decoration! as BoxDecoration).color,
        AppColors.light.warningSoft,
      );
      final title = tester.widget<Text>(find.text('Offline'));
      expect(title.style?.color, AppColors.light.onWarningSoft);
      expect(find.byIcon(Symbols.warning), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('error tone switches the pair and glyph', (tester) async {
      await tester.pumpWidget(
        _host(const MxBanner(tone: MxBannerTone.error, title: 'Save failed')),
      );

      final title = tester.widget<Text>(find.text('Save failed'));
      expect(title.style?.color, AppColors.light.onErrorSoft);
      expect(find.byIcon(Symbols.error), findsOneWidget);
    });
  });

  group('MxDialog', () {
    testWidgets('helper shows the panel and resolves an action result', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MxButton(
              onPressed: () async {
                result = await showMxDialog<String>(
                  context,
                  title: 'Delete this deck?',
                  body: const MxText('All 142 cards will be removed.'),
                  actions: [
                    MxButton(
                      onPressed: () => Navigator.of(context).pop('cancel'),
                      label: 'Cancel',
                      variant: MxButtonVariant.ghost,
                    ),
                    MxButton(
                      onPressed: () => Navigator.of(context).pop('delete'),
                      label: 'Delete',
                      danger: true,
                    ),
                  ],
                );
              },
              label: 'Open',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this deck?'), findsOneWidget);
      expect(find.text('All 142 cards will be removed.'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, 'delete');
      expect(find.text('Delete this deck?'), findsNothing);
    });

    testWidgets('barrier dismiss returns null', (tester) async {
      String? result = 'sentinel';
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MxButton(
              onPressed: () async {
                result = await showMxDialog<String>(
                  context,
                  title: 'Keep editing?',
                  body: const MxText('Draft is unsaved.'),
                  actions: const [],
                );
              },
              label: 'Open',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('MxSheet', () {
    testWidgets('helper shows handle, title and scrollable content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MxButton(
              onPressed: () => showMxSheet<void>(
                context,
                title: 'Card actions',
                child: Column(
                  children: [for (var i = 0; i < 40; i++) MxText('option $i')],
                ),
              ),
              label: 'Open sheet',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Card actions'), findsOneWidget);
      expect(find.byType(MxSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Height-capped: the sheet leaves the top of the screen visible.
      expect(
        tester.getSize(find.byType(MxSheet)).height,
        lessThan(tester.getSize(find.byType(MaterialApp)).height * 0.9),
      );
    });
  });
}
