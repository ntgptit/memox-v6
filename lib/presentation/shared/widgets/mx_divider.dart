import 'package:flutter/material.dart';

/// Hairline separator on the divider token (kit `--memox-divider`).
///
/// Purpose:
/// The single divider primitive — color and hairline thickness come from
/// the app theme's `DividerTheme` (WBS 2.7), so separators look identical
/// everywhere.
///
/// Use when:
/// Separating peer content inside a surface where spacing alone is not
/// enough.
///
/// Category:
/// display
///
/// Public API:
/// - key: the only parameter; appearance is fully theme-driven with no
///   per-call styling.
class MxDivider extends StatelessWidget {
  const MxDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider();
}
