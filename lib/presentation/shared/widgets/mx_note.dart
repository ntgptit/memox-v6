import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Tone pairs of the kit `Note` contract.
///
/// Named for what they render, not for what the kit's JSX calls them: the kit
/// writes `tone="accent"` for the pair that resolves to `--memox-primary-soft`
/// / `--memox-on-primary-soft`. `MxBannerTone.accent` means the *accent* ramp,
/// so reusing that word here would put two different colours behind one name.
enum MxNoteTone { primary, success, warning, error }

/// A one-line tinted status note (kit `Note`).
///
/// Purpose:
/// A short, non-interactive sentence on a soft tone ground — the smallest
/// feedback surface in the kit. The caller picks the glyph, because the note
/// says something specific ("Streak reset", "Time is up") that a
/// tone-derived icon cannot name.
///
/// Use when:
/// A single sentence reports state in place: the dashboard's streak notes,
/// the recall verdict, the hint line, the relearn marker.
///
/// Do not use when:
/// The message needs a title, body and an action — that is `MxBanner`,
/// which the kit keeps as a separate component for the same reason.
///
/// Category:
/// feedback
///
/// Public API:
/// - tone: the soft/on-soft pair.
/// - icon: a `Symbols.*` glyph, caller-chosen.
/// - text: one sentence; wraps rather than truncating.
///
/// Residual: the kit's copy is `font-weight-semibold` and the nearest role,
/// `captionStrong`, is bold. The type scale has no small semibold role, and a
/// role added for one component would be a token invented in the UI layer.
class MxNote extends StatelessWidget {
  const MxNote({
    super.key,
    required this.tone,
    required this.icon,
    required this.text,
  });

  final MxNoteTone tone;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = switch (tone) {
      MxNoteTone.primary => (colors.primarySoft, colors.onPrimarySoft),
      MxNoteTone.success => (colors.successSoft, colors.onSuccessSoft),
      MxNoteTone.warning => (colors.warningSoft, colors.onWarningSoft),
      MxNoteTone.error => (colors.errorSoft, colors.onErrorSoft),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space3,
        horizontal: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadii.control,
      ),
      child: Row(
        // Centered while the sentence is one line, top-aligned once it wraps —
        // which `start` gives on a single line too, since the row is then only
        // as tall as its tallest child.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MxIcon(icon: icon, size: AppIconSizes.sm, color: fg),
          const MxGap.s2(),
          Expanded(
            child: MxText(text, role: MxTextRole.captionStrong, color: fg),
          ),
        ],
      ),
    );
  }
}
