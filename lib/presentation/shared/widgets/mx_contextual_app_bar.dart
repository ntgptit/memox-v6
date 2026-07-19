import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
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
/// - onClose + closeLabel: modal-form variant (kit `.cappbar--modal`):
///   close glyph leading, centered title on a surface bar with a
///   bottom hairline (both required together; exclusive with onBack).
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
    this.onClose,
    this.closeLabel,
    this.actions = const <Widget>[],
    this.avatar,
  }) : assert(
         (onBack == null) == (backLabel == null),
         'onBack and backLabel come together',
       ),
       assert(
         (onClose == null) == (closeLabel == null),
         'onClose and closeLabel come together',
       ),
       assert(
         onBack == null || onClose == null,
         'back and close variants are exclusive',
       );

  final String title;
  final String? contextLine;
  final VoidCallback? onBack;
  final String? backLabel;
  final VoidCallback? onClose;
  final String? closeLabel;
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
    final onClose = this.onClose;
    final closeLabel = this.closeLabel;
    final avatar = this.avatar;
    final isModal = onClose != null;

    final titleBlock = Column(
      crossAxisAlignment: isModal
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
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
        decoration: BoxDecoration(
          color: isModal ? colors.surface : colors.bg,
          border: isModal
              ? Border(
                  bottom: BorderSide(
                    color: colors.divider,
                    width: AppStrokes.hairline,
                  ),
                )
              : null,
        ),
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
            if (onClose != null && closeLabel != null) ...[
              MxIconButton.toolbar(
                icon: Symbols.close,
                onPressed: onClose,
                semanticLabel: closeLabel,
              ),
              const MxGap.s2(),
            ],
            Expanded(child: titleBlock),
            // A modal bar balances its leading glyph so the centered
            // title stays optically centered.
            if (isModal) const MxGap.s10(),
            ...actions,
            if (avatar != null) ...[const MxGap.s2(), avatar],
          ],
        ),
      ),
    );
  }
}
