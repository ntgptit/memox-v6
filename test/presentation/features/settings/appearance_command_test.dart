import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/preferences/appearance_mode.dart';
import 'package:memox_v6/domain/usecases/preferences/set_appearance_preference_usecase.dart';
import 'package:memox_v6/presentation/features/settings/viewmodels/appearance_viewmodel.dart';

/// WBS 8.1 — `set-appearance-preference.md` §4: "Rapid selection chỉ latest
/// value thắng."
///
/// Two taps in quick succession start two writes. They land in tap order —
/// drift runs statements on one connection in submission order — but their
/// results come back whenever they come back, and the command has to know
/// which one it is still allowed to speak for.
void main() {
  test('a superseded selection cannot decide the outcome', () async {
    final gate = _GatedAppearance();
    final container = ProviderContainer(
      overrides: [
        setAppearancePreferenceUseCaseProvider.overrideWithValue(gate),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(
      appearanceCommandViewmodelProvider.notifier,
    );

    final superseded = notifier.selectAppearance(AppearanceMode.light);
    final latest = notifier.selectAppearance(AppearanceMode.dark);

    // The later tap lands first and succeeds.
    gate.finish(AppearanceMode.dark);
    await latest;
    expect(
      container.read(appearanceCommandViewmodelProvider),
      isA<AsyncData>(),
    );

    // The earlier one comes back afterwards, and fails. It is no longer the
    // learner's choice, so it has nothing to say: without the guard this
    // error became the command's state, and the sheet would have reported a
    // failure for a selection that had already been replaced.
    gate.fail(AppearanceMode.light);
    await superseded;

    expect(
      container.read(appearanceCommandViewmodelProvider),
      isA<AsyncData>(),
      reason: 'the latest selection still owns the state',
    );
  });
}

/// A use case whose writes finish only when the test says so, per mode.
class _GatedAppearance implements SetAppearancePreferenceUseCase {
  final Map<AppearanceMode, Completer<void>> _gates =
      <AppearanceMode, Completer<void>>{};

  Completer<void> _gateFor(AppearanceMode mode) =>
      _gates.putIfAbsent(mode, Completer<void>.new);

  void finish(AppearanceMode mode) => _gateFor(mode).complete();

  void fail(AppearanceMode mode) =>
      _gateFor(mode).completeError(StateError('write failed'));

  @override
  Future<void> setMode(AppearanceMode mode) => _gateFor(mode).future;

  @override
  Future<AppearanceMode> current() async => AppearanceMode.system;

  @override
  Stream<AppearanceMode> watch() =>
      Stream<AppearanceMode>.value(AppearanceMode.system);
}
