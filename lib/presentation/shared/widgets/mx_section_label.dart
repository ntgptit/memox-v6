import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';

/// Small caption above a field or section (kit `SectionLabel` helper:
/// sm/bold/wide tracking, secondary color, nudged in by s1).
///
/// Purpose:
/// The one label treatment above form fields and small content
/// sections, so grouping captions read identically everywhere.
///
/// Use when:
/// Labeling a field row or a short content group.
///
/// Do not use when:
/// Section headers with actions (`MxSectionHeader`) or in-card titles.
///
/// Category:
/// display
///
/// Public API:
/// - text: the label copy (caller uppercases when the kit does).
class MxSectionLabel extends StatelessWidget {
  const MxSectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space1,
        left: AppSpacing.space1,
      ),
      child: Text(
        text,
        style: context.textStyles.sectionLabel.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
