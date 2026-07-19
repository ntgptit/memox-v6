import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Shared field chrome behind `MxTextField` and `MxTextArea` (kit `.field`).
///
/// Purpose:
/// One implementation of everything the two public inputs have in common:
/// the branded focus ring, the boxed `Field` surface, the label/helper/
/// error group and the field semantics. The public inputs then differ in
/// exactly one thing — how many lines they occupy.
///
/// Use when:
/// Never from feature code. This is internal plumbing for the inputs
/// family; use `MxTextField` for a single-line value or `MxTextArea` for
/// one that may contain line breaks.
///
/// Do not use when:
/// Building a screen. Reaching for this directly re-opens the line-count
/// choice that splitting the two public inputs exists to close.
///
/// Category:
/// input
///
/// Public API:
/// - minLines / maxLines: the line box, supplied by the owning input.
/// - controller: optional external controller; one is owned internally
///   when the caller supplies none.
/// - onChanged / onSubmitted: value callbacks.
/// - label / helper / errorText / requiredField: the field group.
/// - boxed: kit `Field` surface box.
/// - placeholder / enabled / readOnly: input surface state.
/// - keyboardType / textInputAction / autofillHints / focusNode /
///   textAlign: input environment passthrough.
///
/// States:
/// empty, filled, focus (branded ring), error, disabled, read-only.
class MxFieldScaffold extends StatefulWidget {
  const MxFieldScaffold({
    super.key,
    required this.minLines,
    required this.maxLines,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.helper,
    this.errorText,
    this.boxed = false,
    this.requiredField = false,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.textAlign = TextAlign.start,
  });

  /// Lines the field occupies at rest, before anything is typed.
  final int minLines;

  /// Growth cap; equal to [minLines] for a field that never grows.
  final int maxLines;

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? label;
  final String? helper;
  final String? errorText;

  /// Renders the kit `Field` surface box (touch-height white surface
  /// with hairline border; error swaps to the emphasis error border).
  /// Default false: the surrounding container owns the visible box.
  final bool boxed;

  final bool requiredField;
  final String? placeholder;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  @override
  State<MxFieldScaffold> createState() => _MxFieldScaffoldState();
}

class _MxFieldScaffoldState extends State<MxFieldScaffold> {
  TextEditingController? _ownedController;
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final hasError = widget.errorText != null;

    final textColor = !widget.enabled
        ? colors.textTertiary
        : widget.readOnly
        ? colors.textSecondary
        : hasError
        ? colors.error
        : colors.text;

    Widget input = TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      showCursor: widget.readOnly ? false : null,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      focusNode: widget.focusNode,
      textAlign: widget.textAlign,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      cursorColor: hasError ? colors.error : colors.primary,
      style: styles.body.copyWith(color: textColor),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: widget.placeholder,
        hintStyle: styles.body.copyWith(color: colors.textTertiary),
      ),
    );

    // Branded focus ring (kit `.field:focus-visible`). ONE ring only:
    // a boxed field draws it over its own surface edge, a bare field
    // around the input — never nested, never taking layout space.
    final showRing = _focused && widget.enabled;
    input = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: widget.boxed
          ? input
          : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppBorderRadii.xs,
                border: Border.all(
                  color: showRing
                      ? colors.focusRing
                      : colors.focusRing.withAlpha(0),
                  width: AppStrokes.focus,
                ),
              ),
              child: input,
            ),
    );

    if (widget.boxed) {
      input = Container(
        alignment: Alignment.centerLeft,
        constraints: const BoxConstraints(minHeight: AppSpacing.touchMin),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space2,
          horizontal: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppBorderRadii.control,
          border: Border.all(
            color: hasError ? colors.error : colors.divider,
            width: hasError ? AppStrokes.emphasis : AppStrokes.hairline,
          ),
        ),
        // The ring paints over the surface edge on focus, replacing the
        // resting hairline instead of nesting a second outline inside.
        foregroundDecoration: BoxDecoration(
          borderRadius: AppBorderRadii.control,
          border: Border.all(
            color: showRing ? colors.focusRing : colors.focusRing.withAlpha(0),
            width: AppStrokes.focus,
          ),
        ),
        child: input,
      );
    }

    final label = widget.label;
    if (label == null &&
        widget.helper == null &&
        !hasError &&
        !widget.requiredField) {
      return input;
    }

    final support = _buildSupport(context);

    Widget group = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...[
          _buildLabel(context, label),
          const MxGap.s2(),
        ],
        input,
        if (support != null) ...[const MxGap.s2(), support],
      ],
    );

    if (!widget.enabled) {
      group = Opacity(opacity: AppOpacities.opacityDisabled, child: group);
    }

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: label ?? widget.placeholder,
      child: group,
    );
  }

  /// Kit `SectionLabel` treatment (s1 top/left nudge), with the required
  /// star carrying the error color.
  Widget _buildLabel(BuildContext context, String label) {
    final colors = context.colors;
    final styles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space1,
        left: AppSpacing.space1,
      ),
      child: Text.rich(
        TextSpan(
          text: label,
          style: styles.sectionLabel.copyWith(color: colors.textSecondary),
          children: [
            if (widget.requiredField)
              TextSpan(
                text: ' *',
                style: styles.sectionLabel.copyWith(color: colors.error),
              ),
          ],
        ),
      ),
    );
  }

  /// Error text (announced) wins over helper text; neither renders when
  /// the field only carries a label.
  Widget? _buildSupport(BuildContext context) {
    final colors = context.colors;
    final errorText = widget.errorText;
    if (errorText != null) {
      return Semantics(
        liveRegion: true,
        child: MxText(
          errorText,
          role: MxTextRole.caption,
          color: colors.error,
        ),
      );
    }

    final helper = widget.helper;
    if (helper == null) return null;
    return MxText(
      helper,
      role: MxTextRole.caption,
      color: colors.textTertiary,
    );
  }
}
