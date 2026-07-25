import 'package:flutter/material.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_list.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_skeleton.dart';

/// The deck detail's two loading placeholders (`MX-VIS-037`, `MX-VIS-043`).
///
/// Split out of `deck_detail_screen.dart` for file size. Which one a screen
/// shows is decided there, from the resolved child decks.

/// `subdeck-list--loading` (MX-VIS-037): the parent branch's placeholder —
/// a filter-row pill over four deck rows, each a round tile beside a long
/// and a short line. Transcribed from the kit `SubdeckList.jsx` loading
/// branch, which states it matches the Library root's.
class DeckRowsSkeleton extends StatelessWidget {
  const DeckRowsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonBody(
      filterHeight: 40,
      rows: MxList(
        children: <Widget>[
          for (var i = 0; i < 4; i++)
            const MxCard(
              padding: MxCardPadding.sm,
              child: Row(
                children: <Widget>[
                  MxSkeleton.circle(size: 40),
                  MxGap.s4(),
                  Expanded(
                    child: _SkeletonLines(
                      first: 0.6,
                      second: 0.4,
                      firstHeight: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// `flashcard-list--loading` (MX-VIS-043): the leaf branch's placeholder —
/// a taller filter-row pill over five card rows, each two lines beside a
/// trailing badge pill, with no leading tile. Transcribed from the kit
/// `FlashcardList.jsx` loading branch, where the five cards are direct
/// children of the body rather than an `MxList`, so they take the body's
/// own `space-6` rhythm instead of the list's `space-3`.
class CardRowsSkeleton extends StatelessWidget {
  const CardRowsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonBody(
      filterHeight: 44,
      rows: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < 5; i++) ...const <Widget>[
            MxCard(
              padding: MxCardPadding.sm,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _SkeletonLines(
                      first: 0.45,
                      second: 0.65,
                      firstHeight: 16,
                    ),
                  ),
                  MxGap.s4(),
                  MxSkeleton(width: 56, height: 22),
                ],
              ),
            ),
            MxGap.s6(),
          ],
        ],
      ),
    );
  }
}

/// The body both loading branches share: the filter-row pill, then the rows.
class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({required this.filterHeight, required this.rows});

  final double filterHeight;
  final Widget rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The same space-4 the loaded branches open with. Without it the
          // placeholder sat 16px higher than the content it stands in for,
          // so the screen visibly jumped when the data arrived.
          const MxGap.s4(),
          MxSkeleton(height: filterHeight),
          const MxGap.s6(),
          rows,
        ],
      ),
    );
  }
}

/// A row's two text placeholders: a longer line over a shorter one, at the
/// kit's `space-2` rhythm. Widths are fractions of the row, and the first
/// line's height differs per branch — the kit's deck rows use 14 and its
/// card rows 16, which is a 2px-per-row drift if the two are conflated.
class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines({
    required this.first,
    required this.second,
    required this.firstHeight,
  });

  final double first;
  final double second;
  final double firstHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: first,
          child: MxSkeleton(height: firstHeight),
        ),
        const MxGap.s2(),
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: second,
          child: const MxSkeleton(height: 10),
        ),
      ],
    );
  }
}
