import 'package:flutter/material.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_field_scaffold.dart';

/// Multi-line text input (kit `MxTextField` with `multiline` / `.field--multiline`).
///
/// Purpose:
/// Free text that may contain line breaks — descriptions, notes, pasted
/// content. Shares every visual with [MxTextField]; it differs only in
/// being a real multi-line control, so Enter inserts a newline instead of
/// submitting and intentional line breaks survive.
///
/// Use when:
/// The value is prose the user may deliberately break across lines. Deck
/// descriptions are the canonical case — `docs/business/deck/edit-deck.md`
/// §Description requires intentional line breaks to be preserved.
///
/// Do not use when:
/// The value is one line — use [MxTextField]. A single-line value in a
/// multi-line control invites stray newlines the domain then has to strip.
///
/// Category:
/// input
///
/// Public API:
/// - rows: lines shown at rest, before anything is typed. The kit's
///   `rows` prop; default 3 as in the kit. Pass `rows: 1` for a field
///   that should start compact and grow into its content.
/// - maxRows: growth cap before the field scrolls internally.
/// - everything else: identical to [MxTextField].
///
/// States:
/// empty, filled, focus (branded ring), error, disabled, read-only.
class MxTextArea extends StatelessWidget {
  const MxTextArea({
    super.key,
    this.rows = 3,
    this.maxRows = 6,
    this.controller,
    this.onChanged,
    this.label,
    this.helper,
    this.errorText,
    this.boxed = false,
    this.requiredField = false,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.textAlign = TextAlign.start,
  }) : assert(rows >= 1, 'rows must be at least 1'),
       assert(maxRows >= rows, 'maxRows cannot be smaller than rows');

  /// Lines shown at rest (kit `rows`).
  final int rows;

  /// Growth cap before the field scrolls internally.
  final int maxRows;

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? label;
  final String? helper;
  final String? errorText;
  final bool boxed;
  final bool requiredField;
  final String? placeholder;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return MxFieldScaffold(
      minLines: rows,
      maxLines: maxRows,
      controller: controller,
      onChanged: onChanged,
      // Deliberately no `onSubmitted`/`textInputAction`: in a multi-line
      // control the Enter key belongs to the text, not to the form.
      label: label,
      helper: helper,
      errorText: errorText,
      boxed: boxed,
      requiredField: requiredField,
      placeholder: placeholder,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: TextInputType.multiline,
      focusNode: focusNode,
      textAlign: textAlign,
    );
  }
}
