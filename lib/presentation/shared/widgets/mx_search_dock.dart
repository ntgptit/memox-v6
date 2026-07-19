import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_search_field.dart';

/// The pill-shaped search dock at the top of list screens (kit
/// `MxSearchDock`).
///
/// Purpose:
/// The floating chrome around `MxSearchField`: the elevated pill (shadow
/// on the surface ground) or the flat muted treatment, with an optional
/// trailing control (filters).
///
/// Use when:
/// The search entry at the top of list screens (library, search).
///
/// Do not use when:
/// Inline form text entry (`MxTextField`).
///
/// Category:
/// input
///
/// Public API:
/// - placeholder / clearLabel / controller / onChanged / onSubmitted:
///   passthrough to `MxSearchField`; the controller is owned by the
///   consumer through `useMxSearchController` (guard hook contract) —
///   this dock never wires its own search state.
/// - trailing: optional trailing control (e.g. a filter
///   `MxIconButton`).
/// - flat: muted un-elevated treatment.
class MxSearchDock extends StatelessWidget {
  const MxSearchDock({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.placeholder,
    required this.clearLabel,
    this.trailing,
    this.flat = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;
  final String clearLabel;
  final Widget? trailing;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final elevations = context.elevations;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadii.pill,
        boxShadow: flat ? const <BoxShadow>[] : elevations.shadowSm,
      ),
      child: MxSearchField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        placeholder: placeholder,
        clearLabel: clearLabel,
        trailing: trailing,
        flat: flat,
      ),
    );
  }
}
