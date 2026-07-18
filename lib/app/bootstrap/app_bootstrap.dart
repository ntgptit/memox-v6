import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:memox_v6/app/app.dart';
import 'package:memox_v6/core/logging/app_logger.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';

/// Single sink for every uncaught framework, platform or zone error.
///
/// The default routes through the redacted [AppLogger] pipeline and, in
/// debug builds, still presents full details on the console.
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
  final report = onError ?? reportToAppLogger;
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    installGlobalErrorHandlers(report);
    installLifecycleListener(onLifecycleStateChanged);
    runApp(buildRoot(overrides: overrides));
  }, (error, stackTrace) => report(detailsForUncaughtError(error, stackTrace)));
}

/// Default reporter: redacted fatal log, plus full console details in debug.
@visibleForTesting
void reportToAppLogger(FlutterErrorDetails details) {
  AppLogger.fatal(
    'Uncaught error: ${details.exceptionAsString()}',
    error: details.exception,
    stackTrace: details.stack,
  );
  if (kDebugMode) FlutterError.presentError(details);
}

/// Routes [FlutterError.onError] and platform-dispatcher errors to [report]
/// and replaces the framework build-failure dump with a user-safe surface.
@visibleForTesting
void installGlobalErrorHandlers(BootstrapErrorReporter report) {
  FlutterError.onError = report;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    report(detailsForUncaughtError(error, stackTrace));
    return true;
  };
  ErrorWidget.builder = (details) => const SafeBuildErrorSurface();
}

/// Registers the root lifecycle listener; the binding retains it.
@visibleForTesting
AppLifecycleListener installLifecycleListener(
  BootstrapLifecycleObserver? observer,
) {
  return AppLifecycleListener(onStateChange: (state) => observer?.call(state));
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

/// User-safe replacement for the framework build-failure widget.
///
/// Shows localized copy when localizations are reachable at the failure
/// point and degrades to an icon-only surface otherwise; never exposes
/// exception text to the user.
@visibleForTesting
class SafeBuildErrorSurface extends StatelessWidget {
  @visibleForTesting
  const SafeBuildErrorSurface({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Center(
      child: l10n == null
          ? const Icon(Icons.error_outline)
          : Text(l10n.somethingWentWrongMessage),
    );
  }
}
