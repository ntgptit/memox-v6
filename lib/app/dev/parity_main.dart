import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:memox_v6/app/bootstrap/app_bootstrap.dart';
import 'package:memox_v6/app/di/core_providers.dart';
import 'package:memox_v6/app/di/data_providers.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/data/database/app_database.dart';
import 'package:memox_v6/data/dev/parity_fixtures.dart';

/// Flutter Web entry point for the kit visual-parity gate (WBS P0.2).
///
/// Boots the **real** application — real router, real first-run gate,
/// real screens — so a Playwright spec can traverse the owning business
/// Master flow (WBS §6.6) exactly as a user would. Only three seams are
/// replaced, and each one is replaced to remove nondeterminism, never to
/// shortcut a flow:
///
/// - the database is reset and reseeded from `?fixture=` on every load,
/// - the clock is pinned to [ParityFixtures.fixedInstantMs],
/// - ids come from a counter instead of UUID v7.
///
/// Theme and locale are **not** overridden here: the app already follows
/// the platform, so Playwright drives them through `colorScheme` /
/// `locale` emulation and the production `ThemeMode.system` path stays
/// under test.
///
/// This target is never the production entry (`lib/main.dart` is) and is
/// only reachable through `tool/parity/build_web.mjs`, which passes
/// `--dart-define=MEMOX_PARITY=true`.
Future<void> main() async {
  const isParityBuild = bool.fromEnvironment('MEMOX_PARITY');
  if (!isParityBuild) {
    throw StateError(
      'parity_main is the visual-parity harness entry point and requires '
      '--dart-define=MEMOX_PARITY=true; build it via tool/parity/build_web.mjs.',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();

  // CanvasKit paints the whole UI into a canvas, so a browser driver
  // sees no text, buttons or roles by default. Forcing the semantics
  // tree on makes Flutter emit its accessibility DOM, which is what
  // Playwright queries and clicks — the same tree a screen reader uses.
  // It is an invisible overlay and does not alter the painted frame.
  SemanticsBinding.instance.ensureSemantics();

  final fixtureId = Uri.base.queryParameters['fixture'] ?? 'MX-VIS-001';
  final database = AppDatabase.open();
  await ParityFixtures(database).seed(fixtureId);

  await bootstrap(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      appClockProvider.overrideWithValue(const _FixedParityClock()),
      idGeneratorProvider.overrideWithValue(_SequentialParityIds()),
    ],
    appBuilder: _applyKitViewportInsets,
  );
}

/// The status-bar inset the kit reserves above every app bar
/// (`--memox-safe-area-top`: `max(env(safe-area-inset-top), 24px)`).
///
/// A browser reports no safe area, so a raw Flutter Web capture would
/// sit 24 logical px higher than every kit shot and read as a whole-frame
/// layout diff. This injects the inset a device would supply — the same
/// simulation `applyKitViewport` performs for the in-test 3.15 harness.
const double kitStatusBarInset = 24;

Widget _applyKitViewportInsets(BuildContext context, Widget? child) {
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(
      padding: media.padding.copyWith(top: kitStatusBarInset),
      viewPadding: media.viewPadding.copyWith(top: kitStatusBarInset),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

/// Pins every time read so scheduling, ordering and any rendered date
/// stay identical across runs.
final class _FixedParityClock implements AppClock {
  const _FixedParityClock();

  @override
  DateTime nowUtc() {
    return DateTime.fromMillisecondsSinceEpoch(
      ParityFixtures.fixedInstantMs,
      isUtc: true,
    );
  }
}

/// Counter-based ids so a captured state has stable primary keys.
final class _SequentialParityIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() {
    _next++;
    return 'parity-${_next.toString().padLeft(4, '0')}';
  }
}
