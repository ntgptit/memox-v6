import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The ONE shared top app bar (kit `MxContextualAppBar`).
///
/// Purpose:
/// Every screen header comes from this bar — root destinations show the
/// title (optionally with a context caption line), child screens lead
/// with Back — so no screen ever builds a per-screen header.
///
/// Use when:
/// The `appBar` slot of any `Mx*Scaffold`.
///
/// Do not use when:
/// Section headings inside the body (`MxSectionHeader`) or overlays.
///
/// Category:
/// navigation
///
/// Public API:
/// - title: the screen title.
/// - contextLine: optional caption above the title (root-contextual
///   variant; the on-scroll collapse composition is owned by the Today
///   screen, WBS 5.7).
/// - onBack + backLabel: child-screen variant leading with the quiet
///   toolbar Back action (both required together).
/// - actions: trailing `MxIconButton.toolbar` actions (guard rule).
/// - avatar: optional trailing avatar slot.
///
/// States:
/// root (title only), root-contextual (caption + title), child (Back +
/// title); with/without actions and avatar.
class MxContextualAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MxContextualAppBar({
    super.key,
    required this.title,
    this.contextLine,
    this.onBack,
    this.backLabel,
    this.actions = const <Widget>[],
    this.avatar,
  }) : assert(
         (onBack == null) == (backLabel == null),
         'onBack and backLabel come together',
       );

  final String title;
  final String? contextLine;
  final VoidCallback? onBack;
  final String? backLabel;
  final List<Widget> actions;
  final Widget? avatar;

  @override
  Size get preferredSize => Size.fromHeight(
    contextLine == null ? AppSpacing.appbarHeight : AppSpacing.appbarLgHeight,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final contextLine = this.contextLine;
    final onBack = this.onBack;
    final backLabel = this.backLabel;
    final avatar = this.avatar;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (contextLine != null) ...[
          MxText(contextLine, role: MxTextRole.caption),
          const MxGap.s05(),
        ],
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: styles.appBarTitle.copyWith(color: colors.text),
        ),
      ],
    );

    return Semantics(
      header: true,
      child: Container(
        color: colors.bg,
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top,
          left: context.spacing.gutter,
          right: context.spacing.gutter,
        ),
        height: preferredSize.height + MediaQuery.paddingOf(context).top,
        child: Row(
          children: [
            if (onBack != null && backLabel != null) ...[
              MxIconButton.toolbar(
                icon: Symbols.arrow_back,
                onPressed: onBack,
                semanticLabel: backLabel,
              ),
              const MxGap.s2(),
            ],
            Expanded(child: titleBlock),
            ...actions,
            if (avatar != null) ...[const MxGap.s2(), avatar],
          ],
        ),
      ),
    );
  }
}
