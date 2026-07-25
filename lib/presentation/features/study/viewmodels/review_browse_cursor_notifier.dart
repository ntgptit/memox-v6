import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'review_browse_cursor_notifier.g.dart';

/// Local browse offset for Review's backward re-view (WBS 5.6.5;
/// `review-cards.md` §§4,47): how many cards back from the committed cursor the
/// learner is currently viewing. Presentation-only — backward navigation writes
/// no evidence — and it resets with the screen.
@riverpod
class ReviewBrowseCursor extends _$ReviewBrowseCursor {
  @override
  int build() => 0;

  /// View one card further back.
  void back() => state = state + 1;

  /// Step forward over an already-seen card; never past the committed card.
  void forward() {
    if (state > 0) state = state - 1;
  }
}
