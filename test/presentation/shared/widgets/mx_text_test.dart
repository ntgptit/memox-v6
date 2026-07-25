import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_typography.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// WBS 2.6 type scale — the emphasis roles.
///
/// The scale stepped straight from `body` (base/regular) to `bodyLarge`
/// (md/semibold), with nothing at base+bold. The kit sets that pairing on
/// banner titles, setting names and Match tiles, so three call sites had
/// borrowed `button` — a label role that happens to share the pairing. These
/// tests pin the two emphasis roles as distinct from the roles they emphasise,
/// which is the whole reason they exist.
void main() {
  Future<TextStyle> styleOf(WidgetTester tester, MxTextRole role) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: MxText('사랑', role: role)),
      ),
    );
    return tester.widget<Text>(find.text('사랑')).style ?? const TextStyle();
  }

  testWidgets('bodyStrong is body at emphasis weight, not a larger role', (
    tester,
  ) async {
    final body = await styleOf(tester, MxTextRole.body);
    final strong = await styleOf(tester, MxTextRole.bodyStrong);

    expect(strong.fontSize, body.fontSize, reason: 'same step of the scale');
    expect(strong.fontWeight, AppTypography.fontWeightBold);
    expect(body.fontWeight, AppTypography.fontWeightRegular);
  });

  testWidgets('captionStrong is caption at emphasis weight', (tester) async {
    final caption = await styleOf(tester, MxTextRole.caption);
    final strong = await styleOf(tester, MxTextRole.captionStrong);

    expect(strong.fontSize, caption.fontSize);
    expect(strong.fontWeight, AppTypography.fontWeightBold);
  });

  testWidgets('captionStrong keeps caption\'s secondary colour default', (
    tester,
  ) async {
    // The emphasis roles inherit their base role's colour default; a strong
    // caption that turned primary would read as a heading rather than as
    // emphasised metadata.
    final caption = await styleOf(tester, MxTextRole.caption);
    final strong = await styleOf(tester, MxTextRole.captionStrong);

    expect(strong.color, caption.color);
  });
}
