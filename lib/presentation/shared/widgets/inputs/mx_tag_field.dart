import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/core/theme/tokens/app_opacities.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';

/// The compact tag surface (kit `TagsField`).
///
/// Purpose:
/// One low-weight row that both *shows* a card's tags and *accepts* new ones,
/// so tagging never competes with Term and Meaning for attention.
///
/// Use when:
/// A card-scoped tag list — the Card Editor's edit mode.
///
/// Do not use when:
/// Tags are a filter rather than content (that is the Library `FilterRow`,
/// which uses bare [MxChip]s with no entry field).
///
/// Category:
/// input
///
/// Public API:
/// - label: the section label above the row.
/// - chips: the already-attached tags, rendered inside the row.
/// - controller / onSubmitted / placeholder: entry for a new tag.
/// - enabled: dims and blocks the whole surface while a mutation is in
///   flight.
///
/// The entry field lives *inside* the bordered row rather than below it,
/// because that is what the kit draws: its empty state puts the "Add tags —
/// e.g. …" hint inside the box, which only makes sense if the box is the
/// input. Chips and the caret share one surface.
class MxTagField extends StatelessWidget {
  const MxTagField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.chips,
    this.enabled = true,
    this.onSubmitted,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final List<Widget> chips;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  /// Enough room for a tag being typed without starving the chips beside it.
  static const double _entryWidth = 132;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;

    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: styles.fieldLabel.copyWith(color: colors.textSecondary),
        ),
        const MxGap.s2(),
        Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMin),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space2,
            horizontal: AppSpacing.space4,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppBorderRadii.control,
            border: Border.all(
              color: colors.divider,
              width: AppStrokes.hairline,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              MxIcon(
                icon: Symbols.sell,
                size: AppIconSizes.sm,
                color: colors.textTertiary,
              ),
              const MxGap.s2(),
              Expanded(
                child: Wrap(
                  spacing: MxGap.s2Value,
                  runSpacing: MxGap.s2Value,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    ...chips,
                    SizedBox(
                      width: _entryWidth,
                      child: TextField(
                        controller: controller,
                        enabled: enabled,
                        onSubmitted: onSubmitted,
                        style: styles.body,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          // The hint carries the whole empty state, exactly as
                          // the kit's box does when a card has no tags.
                          hintText: chips.isEmpty ? placeholder : null,
                          hintStyle: styles.body.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!enabled) {
      field = Opacity(opacity: AppOpacities.opacityMuted, child: field);
    }
    return field;
  }
}
