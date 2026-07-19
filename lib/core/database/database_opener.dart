import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Platform database opener (WBS 4.1; ADR-004).
///
/// One shared Drift schema opens through platform-specific executors:
///
/// - **Native (Android/desktop)** — `drift_flutter` opens the SQLite file
///   in a background isolate (`NativeDatabase.createInBackground` under
///   the hood), keeping queries off the UI isolate per the ADR.
/// - **Web** — the approved wasm opener; `sqlite3.wasm` and
///   `drift_worker.js` are served from `web/`. Provisioning those build
///   assets is part of the Tier-1 web smoke evidence (WBS 5.7.4) — the
///   code path here is complete and inert until then.
///
/// The executor is lazy: nothing touches platform channels until the
/// first query, so construction is side-effect free (testable without a
/// device).
QueryExecutor openAppDatabaseExecutor({required String name}) {
  return driftDatabase(
    name: name,
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
