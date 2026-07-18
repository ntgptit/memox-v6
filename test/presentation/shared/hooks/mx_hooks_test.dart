import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_search_hooks.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('useMxTextValue tracks the controller text', (tester) async {
    late String seen;
    await tester.pumpWidget(
      _host(
        HookBuilder(
          builder: (context) {
            final text = useMxTextValue(initial: 'seed');
            seen = text.value;
            return MxTextField(controller: text.controller);
          },
        ),
      ),
    );

    expect(seen, 'seed');
    await tester.enterText(find.byType(TextField), 'updated');
    await tester.pump();
    expect(seen, 'updated');
  });

  testWidgets('useMxTextSubmitState enables only on trimmed content', (
    tester,
  ) async {
    late bool canSubmit;
    await tester.pumpWidget(
      _host(
        HookBuilder(
          builder: (context) {
            final form = useMxTextSubmitState();
            canSubmit = form.canSubmit;
            return MxTextField(controller: form.controller);
          },
        ),
      ),
    );

    expect(canSubmit, isFalse);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(canSubmit, isFalse, reason: 'whitespace only never submits');

    await tester.enterText(find.byType(TextField), '  deck name  ');
    await tester.pump();
    expect(canSubmit, isTrue);
  });

  testWidgets('useMxSearchController trims the query and clears', (
    tester,
  ) async {
    late String query;
    late void Function() clear;
    await tester.pumpWidget(
      _host(
        HookBuilder(
          builder: (context) {
            final search = useMxSearchController();
            query = search.query;
            clear = search.clear;
            return MxTextField(controller: search.controller);
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  kanji  ');
    await tester.pump();
    expect(query, 'kanji');

    clear();
    await tester.pump();
    expect(query, '');
    expect(find.text('kanji'), findsNothing);
  });
}
