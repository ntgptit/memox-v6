/// Pagination and stream limits for data-layer queries (WBS 4.9).
///
/// Every paged read uses these named limits — callers never invent ad
/// hoc page sizes, so latency budgets hold across screens.
abstract final class QueryLimits {
  /// Default page for card/deck listings; matches the dense-fixture
  /// batch so one page never grows unbounded.
  static const int defaultPageSize = 25;

  /// Hard ceiling any caller-supplied limit is clamped to.
  static const int maxPageSize = 100;

  /// Clamps a requested page size into `1..maxPageSize`.
  static int clampPageSize(int requested) {
    if (requested < 1) return 1;
    if (requested > maxPageSize) return maxPageSize;
    return requested;
  }
}
