// Drift web worker entrypoint (WBS 4.1 web opener).
//
// Compiled to `drift_worker.js` with the project's own drift/sqlite3
// versions so the worker always matches `sqlite3.wasm`:
//
//   dart compile js -O4 web/drift_worker.dart -o web/drift_worker.js
//
// Do not replace the output with a prebuilt release worker — a version
// skew against sqlite3.wasm fails at runtime with a wasm LinkError.
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
