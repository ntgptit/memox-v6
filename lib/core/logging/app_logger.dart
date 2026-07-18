import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:memox_v6/core/logging/redaction.dart';

/// Ordered log severity.
enum LogLevel { debug, info, warning, error, fatal }

/// Immutable structured log record; [message] and [context] values are
/// already redacted when the record reaches a sink.
@immutable
final class LogRecord {
  const LogRecord({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.context = const <String, String>{},
  });

  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, String> context;
}

/// Receives every emitted [LogRecord].
typedef LogSink = void Function(LogRecord record);

void _developerSink(LogRecord record) {
  developer.log(
    record.message,
    name: 'memox',
    level: switch (record.level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
      LogLevel.fatal => 1200,
    },
    error: record.error,
    stackTrace: record.stackTrace,
  );
}

/// Sole runtime logging API (guard: `memox.observability.no_debug_print`).
///
/// This file is the only approved caller of raw log primitives; everything
/// else routes through these methods so output stays redacted and
/// controllable per build configuration.
abstract final class AppLogger {
  static LogSink _sink = _developerSink;

  /// Replaces the sink; tests inject a spy and restore the previous value.
  @visibleForTesting
  static LogSink get sink => _sink;

  @visibleForTesting
  static set sink(LogSink value) => _sink = value;

  static void debug(String message, {Map<String, String>? context}) =>
      _emit(LogLevel.debug, message, context: context);

  static void info(String message, {Map<String, String>? context}) =>
      _emit(LogLevel.info, message, context: context);

  static void warning(String message, {Map<String, String>? context}) =>
      _emit(LogLevel.warning, message, context: context);

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? context,
  }) => _emit(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? context,
  }) => _emit(
    LogLevel.fatal,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  static void _emit(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? context,
  }) {
    _sink(
      LogRecord(
        level: level,
        message: redactSensitive(message),
        error: error,
        stackTrace: stackTrace,
        context: <String, String>{
          for (final entry in (context ?? const <String, String>{}).entries)
            entry.key: redactSensitive(entry.value),
        },
      ),
    );
  }
}
