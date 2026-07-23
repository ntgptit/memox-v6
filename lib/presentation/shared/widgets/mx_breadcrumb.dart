import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// One crumb in an [MxBreadcrumb] (kit `.breadcrumb__crumb`).
///
/// [onTap] non-null renders a tappable ancestor crumb; the last item in the
/// list is always the current, non-interactive page label regardless of
/// [onTap].
@immutable
class MxBreadcrumbItem {
  const MxBreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// Nested-deck path affordance (kit shared widget `breadcrumb`): the ancestor
/// trail for a multi-level tree — `Library › Korean › TOPIK I › Grammar`.
///
/// Purpose:
/// Show where the current deck sits in the hierarchy and let the reader jump
/// straight to any ancestor.
///
/// Use when:
/// A screen renders a node inside a deck tree deeper than the root (WBS 6.2).
///
/// Do not use when:
/// The node is a root deck — the app-bar back is the only up-navigation there.
///
/// Category:
/// navigation
///
/// Public API:
/// - items: ordered root → current. Ancestor crumbs carry `onTap`; the last
///   item renders as the bold, non-interactive page crumb.
///
/// The row scrolls horizontally when the path is wider than the viewport (kit
/// `.breadcrumb { overflow-x: auto }`), so every ancestor stays reachable.
class MxBreadcrumb extends StatelessWidget {
  const MxBreadcrumb({super.key, required this.items});

  final List<MxBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final styles = context.textStyles;
    // Kit: crumbs are sm/medium and secondary; the current page is sm/semibold
    // and primary text (`.breadcrumb__crumb` vs `.breadcrumb__current`).
    final crumbStyle = styles.breadcrumbCrumb.copyWith(
      color: colors.textSecondary,
    );
    final currentStyle = styles.breadcrumbCurrent.copyWith(color: colors.text);

    final lastIndex = items.length - 1;
    final row = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        row.add(const _MxBreadcrumbSeparator());
      }
      final item = items[i];
      row.add(
        _MxCrumb(
          item: item,
          isCurrent: i == lastIndex,
          crumbStyle: crumbStyle,
          currentStyle: currentStyle,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: row),
    );
  }
}

/// The chevron between two crumbs (kit `.breadcrumb__sep`).
class _MxBreadcrumbSeparator extends StatelessWidget {
  const _MxBreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      child: MxIcon(
        icon: Symbols.chevron_right,
        size: AppIconSizes.sm,
        color: context.colors.textTertiary,
      ),
    );
  }
}

class _MxCrumb extends StatelessWidget {
  const _MxCrumb({
    required this.item,
    required this.isCurrent,
    required this.crumbStyle,
    required this.currentStyle,
  });

  final MxBreadcrumbItem item;
  final bool isCurrent;
  final TextStyle crumbStyle;
  final TextStyle currentStyle;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Text(item.label, style: currentStyle, maxLines: 1);
    }
    final onTap = item.onTap;
    final label = Text(item.label, style: crumbStyle, maxLines: 1);
    if (onTap == null) return label;
    return MxTappable(onTap: onTap, semanticLabel: item.label, child: label);
  }
}
