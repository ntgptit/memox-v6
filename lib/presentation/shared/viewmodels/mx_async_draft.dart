import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Draft access for `AsyncValue<T>` (guard
/// `memox.state_management.async_draft_via_extension`).
///
/// Viewmodels read the current draft through [currentValue] instead of
/// inlining the `AsyncData(:final value) => value, _ => null` switch, so
/// draft semantics stay in one place.
extension MxAsyncDraft<T> on AsyncValue<T> {
  /// The current data value, or `null` while loading/after an error.
  T? get currentValue => switch (this) {
    AsyncData(:final value) => value,
    _ => null,
  };
}
