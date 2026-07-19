import 'package:go_router/go_router.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_providers.g.dart';

/// The production router, wired to the first-run gate: a fresh install
/// (no active pair, landing never dismissed) enters the first-run
/// landing; everyone else lands home. Pulled forward from the 5.7
/// navigation guard so developed flows are reachable for testing.
@Riverpod(keepAlive: true)
GoRouter appRouterInstance(Ref ref) {
  return createAppRouter(
    needsFirstRun: () async {
      try {
        final pair = await ref
            .read(selectLanguagePairUseCaseProvider)
            .activePair();
        if (pair != null) return false;
        final dismissed = await ref
            .read(dismissFirstRunUseCaseProvider)
            .wasDismissed();
        return !dismissed;
      } on Object {
        // A store that cannot answer must never trap the user outside
        // the app shell; the empty Dashboard keeps its own entry.
        return false;
      }
    },
  );
}
