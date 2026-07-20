import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/domain/deck/deck.dart';
import 'package:memox_v6/domain/usecases/deck/create_deck_usecase.dart';

/// Dependency preconditions for kit visual-parity states (WBS P0.3).
///
/// The companion of `data/dev/parity_fixtures.dart`: that file seeds
/// rows, this one supplies the provider overrides a state needs. They
/// are split because providers are wired in the app layer and the data
/// layer must not reach into it.
///
/// Some states exist only when an operation fails. Making the failure a
/// precondition — a write path broken *before* the user acts — is not a
/// shortcut: the spec still walks the whole flow and presses the real
/// control, and what renders afterwards is the production error path.
/// Seeding the rendered error instead would hide exactly the wiring this
/// gate exists to check.
List<Override> parityOverridesFor(String fixtureId) {
  return switch (fixtureId) {
    'MX-VIS-012' => <Override>[
      createDeckUseCaseProvider.overrideWith(
        (ref) => _FailingCreateDeckUseCase(
          decks: ref.watch(deckRepositoryProvider),
          pairs: ref.watch(languagePairRepositoryProvider),
          idGenerator: ref.watch(idGeneratorProvider),
          clock: ref.watch(appClockProvider),
        ),
      ),
    ],
    _ => const <Override>[],
  };
}

/// A create path that always fails, for the submit-failure state.
///
/// It throws instead of validating, so the draft stays intact and the
/// banner — not a field error — is what renders, matching
/// `create-deck-firstrun--submit-failure`.
class _FailingCreateDeckUseCase extends CreateDeckUseCase {
  const _FailingCreateDeckUseCase({
    required super.decks,
    required super.pairs,
    required super.idGenerator,
    required super.clock,
  });

  @override
  Future<Deck> call({
    required String name,
    required String languagePairId,
    String? parentId,
    String? retryDeckId,
    String? description,
  }) async {
    throw const UnexpectedFailure(
      cause: 'parity fixture: the deck write path fails for MX-VIS-012',
    );
  }
}
