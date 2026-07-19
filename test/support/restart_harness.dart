import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/data/database/app_database.dart';

/// Simulated process-restart fixture (WBS 1.10).
///
/// Backs the shared database with a real temp file so closing the
/// instance and opening a fresh one replays exactly what an app restart
/// does: same store, new connection, new object graph.
final class RestartHarness {
  RestartHarness._(this._file);

  final File _file;
  AppDatabase? _database;

  /// Creates the harness with an isolated temp store; cleanup is
  /// registered on the current test.
  static RestartHarness create() {
    final directory = Directory.systemTemp.createTempSync('memox_restart');
    final harness = RestartHarness._(File('${directory.path}/restart.db'));
    addTearDown(() async {
      await harness._database?.close();
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    return harness;
  }

  /// The currently open database, opening the store on first use.
  AppDatabase get database {
    final open = _database;
    if (open != null) return open;
    final created = AppDatabase.forTesting(NativeDatabase(_file));
    _database = created;
    return created;
  }

  /// Closes the current instance and reopens the same store, as a
  /// process restart would.
  Future<AppDatabase> restart() async {
    await _database?.close();
    _database = null;
    return database;
  }
}
