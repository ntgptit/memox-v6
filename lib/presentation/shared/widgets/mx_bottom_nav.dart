import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_motion.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// One destination of [MxBottomNav].
final class MxBottomNavItem {
  const MxBottomNavItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// The persistent bottom tab bar (kit `MxBottomNav`).
///
/// Purpose:
/// Root-destination navigation on compact windows; the active item gets
/// the tonal pill behind its icon and a brighter bold label so selection
/// never reads dimmer than idle (kit dark-mode rule).
///
/// Use when:
/// 2–5 root destinations on compact window classes (medium+ uses the
/// rail per the responsive contract).
///
/// Do not use when:
/// More than 5 destinations, in-screen actions, wizard steps, or
/// appearing/disappearing subsets.
///
/// Category:
/// navigation
///
/// Public API:
/// - items: 2–5 [MxBottomNavItem]s.
/// - value: the active item id.
/// - onChanged: receives the tapped item id.
///
/// States:
/// idle (text-secondary, semibold), active (tonal pill + on-primary-soft
/// glyph, text-color bold label), focus ring per item.
class MxBottomNav extends StatelessWidget {
  const MxBottomNav({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  }) : assert(items.length >= 2 && items.length <= 5, '2-5 destinations');

  final List<MxBottomNavItem> items;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: elevations.shadowNav,
      ),
      child: SizedBox(
        height: AppSpacing.bottomNavHeight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space2),
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _NavItem(
                    item: item,
                    active: item.id == value,
                    onTap: () => onChanged(item.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final MxBottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    final labelStyle = styles.navLabel.copyWith(
      fontWeight: active ? styles.boldWeight : null,
      color: active ? colors.text : colors.textSecondary,
    );

    return Semantics(
      selected: active,
      child: MxTappable(
        onTap: onTap,
        borderRadius: AppBorderRadii.pill,
        semanticLabel: item.label,
        enforceMinTouchTarget: false,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.durationFast,
                curve: AppMotion.easeStandard,
                constraints: const BoxConstraints(
                  maxWidth: AppComponentDimensions.navPillWidth,
                ),
                width: double.infinity,
                height: AppComponentDimensions.navPillHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? colors.primarySoft
                      : colors.primarySoft.withAlpha(0),
                  borderRadius: AppBorderRadii.pill,
                ),
                child: MxIcon(
                  icon: item.icon,
                  color: active ? colors.onPrimarySoft : colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppComponentDimensions.navItemGap),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
