import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_field_scaffold.dart';

/// A labelled field must expose exactly ONE text-field node, carrying both
/// its name and its value.
///
/// The regression this pins: the label/input/helper column was wrapped in
/// `Semantics(textField: true)`, so the *group* claimed to be the field.
/// The visible label merged into the accessible name (producing
/// `Deck name\nDeck name *`) and the group node, which holds no value,
/// shadowed the real input — a screen reader read the name twice and never
/// announced what had been typed. It also broke the parity gate, where
/// `getByRole('textbox')` resolved to the valueless wrapper.
Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('MxFieldScaffold semantics', () {
    testWidgets('a labelled field is one node carrying label and value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Korean TOPIK I');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          MxFieldScaffold(
            minLines: 1,
            maxLines: 1,
            label: 'Deck name',
            controller: controller,
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(EditableText));
      expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
      expect(
        node.label,
        'Deck name',
        reason: 'the visible label must name the field exactly once',
      );
      expect(
        node.value,
        'Korean TOPIK I',
        reason: 'the node that claims to be the text field must hold its value',
      );

      handle.dispose();
    });

    testWidgets('a required field is still named once', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Beginner Grammar');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          MxFieldScaffold(
            minLines: 1,
            maxLines: 1,
            label: 'Deck name',
            requiredField: true,
            controller: controller,
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(EditableText));
      // The required marker is a visual affordance on the label; it must
      // not be appended to the field's accessible name.
      expect(node.label, 'Deck name');
      expect(node.value, 'Beginner Grammar');

      handle.dispose();
    });

    testWidgets('exactly one node in the subtree claims to be a text field', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'x');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          MxFieldScaffold(
            minLines: 1,
            maxLines: 1,
            label: 'Deck name',
            helper: 'Shown under the field',
            controller: controller,
          ),
        ),
      );

      var textFieldNodes = 0;
      void visit(SemanticsNode node) {
        if (node.getSemanticsData().flagsCollection.isTextField) {
          textFieldNodes += 1;
        }
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      // Climb to the semantics root from the node we know exists, rather
      // than reaching for a binding-level owner the test binding leaves null.
      var root = tester.getSemantics(find.byType(EditableText));
      while (root.parent != null) {
        root = root.parent!;
      }
      visit(root);
      expect(
        textFieldNodes,
        1,
        reason: 'a wrapper that also claims isTextField shadows the real input',
      );

      handle.dispose();
    });

    testWidgets('an error is announced without renaming the field', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'x');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          MxFieldScaffold(
            minLines: 1,
            maxLines: 1,
            label: 'Deck name',
            errorText: 'Name is required',
            controller: controller,
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(EditableText));
      expect(node.label, 'Deck name');
      // The error keeps its own live region rather than being folded into
      // the field's name.
      expect(find.text('Name is required'), findsOneWidget);

      handle.dispose();
    });
  });
}
