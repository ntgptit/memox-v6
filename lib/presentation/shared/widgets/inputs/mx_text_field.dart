import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Inline text input (kit `MxTextField` / `.field`).
///
/// Purpose:
/// The single text-input surface: bare by default (the visible box belongs
/// to the surrounding container), or a full labelled field group with
/// label, helper and validation state — all colors and type from tokens.
///
/// Use when:
/// Any free-text entry — editor fields, answers, paste boxes, forms.
///
/// Do not use when:
/// Choosing from a fixed set (segmented/chips/menu) or on/off
/// (`MxSwitch`).
///
/// Category:
/// input
///
/// Public API:
/// - controller: optional external controller (owned via `useMx*` hooks by
///   consumers; this file may own one internally per guard exclusion).
/// - onChanged / onSubmitted: value callbacks.
/// - label: renders the labelled field group and names the input.
/// - helper: support copy, hidden while `errorText` is set.
/// - errorText: validation state — error text/caret colors and a live
///   announcement; hides helper.
/// - requiredField: visual `*` and required semantics with a label.
/// - placeholder: hint at text-tertiary; names the input when bare.
/// - enabled / readOnly: kit `field--disabled` / `field--readonly` states.
/// - multiline / minLines / maxLines: kit multiline variant.
/// - keyboardType / textInputAction / autofillHints / focusNode /
///   textAlign: input environment passthrough.
///
/// States:
/// empty, filled, focus (branded ring), error, disabled, read-only,
/// multiline.
class MxTextField extends StatefulWidget {
  const MxTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.helper,
    this.errorText,
    this.requiredField = false,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
    this.multiline = false,
    this.minLines,
    this.maxLines,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? label;
  final String? helper;
  final String? errorText;
  final bool requiredField;
  final String? placeholder;
  final bool enabled;
  final bool readOnly;
  final bool multiline;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  @override
  State<MxTextField> createState() => _MxTextFieldState();
}

class _MxTextFieldState extends State<MxTextField> {
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
      keyboardType:
          widget.keyboardType ??
          (widget.multiline ? TextInputType.multiline : null),
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      focusNode: widget.focusNode,
      textAlign: widget.textAlign,
      minLines: widget.multiline ? (widget.minLines ?? 2) : 1,
      maxLines: widget.multiline ? (widget.maxLines ?? 6) : 1,
      cursorColor: hasError ? colors.error : colors.primary,
      style: styles.body.copyWith(color: textColor),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: widget.placeholder,
        hintStyle: styles.body.copyWith(color: colors.textTertiary),
      ),
    );

    // Bare-field branded focus ring (kit `.field:focus-visible`), space
    // reserved so focusing never shifts layout.
    input = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppBorderRadii.xs,
          border: Border.all(
            color: _focused && widget.enabled
                ? colors.focusRing
                : colors.focusRing.withAlpha(0),
            width: AppStrokes.focus,
          ),
        ),
        child: input,
      ),
    );

    final label = widget.label;
    if (label == null &&
        widget.helper == null &&
        !hasError &&
        !widget.requiredField) {
      return input;
    }

    final Widget? support = hasError
        ? Semantics(
            liveRegion: true,
            child: MxText(
              widget.errorText ?? '',
              role: MxTextRole.caption,
              color: colors.error,
            ),
          )
        : widget.helper != null
        ? MxText(
            widget.helper ?? '',
            role: MxTextRole.caption,
            color: colors.textTertiary,
          )
        : null;

    final children = <Widget>[
      if (label != null) ...[
        Text.rich(
          TextSpan(
            text: label,
            style: styles.fieldLabel.copyWith(color: colors.textSecondary),
            children: [
              if (widget.requiredField)
                TextSpan(
                  text: ' *',
                  style: styles.fieldLabel.copyWith(color: colors.error),
                ),
            ],
          ),
        ),
        const MxGap.s2(),
      ],
      input,
      if (support != null) ...[const MxGap.s2(), support],
    ];

    Widget group = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
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
}
