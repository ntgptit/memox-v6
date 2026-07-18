import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';

/// The one vertical list wrapper (kit `MxList`).
///
/// Purpose:
/// Owns the standard inter-item gap (space-3) so every stack of cards or
/// rows — decks, subdecks, flashcards, search results — spaces its items
/// identically; scroll-body section spacing stays the larger space-6.
///
/// Use when:
/// Stacking two or more cards/rows vertically.
///
/// Do not use when:
/// A single item, a form-field stack (section spacing owns that), or a
/// grid. Large lazy lists arrive with the library wave and reuse this
/// gap contract through separators.
///
/// Category:
/// layout
///
/// Public API:
/// - children: the stacked items.
/// - gap: spacing-token override for denser lists (default
///   `AppSpacing.space3`); never a hard-coded pixel value.
class MxList extends StatelessWidget {
  const MxList({
    super.key,
    required this.children,
    this.gap = AppSpacing.space3,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: gap),
          children[index],
        ],
      ],
    );
  }
}
