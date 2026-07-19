import 'package:flutter/material.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_field_scaffold.dart';

/// Single-line text input (kit `MxTextField` / `.field`).
///
/// Purpose:
/// One line of free text: bare by default (the visible box belongs to the
/// surrounding container), or a full labelled field group with label,
/// helper and validation state — all colors and type from tokens.
///
/// Use when:
/// The value is one line — a name, an answer, an email, a search term.
/// Enter submits rather than inserting a newline.
///
/// Do not use when:
/// The value may contain line breaks — use [MxTextArea], which is a real
/// multi-line control. Choosing from a fixed set (segmented/chips/menu) or
/// on/off (`MxSwitch`) are different components again.
///
/// Category:
/// input
///
/// Public API:
/// - controller: optional external controller (owned via `useMx*` hooks by
///   consumers; this family may own one internally per guard exclusion).
/// - onChanged / onSubmitted: value callbacks.
/// - label: renders the labelled field group and names the input.
/// - helper: support copy, hidden while `errorText` is set.
/// - errorText: validation state — error text/caret colors and a live
///   announcement; hides helper.
/// - requiredField: visual `*` and required semantics with a label.
/// - placeholder: hint at text-tertiary; names the input when bare.
/// - boxed: kit `Field` surface box.
/// - enabled / readOnly: kit `field--disabled` / `field--readonly` states.
/// - keyboardType / textInputAction / autofillHints / focusNode /
///   textAlign: input environment passthrough.
///
/// States:
/// empty, filled, focus (branded ring), error, disabled, read-only.
class MxTextField extends StatelessWidget {
  const MxTextField({
    super.key,
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

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? label;
  final String? helper;
  final String? errorText;
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
  Widget build(BuildContext context) {
    return MxFieldScaffold(
      // Pinned: a single-line field never grows, and the platform gives it
      // a submit key instead of a newline key.
      minLines: 1,
      maxLines: 1,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      label: label,
      helper: helper,
      errorText: errorText,
      boxed: boxed,
      requiredField: requiredField,
      placeholder: placeholder,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      focusNode: focusNode,
      textAlign: textAlign,
    );
  }
}
