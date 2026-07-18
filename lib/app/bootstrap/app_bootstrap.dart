import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:memox_v6/app/app.dart';

/// Single sink for every uncaught framework, platform or zone error.
///
/// WBS 1.5 rewires the default to the redacted `AppLogger` pipeline; until
/// then the only guard-approved sink is [FlutterError.presentError].
typedef BootstrapErrorReporter = void Function(FlutterErrorDetails details);

/// Receives app lifecycle transitions observed by the root listener.
typedef BootstrapLifecycleObserver = void Function(AppLifecycleState state);

/// Boots the application inside one guarded error zone.
///
/// This is the only production entry point; `main.dart` delegates here and
/// nothing else may install global error handlers (guard:
/// `memox.observability.error_zone_ownership`).
Future<void> bootstrap({
  List<Override> overrides = const <Override>[],
  BootstrapErrorReporter? onError,
  BootstrapLifecycleObserver? onLifecycleStateChanged,
}) async {
  final report = onError ?? FlutterError.presentError;
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      installGlobalErrorHandlers(report);
      installLifecycleListener(onLifecycleStateChanged);
      runApp(buildRoot(overrides: overrides));
    },
    (error, stackTrace) => report(detailsForUncaughtError(error, stackTrace)),
  );
}

/// Routes [FlutterError.onError] and platform-dispatcher errors to [report].
@visibleForTesting
void installGlobalErrorHandlers(BootstrapErrorReporter report) {
  FlutterError.onError = report;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    report(detailsForUncaughtError(error, stackTrace));
    return true;
  };
}

/// Registers the root lifecycle listener; the binding retains it.
@visibleForTesting
AppLifecycleListener installLifecycleListener(
  BootstrapLifecycleObserver? observer,
) {
  return AppLifecycleListener(
    onStateChange: (state) => observer?.call(state),
  );
}

/// Root composition: Riverpod scope around the app widget.
@visibleForTesting
Widget buildRoot({List<Override> overrides = const <Override>[]}) {
  return ProviderScope(overrides: overrides, child: const MemoxApp());
}

/// Maps an uncaught non-framework error to reportable [FlutterErrorDetails].
@visibleForTesting
FlutterErrorDetails detailsForUncaughtError(
  Object error,
  StackTrace stackTrace,
) {
  return FlutterErrorDetails(
    exception: error,
    stack: stackTrace,
    library: 'memox bootstrap',
    context: ErrorDescription('uncaught asynchronous error'),
  );
}
