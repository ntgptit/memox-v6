import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_component_dimensions.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';

/// Search input row (the input anatomy of the kit search dock).
///
/// Purpose:
/// The single search-entry surface — pill ground on the surface color,
/// leading search glyph, token-styled input and a clear affordance that
/// appears with content. The floating dock chrome (shadow, docked
/// positioning) is owned by `MxSearchDock` (WBS 3.6), which wraps this.
///
/// Use when:
/// Any search entry point; own the controller via `useMxSearchController`
/// (guard `memox.hooks.search_field_uses_shared_hook`).
///
/// Do not use when:
/// Free-form text entry (use `MxTextField`) or filtering a tiny fixed set
/// (chips/segmented).
///
/// Category:
/// input
///
/// Public API:
/// - controller / onChanged / onSubmitted: input wiring (controller
///   normally comes from `useMxSearchController`).
/// - placeholder: hint copy; also names the field for accessibility.
/// - clearLabel: localized semantics label for the clear action
///   (required — shared widgets never hardcode copy).
/// - flat: muted ground variant (kit `search-dock--flat`).
/// - autofocus / focusNode: focus wiring.
///
/// States:
/// empty, filled (clear affordance visible), focused (branded ring),
/// flat variant.
class MxSearchField extends StatefulWidget {
  const MxSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.placeholder,
    required this.clearLabel,
    this.flat = false,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;
  final String clearLabel;
  final bool flat;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<MxSearchField> createState() => _MxSearchFieldState();
}

class _MxSearchFieldState extends State<MxSearchField> {
  TextEditingController? _ownedController;
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    final input = TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.search,
      cursorColor: colors.primary,
      style: styles.body.copyWith(color: colors.text),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: widget.placeholder,
        hintStyle: styles.body.copyWith(color: colors.textTertiary),
      ),
    );

    final row = Row(
      children: [
        MxIcon(icon: Symbols.search, color: colors.textTertiary),
        const MxGap.s3(),
        Expanded(child: input),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return MxTappable(
              onTap: _clear,
              borderRadius: AppBorderRadii.pill,
              semanticLabel: widget.clearLabel,
              enforceMinTouchTarget: false,
              child: MxIcon(icon: Symbols.close, color: colors.textSecondary),
            );
          },
        ),
      ],
    );

    return Semantics(
      textField: true,
      label: widget.placeholder,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Container(
          height: AppComponentDimensions.searchDockHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          decoration: BoxDecoration(
            color: widget.flat ? colors.surfaceMuted : colors.surface,
            borderRadius: AppBorderRadii.pill,
            border: Border.all(
              color: _focused
                  ? colors.focusRing
                  : colors.focusRing.withAlpha(0),
              width: AppStrokes.focus,
            ),
          ),
          child: row,
        ),
      ),
    );
  }
}
