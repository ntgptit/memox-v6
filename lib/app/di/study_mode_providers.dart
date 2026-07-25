import 'package:memox_v6/domain/study_modes/study_mode_factory.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_mode_providers.g.dart';

/// Study Mode DI (WBS 5.5.5; factory-di-architecture §4).
///
/// The one place a [StudyModeFactory] is constructed: keep-alive, holding the
/// six concrete strategies. The Study Session use cases depend on this factory
/// alone; tests override this provider with a factory of fakes, so domain code
/// never reaches for a strategy directly.

@Riverpod(keepAlive: true)
StudyModeFactory studyModeFactory(Ref ref) => StudyModeFactory.standard();
