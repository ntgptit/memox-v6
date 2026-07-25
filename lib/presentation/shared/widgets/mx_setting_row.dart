import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// A labelled setting on a flat sunken surface (kit
/// `flashcard-editor/visibility`, and the same shape in Settings/Reminder).
///
/// Purpose:
/// Pairs a named setting and its consequence with the control that changes
/// it — no icon tile, no elevation, the control trailing.
///
/// Use when:
/// A setting needs a sentence of explanation beside its control, e.g. a
/// switch whose effect is not obvious from its label alone.
///
/// Do not use when:
/// The row navigates somewhere (`window.ListRow`), or the label alone is
/// enough — then use the bare control.
///
/// Category:
/// layout
///
/// Public API:
/// - title: names the setting, bold at base size.
/// - body: one sentence naming what the setting actually does.
/// - trailing: the control, e.g. an `MxSwitch`.
///
/// States:
/// none of its own; the trailing control owns them.
class MxSettingRow extends StatelessWidget {
  const MxSettingRow({
    super.key,
    required this.title,
    required this.body,
    required this.trailing,
  });

  final String title;
  final String body;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space3,
        horizontal: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: AppBorderRadii.control,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Kit titles this row semibold at base size. `MxText` has no
                // bold-base role, so this borrows the button style the same
                // way `MxBanner` does for its own title.
                Text(title, style: styles.button),
                const MxGap.s1(),
                MxText(
                  body,
                  role: MxTextRole.caption,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const MxGap.s4(),
          trailing,
        ],
      ),
    );
  }
}
