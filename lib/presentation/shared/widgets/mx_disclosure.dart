import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// A show-more control that reveals advanced content (kit
/// `flashcard-editor/more-toggle`).
///
/// Purpose:
/// Keeps a form's resting shape to its common path by folding the advanced
/// options behind one flat text control with a chevron.
///
/// Use when:
/// A screen has settings most users never change, and showing them by default
/// would bury the primary flow.
///
/// Do not use when:
/// The content is required to complete the task, or the section is a list
/// header (`window.SectionLabel`).
///
/// Category:
/// layout
///
/// Public API:
/// - label: names what opens; also the accessible name.
/// - open: whether the region is revealed.
/// - onToggle: asked to flip [open]; the owner holds the state.
/// - child: the region shown while open.
///
/// States:
/// collapsed (chevron down) and open (chevron up), plus the pressed and focus
/// ring [MxTappable] draws.
class MxDisclosure extends StatelessWidget {
  const MxDisclosure({
    super.key,
    required this.label,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final String label;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // `Align` keeps the control at its intrinsic width. A form column
        // stretches its children, and a stretched transparent button would put
        // a full-width tap target behind a two-word label.
        Align(
          alignment: Alignment.centerLeft,
          child: MxTappable(
            onTap: onToggle,
            semanticLabel: label,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  MxIcon(
                    icon: open
                        ? Symbols.expand_less_rounded
                        : Symbols.expand_more_rounded,
                    size: AppIconSizes.sm,
                    color: colors.textSecondary,
                  ),
                  const MxGap.s1(),
                  // Kit `.more-toggle`: sm, bold, text-secondary.
                  MxText(label, role: MxTextRole.captionStrong),
                ],
              ),
            ),
          ),
        ),
        if (open) ...<Widget>[const MxGap.s3(), child],
      ],
    );
  }
}
