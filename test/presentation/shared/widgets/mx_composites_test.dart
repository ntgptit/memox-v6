import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_colors.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_select_sheet.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_confirm_dialog.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('showMxConfirmDialog', () {
    Widget launcher({
      required void Function(bool) onResult,
      MxConfirmTone tone = MxConfirmTone.error,
    }) {
      return _host(
        Builder(
          builder: (context) => MxButton(
            onPressed: () async {
              onResult(
                await showMxConfirmDialog(
                  context,
                  icon: Symbols.delete,
                  tone: tone,
                  title: 'Delete this card?',
                  text: "This can't be undone.",
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                ),
              );
            },
            label: 'Open',
          ),
        ),
      );
    }

    testWidgets('confirm resolves true with the danger action', (tester) async {
      bool? result;
      await tester.pumpWidget(launcher(onResult: (value) => result = value));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this card?'), findsOneWidget);
      // Error tone tints the header icon.
      final icon = tester.widget<Icon>(find.byIcon(Symbols.delete));
      expect(icon.color, AppColors.light.error);
      // Error tone forces the danger confirm fill.
      final confirm = tester.widget<MxButton>(
        find.widgetWithText(MxButton, 'Delete'),
      );
      expect(confirm.danger, isTrue);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('cancel and barrier both resolve false', (tester) async {
      bool? result;
      await tester.pumpWidget(launcher(onResult: (value) => result = value));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('showMxSelectSheet', () {
    testWidgets('marks the selected row and returns the tapped key', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MxButton(
              onPressed: () async {
                result = await showMxSelectSheet<String>(
                  context,
                  title: 'Card source',
                  selected: 'srs',
                  options: const [
                    MxSelectOption(
                      key: 'srs',
                      icon: Symbols.schedule,
                      label: 'By schedule',
                    ),
                    MxSelectOption(
                      key: 'all',
                      icon: Symbols.apps,
                      label: 'All cards',
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

      // Uppercase title (overline role) and the selected check.
      expect(find.text('CARD SOURCE'), findsOneWidget);
      final check = tester.widget<Icon>(find.byIcon(Symbols.check_circle));
      expect(check.color, AppColors.light.accent);

      await tester.tap(find.text('All cards'));
      await tester.pumpAndSettle();
      expect(result, 'all');
      expect(find.text('CARD SOURCE'), findsNothing);
    });

    testWidgets('dismiss returns null', (tester) async {
      String? result = 'sentinel';
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MxButton(
              onPressed: () async {
                result = await showMxSelectSheet<String>(
                  context,
                  title: 'Sort by',
                  options: const [
                    MxSelectOption(
                      key: 'az',
                      icon: Symbols.sort_by_alpha,
                      label: 'A to Z',
                    ),
                    MxSelectOption(
                      key: 'za',
                      icon: Symbols.sort_by_alpha,
                      label: 'Z to A',
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
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
