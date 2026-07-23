import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/today/today_projection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_projection_provider.g.dart';

/// The composed Today entry projection (WBS 5.7.1; `load-today-dashboard.md`) as
/// an [AsyncValue] the Today screen renders. Delegates to
/// [LoadTodayProjectionUseCase] — the screen never touches a repository.
@riverpod
Future<TodayProjection> todayProjection(Ref ref) {
  return ref.watch(loadTodayProjectionUseCaseProvider).call();
}
