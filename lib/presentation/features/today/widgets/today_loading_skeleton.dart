import 'package:flutter/widgets.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_skeleton.dart';

/// The dashboard's loading placeholder (kit `dashboard--loading`).
///
/// Stands in for what actually arrives: a section label, the primary action,
/// the daily-goal card, a second section label and two deck rows. The kit
/// draws the shapes of the content rather than a spinner, so the screen does
/// not jump when the data lands.
///
/// The greeting is not part of this: it renders above every state including
/// this one, because it needs no data at all.
class TodayLoadingSkeleton extends StatelessWidget {
  const TodayLoadingSkeleton({super.key});

  /// Kit `<S w="55%" h={16} />` and friends. Widths are fractions of the
  /// content column, which is why they are read as factors rather than pixels.
  static const double _labelHeight = 16;
  static const double _lineHeight = 14;
  static const double _metaHeight = 10;
  static const double _actionHeight = 48;
  static const double _rowIcon = 48;

  @override
  Widget build(BuildContext context) {
    // Scrolls rather than clipping. The kit draws this inside the dashboard's
    // scrolling body, and the placeholder stands for a screenful of content —
    // on a short viewport it is taller than the frame, which overflowed by 87
    // pixels inside the tab shell before this wrapper existed.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _Line(widthFactor: 0.55, height: _labelHeight),
          const MxGap.s4(),
          const MxSkeleton(height: _actionHeight),
          const MxGap.s4(),
          // The daily-goal card: title, progress bar, caption.
          MxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                _Line(widthFactor: 0.35, height: _lineHeight),
                MxGap.s3(),
                MxSkeleton(height: _metaHeight),
                MxGap.s2(),
                _Line(widthFactor: 0.6, height: _metaHeight),
              ],
            ),
          ),
          const MxGap.s4(),
          const _Line(widthFactor: 0.3, height: _labelHeight),
          const MxGap.s4(),
          for (var row = 0; row < 2; row++) ...<Widget>[
            const _DeckRowSkeleton(),
            if (row == 0) const MxGap.s3(),
          ],
        ],
      ),
    );
  }
}

/// A skeleton bar occupying a fraction of the available width.
///
/// `MxSkeleton` takes an absolute width, and the kit specifies percentages —
/// so the fraction is resolved against the row rather than guessed at a pixel
/// value that would only be right at one viewport.
class _Line extends StatelessWidget {
  const _Line({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: MxSkeleton(height: height),
      ),
    );
  }
}

class _DeckRowSkeleton extends StatelessWidget {
  const _DeckRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return MxCard(
      child: Row(
        children: <Widget>[
          const MxSkeleton(
            width: TodayLoadingSkeleton._rowIcon,
            height: TodayLoadingSkeleton._rowIcon,
          ),
          const MxGap.s4(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                _Line(
                  widthFactor: 0.6,
                  height: TodayLoadingSkeleton._lineHeight,
                ),
                MxGap.s2(),
                _Line(
                  widthFactor: 0.4,
                  height: TodayLoadingSkeleton._metaHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
