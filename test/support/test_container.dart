import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [ProviderContainer] wired for tests: disposed automatically at the
/// end of the test that created it (WBS 1.10).
ProviderContainer createTestContainer({List<Override> overrides = const []}) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}
