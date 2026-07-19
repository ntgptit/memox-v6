import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// Inline text action (kit `MxLink`): bold accent copy on a full
/// touch-height target that stays visually compact.
///
/// Purpose:
/// Tertiary actions rendered as text — "Change", "Show", "Not now" —
/// so links look identical everywhere.
///
/// Use when:
/// A low-emphasis action beside content or under a CTA stack.
///
/// Do not use when:
/// Primary/secondary actions (`MxButton`) or toolbar glyph actions
/// (`MxIconButton`).
///
/// Category:
/// button
///
/// Public API:
/// - label: the link copy (localized by the caller).
/// - onTap: the action; null renders the disabled state.
/// - small: kit `size="sm"` (13) — default; false uses base (15).
class MxLink extends StatelessWidget {
  const MxLink({
    super.key,
    required this.label,
    required this.onTap,
    this.small = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final base = small ? styles.caption : styles.body;

    return MxTappable(
      onTap: onTap,
      semanticLabel: label,
      // Center keeps the compact copy in the middle of the 48px touch
      // target (kit `.link`: inline-flex + align-items center).
      child: Center(
        widthFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
          child: Text(
            label,
            style: base.copyWith(
              fontWeight: styles.boldWeight,
              color: colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
